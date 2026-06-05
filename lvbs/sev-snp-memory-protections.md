# AMD SEV-SNP Memory Protections

AMD SEV-SNP uses a **layered memory protection model** with hardware, firmware, and software enforcement.

---

## 1. RMP (Reverse Map Table) — Hardware Foundation

Every physical page in the system has a 16-byte **RMP entry** maintained by the CPU hardware:

| Field | Bits | Purpose |
|-------|------|---------|
| `assigned` | 1 | 1 = guest-owned (private), 0 = hypervisor-owned |
| `pagesize` | 1 | 0 = 4K, 1 = 2M |
| `asid` | 10 | Which VM owns this page (supports 1024 VMs) |
| `gpa` | 39 | Expected Guest Physical Address |
| `immutable` | 1 | Firmware prevents further RMP modification |
| `vmsa` | 1 | Page is a VMSA (vCPU save area) |
| `validated` | 1 | Guest accepted via PVALIDATE |

On **every memory access**, the CPU checks the RMP: if a guest tries to access a page not assigned to its ASID, or at the wrong GPA, the hardware generates an `#NPF` (Nested Page Fault).

---

## 2. Private vs Shared Memory (C-bit / Encryption)

SEV-SNP uses a bit in the guest page table (the "C-bit") to distinguish:

- **Private (encrypted)**: C-bit clear → page encrypted with the VM's key, RMP `assigned=1`
- **Shared (decrypted)**: C-bit set → plaintext, RMP `assigned=0`, visible to hypervisor

Guest-side helpers in `arch/x86/coco/core.c`:
- `cc_mkenc(addr)` — mark encrypted (private)
- `cc_mkdec(addr)` — mark decrypted (shared)

---

## 3. KVM (Hypervisor) Side — RMP State Transitions

KVM manages RMP entries via RMPUPDATE instructions in `arch/x86/virt/svm/sev.c`:

```c
rmp_make_private(pfn, gpa, level, asid, immutable)
  → RMPUPDATE: assigned=1, stores GPA & ASID

rmp_make_shared(pfn, level)
  → RMPUPDATE: assigned=0, hypervisor reclaims page
```

During SNP launch, KVM calls these for each page loaded via `KVM_SEV_SNP_LAUNCH_UPDATE`.

---

## 4. Guest Side — PVALIDATE (Page Acceptance)

The guest must **explicitly accept** pages using the `PVALIDATE` instruction before using them. This prevents the hypervisor from silently remapping memory:

```
PVALIDATE address, size_control, operation
  operation: 0 = validate as shared, 1 = validate as private
```

The guest-side flow in `arch/x86/coco/sev/core.c`:
1. Hypervisor assigns page → `rmp_make_private()` → `assigned=1`, `validated=0`
2. Guest calls `PVALIDATE(validate)` → `validated=1`
3. Guest can now use the page
4. If `snp_vmpl != 0` (SVSM present), PVALIDATE is routed through SVSM at VMPL 0 via `svsm_pval_pages()`

---

## 5. Page State Change (PSC) Protocol — Private ↔ Shared Transitions

When the guest needs to change a page between private and shared (e.g., for DMA buffers), it uses the PSC VMGEXIT protocol:

**To shared** (guest releases page):
1. Guest: `PVALIDATE(unvalidate)` → `validated=0`
2. Guest: `VMGEXIT PSC(SHARED)` → hypervisor notified
3. Hypervisor: `rmp_make_shared()` → `assigned=0`

**To private** (guest claims page):
1. Guest: `VMGEXIT PSC(PRIVATE)` → hypervisor notified
2. Hypervisor: `rmp_make_private()` → `assigned=1`
3. Guest: `PVALIDATE(validate)` → `validated=1`

Batched via `struct snp_psc_desc` (up to 64 entries per VMGEXIT).

---

## 6. KVM Memory Attributes — Software Enforcement (NPT/EPT)

On top of hardware RMP, KVM enforces **software memory attributes** at the nested page table level. This is what the VM Planes implementation uses:

```c
KVM_MEMORY_ATTRIBUTE_PRIVATE    // page allocated to guest via guest_memfd
KVM_MEMORY_ATTRIBUTE_NO_WRITE   // clear PT_WRITABLE_MASK in SPTE
KVM_MEMORY_ATTRIBUTE_NO_EXEC    // set NX bit in SPTE
```

When QEMU calls `KVM_SET_MEMORY_ATTRIBUTES`, KVM zaps existing SPTEs and rebuilds them with the new restrictions. This is the mechanism `vbs_apply_protection()` in `target/i386/kvm/kvm.c` uses to enforce `SEAL_KERNEL` and `PROTECT_MEMORY`.

---

## 7. How It All Fits Together

```
┌─────────────────────────────────────────────────────────┐
│                    Hardware (CPU)                        │
│  RMP Table: per-page {assigned, asid, gpa, validated}   │
│  Every memory access checked against RMP                │
│  AES encryption engine: private pages encrypted in DRAM │
├─────────────────────────────────────────────────────────┤
│                   Firmware (PSP)                         │
│  SNP_LAUNCH_UPDATE: populates RMP + encrypts pages      │
│  SNP_LAUNCH_FINISH: seals measurement, immutable VMSAs  │
│  Attestation: proves RMP state to remote verifier       │
├─────────────────────────────────────────────────────────┤
│              KVM (Hypervisor Software)                   │
│  rmp_make_private/shared: RMPUPDATE instructions        │
│  KVM_SET_MEMORY_ATTRIBUTES: NPT W/X restrictions        │
│  guest_memfd: private memory backing (not mmap-able)    │
├─────────────────────────────────────────────────────────┤
│                Guest (VMPL 0 — SVSM)                    │
│  PVALIDATE: accepts/rejects pages                       │
│  Controls VMPL 1-3 page permissions                     │
├─────────────────────────────────────────────────────────┤
│              Guest (VMPL 2 — Kernel)                    │
│  PSC VMGEXIT: requests private↔shared transitions       │
│  cc_mkenc/cc_mkdec: sets C-bit in guest page tables     │
│  VBS calls → SVSM or Plane 1 for protection policy      │
└─────────────────────────────────────────────────────────┘
```

---

## 8. VM Planes vs SEV-SNP: Complementary Layers

**Key difference from the current VM Planes implementation**: `vbs_apply_protection()` sets `KVM_MEMORY_ATTRIBUTE_NO_WRITE`/`NO_EXEC` which are enforced at the **NPT (software) level** by KVM. In SEV-SNP, the **RMP (hardware) level** provides a stronger guarantee — even if the hypervisor is compromised, it cannot read/modify private guest pages.

The two layers are complementary:
- **RMP** prevents the hypervisor from attacking the guest
- **NPT attributes** (controlled by the secure plane) prevent the guest kernel from modifying its own sealed regions

| Layer | Mechanism | Enforced By | Protects Against |
|-------|-----------|-------------|------------------|
| Hardware (RMP) | Per-page assigned/asid/gpa check | CPU on every access | Malicious hypervisor |
| Firmware (PSP) | Immutable flag, measurement seal | AMD Secure Processor | Tampering after launch |
| Software (NPT) | NO_WRITE/NO_EXEC memory attributes | KVM nested page tables | Guest self-modification |
| Guest (PVALIDATE) | Page acceptance protocol | Guest instruction | Hypervisor remapping |
