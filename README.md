# System-Installation-and-Configuration

# Tier 3 Task 1: 

# Tier 3 Task 1: Automated System Installation Script

Here’s how I created an automated installation script (install.sh) for CentOS 8 to handle tasks like partitioning the disk, installing packages, creating users, and configuring the system. Below is the breakdown of the script, and I’ve documented each step as I implemented it. You can modify and extend this script as needed for your specific use cases.

# 1. install.sh Overview
The script will:
Partition the disk using parted.
Format partitions (e.g., ext4 or XFS).
Install required packages via yum.
Configure networking settings.
Create user accounts and set passwords.
Customize system settings (hostname, timezone, etc.).
Perform post-installation tasks like setting up a firewall and SSH access.

<img width="246" alt="p2 1" src="https://github.com/user-attachments/assets/4294ce60-ff39-4864-8c83-af6c2b9a1df5">


</head>
<body>
    <h1>install.sh Script</h1>
    <pre><code>
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
cat <<EOT > /etc/sysconfig/network-scripts/ifcfg-$NETWORK_INTERFACE
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
    </code></pre>
</body>
</html>


# Explanation of Key Sections


# 1. Partitioning the Disk

<img width="346" alt="p2 2" src="https://github.com/user-attachments/assets/419dc8f5-dfa7-42cf-882e-dc18ee111367">


In this part of the script, the disk is being prepared for use by mounting two partitions: one for the root file system (/) and one for the boot directory (/boot). These partitions have already been created earlier in the script using the parted command, which defined the disk partitions (such as a boot partition and a root partition) and formatted them with the ext4 file system, though other file systems like XFS could be used as well.
Here’s a detailed breakdown of the process:


Mounting the Partitions:

The script first echoes the message "Mounting partitions..." to the terminal and appends it to the log file ($LOGFILE) to track progress. This step helps with logging and keeping a record of the operations being performed.


Mounting the Root Partition:

The root partition, which is stored as the second partition ("${DISK}2"), is mounted to /mnt. This assumes that the variable ${DISK} contains the path to the target disk (e.g., /dev/sda), and the 2 refers to the second partition. Mounting it to /mnt means that this location will temporarily serve as the root directory during the installation or setup process.


Creating and Mounting the Boot Partition: 

Next, the script creates a boot directory within /mnt by running mkdir -p /mnt/boot. The -p flag ensures that the directory is created if it doesn’t already exist, and any necessary parent directories are also created. The first partition ("${DISK}1") is then mounted to /mnt/boot, which is the standard location for storing the bootloader and related files. The boot partition contains essential files that are needed during the boot process, such as the kernel and the initial RAM disk.


This method ensures that the root and boot partitions are correctly mounted so that the system can be set up properly. During an installation process, files will be copied to these partitions (e.g., system files to /mnt and bootloader files to /mnt/boot). If additional partitions, such as a home or swap partition, were part of the setup, they would also be mounted in a similar way at this stage.


After this part of the script is executed, the following system configurations are applied:


<img width="447" alt="p2 9" src="https://github.com/user-attachments/assets/fe4a77e1-cc98-4661-8cbc-c393cfa3528e">



# 2. Package Installation

<img width="378" alt="p2 3" src="https://github.com/user-attachments/assets/5b38c8ac-b0ec-4f10-923b-1f8d2255a7de">


yum is used to install common packages such as vim, net-tools, firewalld, and openssh-server. You can modify the package list based on your needs.


<img width="462" alt="p2 10" src="https://github.com/user-attachments/assets/d5d2f4a8-d842-43c1-a512-4efa7daf0caa">



# 3. Network Configuration

<img width="434" alt="p2 5" src="https://github.com/user-attachments/assets/d3cdf71f-c499-4f78-8efe-e6b6088da833">



This section of the script is responsible for configuring the network settings of a CentOS system by customizing the network interface for static IP assignment. First, it defines key variables: NETWORK_INTERFACE specifies the interface being configured (in this case, eth0), while IP_ADDRESS, NETMASK, GATEWAY, and DNS provide the specific details for the static IP configuration.


The script begins by echoing a message ("Configuring network settings...") to inform the user that network configuration is in progress. This message is also appended to a log file ($LOGFILE) for record-keeping. It then generates a network configuration file (/etc/sysconfig/network-scripts/ifcfg-eth0) using a "here document" (the cat <<EOT syntax). This configuration file defines the following key parameters:


