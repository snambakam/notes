# UEFI Secure Boot Key Hierarchy
## Focus on KEK, DB, and DBX (within the PK Trust Model)

## 1. Overview of UEFI Secure Boot

UEFI Secure Boot is a firmware security mechanism that ensures only trusted software is executed during the early boot process. Trust is enforced using a hierarchy of cryptographic keys and databases stored as authenticated UEFI variables in non-volatile firmware storage.

The Secure Boot trust chain is anchored by the **Platform Key (PK)** and flows downward as follows:

Platform Key (PK)
↓
Key Exchange Keys (KEK)
↓
┌───────────────┐
│   DB (Allow)  │
│  DBX (Revoke) │

- **PK** defines platform ownership and controls KEK.
- **KEK** authorizes updates to DB and DBX.
- **DB** determines what is allowed to execute.
- **DBX** determines what is explicitly forbidden from executing.

This document focuses on **KEK**, **DB**, and **DBX**, and their roles under the PK-controlled trust hierarchy.

---

## 2. Key Exchange Key (KEK)

### Purpose
The **Key Exchange Key (KEK)** establishes trust between the platform firmware and external authorities (such as operating system vendors). It is the mechanism by which the platform allows controlled updates to the Secure Boot policy.

### Contents
The KEK database may contain:
- X.509 certificates (RSA‑2048 or stronger)
- RSA public keys (per UEFI specification)

Multiple KEKs may be present simultaneously.

### Control and Ownership
- **Who controls it:** Platform owner (via PK)
- **Who uses it:** OS vendors and platform vendors
- **Who can update it:** Only an entity that can sign the update with the **Platform Key (PK)**

### Role in Secure Boot
- Authorizes updates to:
  - **DB (Allowed Signature Database)**
  - **DBX (Revoked Signature Database)**
- Optionally, binaries signed directly by a KEK key may be accepted for execution (implementation-dependent, but permitted by spec).

### Typical Real‑World Usage
- OEMs install one or more OS vendor KEKs (e.g., Microsoft KEK).
- OS updates use the KEK to deliver DB and DBX updates securely over time.
- KEK rotation (e.g., CA rollovers) is critical for long-term Secure Boot servicing.

---

## 3. Allowed Signature Database (DB)

### Purpose
The **Allowed Signature Database (DB)** defines which UEFI images are trusted to execute when Secure Boot is enabled.

### Contents
DB may contain a mix of:
- X.509 certificates (signing authorities)
- RSA public keys
- SHA‑256 hashes of individual EFI binaries

### Control and Ownership
- **Who controls it:** Indirectly controlled by PK through KEK
- **Who can update it:** Any entity with a private key corresponding to an enrolled **KEK**

### Role in Secure Boot Verification
When an EFI image is loaded (bootloader, UEFI driver, option ROM), it is allowed to execute if:
- Its signing certificate or key is present in DB, **and**
- It is **not** revoked by DBX

DB acts as a **whitelist**.

### Typical Real‑World Usage
- OEM firmware ships with OS vendor certificates in DB.
- Windows, Linux (via shim), and other OS loaders rely on DB trust.
- Enterprises may add custom signing keys for internally signed boot components.

---

## 4. Revoked Signature Database (DBX)

### Purpose
The **Revoked Signature Database (DBX)** is a security revocation mechanism used to block known‑bad or vulnerable boot components.

### Contents
DBX may contain:
- X.509 certificates
- RSA public keys
- SHA‑256 hashes of EFI binaries

These entries represent **explicitly forbidden** items.

### Control and Ownership
- **Who controls it:** Indirectly controlled by PK through KEK
- **Who can update it:** Any entity authorized by KEK (commonly the OS vendor)

### Role in Secure Boot Verification
DBX is always checked **before** DB.

If an EFI image:
- Matches a hash in DBX, or
- Is signed by a key or certificate in DBX

→ **Execution is blocked**, even if the image would otherwise be allowed by DB.

DBX acts as a **blacklist with higher priority than DB**.

### Typical Real‑World Usage
- Used to revoke compromised bootloaders, option ROMs, or signing keys.
- OS vendors distribute DBX updates in response to Secure Boot–relevant CVEs.
- DBX growth over time is expected and normal.

---

## 5. Update and Revocation Flows

### DB / DBX Update Flow
1. Platform is in **User Mode** (PK installed).
2. Update payload is prepared (new DB or DBX entries).
3. Payload is signed with a **KEK private key**.
4. Firmware verifies the KEK signature.
5. DB or DBX is updated if verification succeeds.

### Revocation Flow (DBX)
- Vulnerability discovered in a boot component.
- Component’s hash or signing key is added to DBX.
- Once installed, affected systems will refuse to boot that component.
- This mechanism is critical for ecosystem-wide Secure Boot incident response.

---

## 6. Comparison Summary

| Store | Role | Typical Contents | Update Authorization | Effect on Boot |
|-----|-----|------------------|----------------------|----------------|
| **KEK** | Policy authority | X.509 certs, RSA keys | Platform Key (PK) | Controls DB/DBX updates |
| **DB** | Allow list | Certs, keys, hashes | Any KEK | Permits execution |
| **DBX** | Deny list | Certs, keys, hashes | Any KEK | Blocks execution |

---

## 7. Key Takeaways

- **PK owns the platform**, but KEK operationalizes Secure Boot over time.
- **KEK is the gatekeeper** for Secure Boot policy evolution.
- **DB defines trust**, **DBX defines distrust**, and DBX always wins.
- Secure Boot remains viable long-term only if KEK and DBX can be updated.
- OEM, OS vendor, and firmware responsibilities are tightly coupled by design.

---
