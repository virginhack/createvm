# createmv
Bash Script to automate the creation  of VM
# This script automates the process of creating KVM VMs. The script has the following dependencing: LVM, KVM, virt-install

# The script takes command line arguments for VM specifications.
# It expect that the OS image is in "/var/lib/libvirt/boot"
# The script does not parse the positional parameters using getops but this is something I'll probably do in the future. I've created this script to mainly automate my work and it's not production ready
#
# Specify the command line arguments in the same order as the positional parameters
# The script requires 6 command line arguments as follows: NAME, CPUS, MEMORY, OS_IMAGE, DISK, BRIDGE
# For example.  ./create_vm.sh vm02 2 2048 CentOS-7-x86_64-Minimal-2009.iso 100 br243
#

