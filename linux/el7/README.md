# EL7 Folder contents

This folder contains scripts and tools and files related to EL7 OS (RHLE 7 , Centos 7)



## install_amp_el7.sh

** Installing Apache, Mysql & PHP which known as (AMP) into Centos 7 Fresh OS **

To run the script into your server , login to your centos 7 fresh installed OS server as root using SSH and run the following command:

```bash
yum -y install wget; cd /root/; wget https://raw.githubusercontent.com/Jordan-Gates/agama/master/linux/el7/install_amp_el7.sh; chmod 755 install_amp_el7.sh; /root/install_amp_el7.sh
```

After you finish Instaling process do not forget to delete the file `install_amp_el7.sh`