TYPE=Ethernet:

Specifies the network interface type as Ethernet.
BOOTPROTO=static: Indicates that the network will use a static IP configuration.


NAME and DEVICE:

Both set the network interface to eth0.
ONBOOT=yes: Ensures the interface is enabled automatically at boot.
IPADDR, NETMASK, GATEWAY, and DNS1: Assign the static IP address, subnet mask, default gateway, and DNS server, respectively.
Once the file is created with these settings, the script restarts the NetworkManager service using systemctl restart NetworkManager. This action applies the new configuration, bringing the interface up with the specified static IP settings. If this were to be adapted for DHCP instead of static, the BOOTPROTO=static line would simply be replaced with BOOTPROTO=dhcp, and the other specific IP configuration parameters would be omitted.


# 4. User Creation

<img width="339" alt="p2 6" src="https://github.com/user-attachments/assets/f99a0390-d675-40f5-98a4-e47d0900f06d">


For Loop:
The loop iterates over the usernames array using the for i in "${!usernames[@]}" construct, which gets both the index and the value of each element.

username=${usernames[$i]}: This assigns the current username from the array.

password=${passwords[$i]}: This assigns the corresponding password from the passwords array.

User Existence Check:


id "$username" &>/dev/null: The id command checks if the user already exists. If they do, the script skips that user.


User Creation:

useradd "$username": This creates a new user account with the given username. The home directory is created automatically unless otherwise specified.


Password Assignment:

echo "$username:$password" | chpasswd: This sets the password for the user. The chpasswd command is used to set passwords for multiple users at once. Here, the password is echoed and piped into chpasswd.


Password Expiration:

passwd --expire "$username": This forces the user to change their password upon their first login.


Feedback:

After the user is created and the password is set, the script prints a message to the console for each user.

# 5. System Customization

<img width="349" alt="Capture" src="https://github.com/user-attachments/assets/f3102add-fbfa-4d7e-a330-f59725630e0a">



In this section of the script, system settings such as the hostname, timezone, and language/keyboard layout are configured to match the desired environment. The hostnamectl command is used to set the system's hostname to "myserver," which identifies the machine on the network. The timedatectl command sets the system's timezone to "America/New_York," ensuring that the system clock displays the correct local time. Finally, the localectl command is used to set the system's locale to "en_US.UTF-8," which configures the system to use English language settings, and the keyboard layout is set to "us" for the U.S. keyboard layout. Adjust these settings as needed to fit your specific requirements.

# Post-Installation Tasks

<img width="343" alt="p2 7" src="https://github.com/user-attachments/assets/89981f0d-bd6c-4dae-9100-a1eb6c1b9172">



This part of the script focuses on post-installation tasks related to securing the system through the firewall and enabling remote access via SSH. It automates the process of configuring the firewall and ensuring that the system is ready for remote management.


Configuring the Firewall:

The script begins by echoing the message "Configuring firewall..." to the terminal and appending it to the log file ($LOGFILE). This step provides real-time feedback and keeps a record of the firewall configuration for troubleshooting and auditing purposes.


Enabling and Starting Firewalld:

The script enables the firewalld service using the command systemctl enable firewalld. This ensures that the firewall service will automatically start on boot, maintaining the security settings persistently across reboots. Next, the script starts the firewalld service with systemctl start firewalld, which activates the firewall immediately, enforcing the default or custom security rules defined by the user.


Allowing SSH Access:

To permit secure remote access to the server, the script runs firewall-cmd --permanent --add-service=ssh. This command permanently adds SSH (Secure Shell) to the firewall's allowed services. By doing so, it ensures that incoming SSH traffic is allowed through the firewall, making it possible for administrators or users to remotely access the system via an encrypted SSH connection.


Allowing HTTP Access:

Similarly, the script allows HTTP traffic by running firewall-cmd --permanent --add-service=http. This command opens up port 80, which is commonly used for web servers, enabling external access to any web services hosted on the system.


<img width="292" alt="p2 11" src="https://github.com/user-attachments/assets/5ffc3476-8ff8-4a47-bc59-18bee1e0c45e">


Reloading the Firewall: 

The final step in this section is reloading the firewall rules using firewall-cmd --reload. This command applies the changes made (allowing SSH and HTTP traffic) without needing to restart the firewall service. The --permanent flag ensures that these rules persist across reboots.


