# EL8 Folder contents

This folder contains scripts and tools and files related to EL8 OS (RHEL 8 , Centos 8)



## install_amp_el8.sh

**Installing Apache, Mysql & PHP which known as (AMP) into Centos 8 Fresh OS**

To run the script and Install AMP (Apache,MySQL,PHP), Login to your centos 8 fresh installed OS server as A `root` using SSH and run the following command:

```bash
yum -y install wget; cd /root/; wget https://raw.githubusercontent.com/Jordan-Gates/agama/master/linux/el8/install_amp_el8.sh; chmod 755 install_amp_el8.sh; /root/install_amp_el8.sh
```

After you finish installing process do not forget to delete the file `install_amp_el8.sh` by running `rm /root/install_amp_el8.sh` command.
