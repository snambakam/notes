# System Management Mode (SMM)

SMM is an x86 CPU execution mode implemented by hardware and firmware.

When Platform generates a System Management Interrupt, the CPU does the following.

1. Save current CPU state.
2. Enters SMM
3. Executes firmware code from SMRAM.
4. Executes RSM (Resume).
5. Returns to the previous execution context.

Therefore, SMM runs completely outside Linux and any normal hypervisor control. It has access to all the system memory and hardware resources.

The SMI interrupts Linux execution and the CPU is used to execute firmware. The CPU returns back to Linux after the SMM is completed.

## Uses of SMM

* Power management
* Thermal control
* BIOS/Firmware services
* Secure firmware variable handling
* ACPI S3 resume support
* UEFI Secure boot variable protection

## SMM in KVM

KVM can simulate the SMM for Guest VMs.

Linux has CONFIG_KVM_SMM which provides the system management mode emulation.
UEFI Firmwares (OVMF/EDK2) expect SMM support.

SMM is required for at least the following.

1. Secure Boot Support
   1. Protect firmware variables such as PK, KEK, DB, DBX etc.
2. UEFI variable protection
3. Firmware behavior

## Concerns

SMM has full memory and hardware access and has very high privilege.

Firmware bugs become catastophic vulnerabilies.

SMM code is proprietary and executes outside the visibility of the O/S and is difficult to audit.

Hypervisors must be able to emulate SMM.