Together, these commands configure the firewall to protect the system while allowing essential services like SSH and HTTP access. This is a critical step in securing the server after installation and ensuring that it can be managed remotely while permitting web traffic.


# 7. System Customization

<img width="446" alt="p1 9" src="https://github.com/user-attachments/assets/0816b587-2936-438d-ba24-09846919a120">


   
In this final part of the script, titled "Completion and Final Checks," the script wraps up the installation process and reboots the system to apply all the configurations and changes made during the process.


Echoing the Completion Message: 

The script first outputs a message saying, "Installation complete. Rebooting the system..." to both the terminal and the log file ($LOGFILE). This serves as a final indication to the user or administrator that the installation tasks are successfully completed and the system is ready to be rebooted. This message in the log file can also help track when the installation was finalized.


# Rebooting the System:

The command reboot is used to restart the system. This is crucial because several configuration changes (such as kernel updates, network settings, and partition mounting) often require a reboot to take full effect. By including this command at the end of the script, the system automatically reboots without requiring manual intervention.


Once rebooted, the system will boot with all the new configurations, firewall rules, network settings, and partition changes fully applied, completing the entire setup process. This approach ensures that everything works as expected after the reboot, particularly when new kernels or system-level changes are involved.

# Testing and Compatibility

Ensure the script is executable by running the following command:

chmod +x install.sh


Run the script as root or with sudo:

sudo ./install.sh


Test the script on multiple systems and validate that it works consistently. Make adjustments based on any specific configurations or hardware variations.


# Documentation and Troubleshooting


Log File: 

The script logs its progress to /var/log/install_script.log. You can review this file to troubleshoot any issues that arise during installation.


<img width="333" alt="p2 12L" src="https://github.com/user-attachments/assets/f4aacb07-4c08-4e55-9bc9-f1074d4e6772">


Error Handling: The script uses set -e to ensure that it exits immediately if any command fails.

# Conclusion and Key Takeaways

Creating an automated installation script like install.sh has been a valuable exercise in streamlining system setup and configuration. Here are some key takeaways and conclusions from this process:

1. Automating System Setup

By automating tasks such as disk partitioning, package installation, and user creation, I’ve significantly reduced the time and effort required to set up new systems. Automation ensures that each system is configured consistently, minimizing human error and improving reliability.

2. Disk Partitioning and Formatting

The script demonstrates the use of parted for disk partitioning and mkfs.ext4 for formatting. This approach ensures that the disk is prepared correctly for the installation process, and automating this step reduces the risk of manual errors.

3. Package Management

Using yum to install packages ensures that all required software is up-to-date and installed consistently. Automating package installation with yum simplifies the setup process and ensures that all necessary tools are available on the system.

4. Network Configuration

Configuring network settings through a script allows for consistent network setups across multiple systems. The script handles static IP configuration and restarts the NetworkManager to apply changes. It’s crucial to ensure the network configuration aligns with the environment to avoid connectivity issues.

5. User Management

The script automates user account creation and password management, including setting up users with appropriate permissions and expiring passwords on first login. This ensures that user accounts are created consistently and securely.

6. System Customization

Customizing system settings such as hostname, timezone, and locale through the script standardizes these configurations across multiple systems. It helps in maintaining consistency and ensuring that systems are correctly set up according to organizational standards.

7. Post-Installation Tasks

Configuring firewall rules and enabling essential services like SSH through the script ensures that the system is secure and accessible as soon as the installation is complete. Automating these tasks helps in setting up a secure and operational environment quickly.

# Key Takeaways

Consistency: Automating system setup helps maintain consistency across multiple installations, reducing the risk of configuration errors.

Efficiency: The script saves time by automating repetitive tasks, allowing for faster and more reliable system setups.

Error Reduction: Automation minimizes human error by standardizing configuration steps and applying them uniformly across systems.

Scalability: The script can be easily adapted for use with other systems or environments, making it scalable for various deployment scenarios.

Documentation: Including logging and detailed comments in the script ensures that the setup process is transparent and can be easily reviewed or modified in the future.

Overall, creating and using this script has greatly enhanced my ability to manage system installations efficiently and reliably.


---------------------------------------------------------------------

# Tier 3 Task 2: Implementing Disk Encryption for Data Security





