# Trusted Platform Module (TPM)

# Components

1. Cryptographic Processor
    1. Random Number Generator
    1. RSA Key Generator
    1. SHA-1 Key Generator
    1. Encryption/Decryption Engine
1. Persistent Memory
    1. Endorsement Key (EK)
    1. Storage Root Key (SRK)
1. Transient Memory
    1. Platform Configuration Register (PCR)
    1. Attestation Key (AIK)
    1. Storage Key

# Platform Configuration Register (PCR)

## PCR Index Reference Table

| PCR Index | Measured Object | Notes |
|-----------|-----------------|-------|
| 0 | Core System Firmware executable code | Measured by firmware |
| 1 | Core System Firmware data (NVRAM) | Measured by firmware |
| 2 | Extended or pluggable executable code | Measured by firmware |
| 3 | Extended or pluggable firmware data | Measured by firmware |
| 4 | Boot loader executable code | systemd-boot and GRUB bootloader code |
| 5 | Boot loader configuration and data (GPT) | systemd-boot and GRUB (grub.cfg, partition table) |
| 6 | Host platform manufacturer specific | OEM-specific |
| 7 | Secure Boot state and configuration | Secure Boot state |
| 8 | UEFI Boot Manager executable code | systemd-boot code measurements |
| 9 | UEFI Boot Manager configuration data | systemd-boot, GRUB, and systemd-measured for kernel/initrd |
| 10 | IMA (Integrity Measurement Architecture) - Optional | Used by systemd for runtime integrity measurements |
| 11 | IMA - Optional | systemd-measured uses for EFI variables |
| 12 | IMA - Optional | systemd-measured for kernel/initrd measurements |
| 13 | IMA - Optional | Available for systemd extensions |∏
| 14 | IMA - Optional | Available for systemd extensions |
| 15 | IMA - Optional | Available for systemd extensions |
| 16 | Debug (PCR reset for debugging) | Debug control |
| 17-22 | TCG firmware specific (reserved) | Reserved by TCG |
| 23 | Application Support | Application-specific measurements |

# How does systemd support TPM?

## systemd Components for TPM Support

| Component | Purpose | Notes |
|-----------|---------|-------|
| **systemd-boot** | UEFI bootloader | Measures kernel and initrd images to PCR 9; optionally measures EFI variables to PCR 11; can measure command line to PCR 12 |
| **systemd-measured** | PCR log service | Logs kernel command line and EFI variables to TPM 2.0 for attestation; writes to PCR 11 and 12 |
| **systemd-pcrlock** | PCR locking/sealing | Locks PCR values in TPM to prevent modifications; creates sealed credentials bound to specific PCR states; used for attestation and access control policies |
| **systemd-cryptsetup** | LUKS disk encryption | Supports TPM-sealed LUKS keys; uses TPM2-backed key encryption with PCR policies for automatic unlocking on secure boot |
| **systemd-gpt-auto-generator** | Partition discovery | Auto-discovers encrypted partitions; integrates with TPM for secure boot scenarios |
| **systemd-tpm2-setup-generator** | TPM initialization | Sets up TPM2 device; initializes early-boot TPM functionality |
| **tpm2-tools** | User-space tools | CLI utilities for TPM operations; used by systemd components for key management and attestation (tpm2_pcrrread, tpm2_quote, etc.) |
| **systemd-homed** | User account management | Can use TPM to protect user home directories with cryptographic binding to hardware state |
| **systemd-cryptenroll** | LUKS key enrollment | User-facing tool for enrolling TPM and FIDO2 security keys into LUKS volumes; creates TPM2-sealed keys with PCR policies for automatic unlocking |
| **systemd-fido2** | Security key support | Works alongside TPM for multi-factor authentication scenarios |

# Scenario: TPM Key Enrollment and LUKS Lifecycle

## Goal

Run a host service that creates a TPM-backed asymmetric key pair, sends the public key to a cloud enrollment service, and uses TPM-aware LUKS unlocking for local storage encryption.

## Environments

| Environment | TPM Type | Trust Notes |
|-------------|----------|-------------|
| Bare-metal Linux | Physical TPM 2.0 | Hardware root of trust is on the motherboard; EK and PCRs represent physical platform state |
| Azure VM with Trusted Launch | vTPM 2.0 | vTPM state is tied to the VM security boundary and measured boot chain; use Azure attestation signals plus PCR policy |

## Enrollment Flow (Service + Cloud)

1. Early boot establishes measured state (firmware, boot loader, kernel, initrd) into PCRs.
1. A host enrollment service generates a non-exportable TPM key pair.
1. The service collects identity evidence (for example: EK public, AIK quote over selected PCRs, platform metadata).
1. The service sends the public key and attestation evidence to a cloud enrollment endpoint.
1. Cloud validates quote, PCR policy, and platform claims, then issues a device credential/certificate bound to that key.
1. The private key never leaves the TPM/vTPM; the host uses it for TLS client auth, signing, or token proof-of-possession.

## LUKS Storage Encryption Pattern

1. Encrypt disk with LUKS2.
1. Enroll a TPM2 protector using systemd-cryptenroll with a defined PCR policy (commonly including Secure Boot and boot chain PCRs).
1. Keep at least one recovery path (recovery key or passphrase) in a separate LUKS keyslot.
1. At boot, systemd-cryptsetup requests unseal from TPM; unlock succeeds only when PCR policy matches expected state.

## Key Management During O/S Updates

O/S updates often change measured components (boot loader, kernel, initrd, command line), which can change PCR values and affect TPM unseal behavior.

| Update Event | Typical Impact | Recommended Action |
|--------------|----------------|--------------------|
| Kernel/initrd update | PCRs tied to boot artifacts may change | Re-enroll or update TPM2 PCR policy after update validation |
| Boot loader update (systemd-boot or GRUB) | Boot chain measurements may change | Stage update with recovery key available; test reboot before broad rollout |
| Secure Boot DB/KEK changes | PCR 7 can change | Plan coordinated policy rotation for TPM-bound keyslots |
| VM image/base OS refresh | Multiple PCRs can shift at once | Use versioned policies and phased rollout; keep break-glass unlock method |

## Operational Notes

- Prefer policy sets that balance security and maintainability; binding to too many volatile PCRs can cause frequent unlock failures after legitimate updates.
- For fleet operations, automate post-update policy refresh and verify unlock on canary hosts first.
- For Azure Trusted Launch VMs, combine TPM PCR policy with cloud-side workload identity and attestation checks; do not rely on PCRs alone for authorization.
- Never depend on TPM-only unlock without recovery material. Keep recovery keys escrowed with strict access controls.

