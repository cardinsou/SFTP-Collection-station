# SFTP Collection station

This script is made to automatically configure a jailed SFTP environment on Ubuntu 22.04 OS. The environment could be used to acquire files from external sources with the following benefit:

- Usage of temporary SFTP users
- Usage of jailed users, SFTP users cannot move through filesystem, they are locked in their home folder
- Every user inserted in "sftp-handlers" group can:
  - modify files in sftp users home folder
  - change password for sftp users

## create_sftp_user.sh

Usage:

```
create_sftp_user.sh -u <username>
```

The script must be executed with administrative privileges, so if you are not root run it with sudo command. Script automates the following configurations:

- **Create a jailed environment**
  
  The script create the home folder for SFTP user in "/sftp_home"

- **Create user and groups**
  
  The script create the user specified with -u parameter with home folder located in "/sftp_home/username".
  
  The script create also two groups:
  - sftp-login, used to apply sftp configuration in SSH daemon file, every user in sftp group can login only with SFTP protocol
  - sftp-handlers, used to manage sftp users, every user in sftp handlers-group has read and write permissions on sftp users home and can change password for sftp users.  
  
- **Configure SSH daemon for SFTP**
  
  The script apply all the necessary configuration to SSH daemon in order to use only SFTP protocol for specified users.
  
- **Configure sudo**
  
  The script configure sudo in order to permit execution of command "sudo passwd <sftp user username>" to all users member of "sftp-handlers" group

You can run the script multiple time to create more than one sftp user.

## Daily usage

- Change sftp user password
- Share sftp username + password 
- Wait files upload
- Manage files 

## Troubleshooting and modification

- **Login after hardening**
  
  If the machine was hardened with [this](https://github.com/cardinsou/Ubuntu-22.04-hardening) script or if you are using google OTP libpam you need to modify /etc/pam.d/sshd configration file:
  
  Before:
  ```
  auth required pam_google_authenticator.so
  ```
  After:
  ```
  auth required pam_google_authenticator.so nullok
  ``` 
  SFTP users hasn't OTP configuration, so they need a "nullok" from PAM to login. With the above modification:
  - users that has OTP configuration need a OTP code to login
  - users that hasn't OTP configuration can use only username + password

- **The environment is not working**

  If you add a current logged in user to sftp-handlers group you need to logout and re-login in order to use the new permissions. Reboot if necessary.
