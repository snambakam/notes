param (
    [Parameter(Mandatory = $true)]
    [string]$VMName
)

# Ensure the VM is turned off
$vm = Get-VM -Name $VMName -ErrorAction Stop
if ($vm.State -ne 'Off') {
    throw "VM '$VMName' must be powered off before enabling virtualization extensions."
}

# Enable nested virtualization
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $false

Write-Host "Nested virtualization disabled for VM '$VMName'."
