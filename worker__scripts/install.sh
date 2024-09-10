
#!/bin/bash
#Exit script on error
set -e


#Log file for installation
LOGFILE="/var/log/install_script.log"


#Check if script is run as root
if [ "$EUID" -ne 0 ]; then
echo "Please run as root."
exit 1
fi


#1. Partitioning the Disk
#Replace /dev/sda with the correct disk if different
DISK="/dev/sda"


echo "Partitioning the disk $DISK..." | tee -a $LOGFILE
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary ext4 1MiB 512MiB
parted -s $DISK mkpart primary ext4 512MiB 100%
mkfs.ext4 "${DISK}1"
mkfs.ext4 "${DISK}2"


#Mount the partitions (adjust as needed for your setup)
echo "Mounting partitions..." | tee -a $LOGFILE
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot


#2. Package Installation
echo "Installing packages..." | tee -a $LOGFILE
yum -y update
yum -y install epel-release
yum -y install vim net-tools curl git firewalld openssh-server


#3. Network Configuration
#You can customize this section for static or DHCP configuration
NETWORK_INTERFACE="eth0"
IP_ADDRESS="192.168.1.100"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.1"
DNS="8.8.8.8"


echo "Configuring network settings..." | tee -a $LOGFILE
cat < /etc/sysconfig/network-scripts/ifcfg-$NETWORK_INTERFACE
TYPE=Ethernet
BOOTPROTO=static
NAME=$NETWORK_INTERFACE
DEVICE=$NETWORK_INTERFACE
ONBOOT=yes
IPADDR=$IP_ADDRESS
NETMASK=$NETMASK
GATEWAY=$GATEWAY
DNS1=$DNS
EOT


systemctl restart NetworkManager


#4. Create User Accounts
echo "Creating user accounts..." | tee -a $LOGFILE


#Array of usernames to be created
usernames=("user1" "user2" "user3")


#Corresponding passwords for each user
passwords=("Password123" "Password456" "Password789")


useradd -m -s /bin/bash $USER
echo "$USER:$PASSWORD" | chpasswd
usermod -aG wheel $USER


#Loop through each username in the array
for i in "${!usernames[@]}"; do
username=${usernames[$i]}
password=${passwords[$i]}


#Check if the user already exists
if id "$username" &>/dev/null; then
    echo "User '$username' already exists. Skipping."
else
    #Create the user account
    useradd "$username"

    #Set the password for the user
    echo "$username:$password" | chpasswd

    #Expire the password to force change on first login
    passwd --expire "$username"

    echo "User '$username' created and password set."
fi

    
  

done


#5. Customize System Settings


#Set Hostname
echo "Configuring system settings..." | tee -a $LOGFILE
hostnamectl set-hostname "myserver"


#Set Timezone
timedatectl set-timezone America/New_York


#Set Language and Keyboard Layout
localectl set-locale LANG=en_US.UTF-8
localectl set-keymap us


#6. Post-Installation Tasks


#Configure Firewall
echo "Configuring firewall..." | tee -a $LOGFILE
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --reload


#Enable and start SSH service
echo "Setting up SSH..." | tee -a $LOGFILE
systemctl enable sshd
systemctl start sshd


#7. Completion and Final Checks
echo "Installation complete. Rebooting the system..." | tee -a $LOGFILE
reboot
