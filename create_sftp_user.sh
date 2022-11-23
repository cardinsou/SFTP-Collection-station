#!/usr/bin/bash

usage() {
	echo "Usage: create_sftp_user.sh [-u <username>]";
	exit 1;
}

checkAdmin() {
	if (( $EUID != 0 ))
	then
		echo "[-] Error - Please use sudo ./create_sftp_user.sh [-u <username>]";
		exit 1;
	fi
}

checkPackage() {
	dpkg -s $1 &> /dev/null
	if [ $? -eq 1 ]
	then
		echo "[+] Package $1 not found, installing ...";
		apt-get -qq -y install $1 &> /dev/null;
	fi
}

verifyUserExist() {
	if id -u "$username" &> /dev/null
	then
    	echo "[-] Error - User already exist";
    	exit 1;
    fi;
}

createGroup() {
	sftp_group_name="sftp"
	sftp_handler_group_name="sftp-handler"
	if ! grep -q $sftp_group_name /etc/group
	then
		echo "[+] Creating group $sftp_group_name ...";
		groupadd $sftp_group_name &> /dev/null
	fi
	if ! grep -q $sftp_handler_group_name /etc/group
	then
		echo "[+] Creating group $sftp_handler_group_name ...";
		groupadd $sftp_handler_group_name &> /dev/null
	fi
}

createJailFolder() {
	jail_folder="/sftp_home"
	if [ ! -d "$jail_folder" ]
	then
		echo "[+] Creating jail folder $jail_folder ...";
		mkdir $jail_folder
	fi
}

createUser() {
	echo "[+] Creating user $username ...";
	useradd -k /home/skel/skel/skel -G $sftp_group_name -s /bin/false -m -d $jail_folder/$username $username;
}

createUploadFolder() {
	echo "[+] Creating upload folder ...";
	mkdir $jail_folder/$username/uploads
}

setPermission() {
	echo "[+] Setting permissions ...";
	chown root:root $jail_folder/$username
	chmod 755 $jail_folder/$username
	chown $username:$sftp_handler_group_name $jail_folder/$username/uploads/
	chmod -R 770 $jail_folder/$username/uploads/
	chmod g+s $jail_folder/$username/uploads/
}

configSSH() {
	checkPackage "openssh-server"
	if ! grep -q $sftp_group_name /etc/ssh/sshd_config
	then
		echo "[+] Configuring SSH for jailed SFTP ...";
		cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bck
		echo "" >> /etc/ssh/sshd_config
		echo "Match Group $sftp_group_name" >> /etc/ssh/sshd_config
		echo "	ForceCommand internal-sftp" >> /etc/ssh/sshd_config
		echo "	PasswordAuthentication yes" >> /etc/ssh/sshd_config
		echo "	ChrootDirectory %h" >> /etc/ssh/sshd_config
		echo "	PermitTunnel no" >> /etc/ssh/sshd_config
		echo "	AllowAgentForwarding no" >> /etc/ssh/sshd_config
		echo "	AllowTcpForwarding no" >> /etc/ssh/sshd_config
		echo "	X11Forwarding no" >> /etc/ssh/sshd_config
		echo "	PermitTTY no" >> /etc/ssh/sshd_config
	fi 
	echo "[+] Restarting SSH ...";
	systemctl restart ssh
}

enablePasswd() {
	echo "[+] Enabling password change for user $username to users member of $sftp_handler_group_name";
	echo "" >> /etc/sudoers
	echo "#Enable users member of $sftp_handler_group_name to change password for user $username" >> /etc/sudoers
	echo "%$sftp_handler_group_name   ALL=/usr/bin/passwd $username" >> /etc/sudoers
}

printInfo() {
	echo "[+] Configuration complete";
	echo "[+] Remember to set password for user $username with command: passwd $username";
	echo "[+] Remember to add SFTP handler users to group $sftp_handler_group_name with command: usermod -aG $sftp_handler_group_name <username>"
}

while getopts ":u:" flag
do
	case ${flag} in
        u) [ ! -z "${OPTARG}" ] || usage
		   username=${OPTARG}		 
		   checkAdmin;
		   verifyUserExist;
		   createGroup;
		   createJailFolder;
		   createUser;
		   createUploadFolder;
		   setPermission;
		   configSSH;
		   enablePasswd;
		   printInfo;
		   exit;;
	esac
done

usage;
