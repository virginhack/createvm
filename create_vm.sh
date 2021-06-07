#!/bin/bash

# This script automates the process of creating KVM VMs. The script has the following dependencing: LVM, KVM, virt-install

# The script takes command line arguments for VM specifications.
# It expect that the OS image is in "/var/lib/libvirt/boot"
# The script does not parse the positional parameters using getops but this is something I'll probably do in the future. I've created this script to mainly automate my work and it's not production ready
#
# Specify the command line arguments in the same order as the positional parameters
# The script requires 6 command line arguments as follows: NAME, CPUS, MEMORY, OS_IMAGE, DISK, BRIDGE
# For example.  ./create_vm.sh vm02 2 2048 CentOS-7-x86_64-Minimal-2009.iso 100 br243
#

# Variables start here
ERROR_WRONG_ARGS="66"

NAME="$1"
CPUS="$2"
MEMORY="$3"
OS_IMAGE="$4"
DISK="$5"
BRIDGE="$6"
OS_IMAGE_PATH="/var/lib/libvirt/boot"

# Functions start here
func_usage() {
  echo "Usage: `basename $0` $script_parameters"
  echo " NAME,Provide a name of the VM"
  echo " CPU, Provie a number of CPUS"
  echo " MEMRORY, Provide memory size"
  echo " OS, Provide Opetating System Type/Distro"
  echo " DISK, Provide a disk size in GB, e.g 100G" 
  echo " Bridge Interface name"
  echo
  echo "NAME, CPUS, MEMORY, OS_IMAGE, DISK, BRIDGE"
  echo "For example.  ./create_vm.sh vm02 2 2048 CentOS-7-x86_64-Minimal-2009.iso 100 br243"
  echo
  exit $ERROR_WRONG_ARGS

}

# Script starts here

# Make sure script is run as root

if [[ "${EUID}" -ne 0 ]]; then
   echo "Please run as root or super user"
   exit 1
fi

# Make sure user providers the right number of arguments

if [[ "$#" -ne 6 ]]; then
   echo "Wrong number of command line arguments"
   func_usage
fi


# Sanity checks

# VM already exist check

check_vm_name=$(virsh list --all | grep -q "${NAME}" && echo "$NAME" already exists on "$HOSTNAME" && exit 2 )

# Check RAM left

RAM=$(free -m | grep -Ev 'free|Swap' | awk '{print $4 }' | sed 's/$//' )
if (( $RAM <  $MEMORY )); then
   echo "There is not enough RAM left on $HOSTNAME"
   exit 3
fi


# Check if OS image exists

[[ ! -e "${OS_IMAGE_PATH}"/"${OS_IMAGE}" ]] &&
   echo "There no image called "${OS_IMAGE} in "${OS_IMAGE_PATH}"/"${OS_IMAGE}" &&
   exit 4

# Disk space left on the vmhost

vg=$(vgs | grep -v VG | awk '{print $1}')
DISK_SPACE=$(vgs --units G | grep -v VG | awk '{print $7 }'  | sed 's/.$//g')

if [[  -L /dev/"${vg}"/"${NAME}" ]] 
then
     echo "DISK /dev/"${vg}"/"${NAME}" already exists on ${HOSTNAME}"
     exit 5
elif  (( ${DISK//G/} < ${DISK_SPACE//.*/} ))
then
     lvcreate -L ${DISK}G  -n $NAME $vg 
else
     echo "Low Disk Space. Currently there's $DISK_SPACE  left on $HOSTNAME"
     exit 6
fi

# Check   the bridge network interface

get_bridge=$( ip a | grep -q "${BRIDGE}")

[[ get_bridge -ne 0 ]] && 
   echo "There's no $BRIDGE Interface on $HOSTNAME" && exit 7

# Create VM
virt-install --name="${NAME}"  --vcpus="${CPUS}"  --memory="${MEMORY}" --location="${OS_IMAGE_PATH}"/"${OS_IMAGE}"  --disk path=/dev/mapper/centos-"${NAME}",size="${DISK}",bus=virtio,format=qcow2, --network=bridge="${BRIDGE}",model=virtio --extra-args='console=ttyS0,115200n8 serial'  --nographics

wait 

exit  0
