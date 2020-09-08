#!/bin/bash
#############################################################################
#                                                                           #
#       _               _              _____       _                        #
#      | |             | |            / ____|     | |                       #
#      | | ___  _ __ __| | __ _ _ __ | |  __  __ _| |_ ___  ___             #
#  _   | |/ _ \| '__/ _` |/ _` | '_ \| | |_ |/ _` | __/ _ \/ __|            #
# | |__| | (_) | | | (_| | (_| | | | | |__| | (_| | ||  __/\__ \            #
#  \____/ \___/|_|  \__,_|\__,_|_| |_|\_____|\__,_|\__\___||___/            #
#                                                                           #                                                      
#                                                                           #
#############################################################################
#     Agama Project                                                         #
#     Copyright (c) 2020 JordanGates Team                                   #
#     http://jordangates.com                                                #
#     Under The MIT license, https://opensource.org/licenses/MIT            #
#     Author: Mohammed AlShannaq <sam@ms.per.jo>                            #
#                                                                           #
#############################################################################
#                                                                           #
#  Installing Apache, Mysql 8 , PHP 7.4 into Centos 7                       #
#  Also Installing composer , ioncube , phpmyadmin, certbot                 #
#                                                                           #
#---------------------------------------------------------------------------#            
#  Tested on centos 7 minimal (Centos 7 ONLY)                               #
#  Tested on Umniah Cloud, Proxmox , Google cloud vm                        #
#############################################################################
VERSION=0.1

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1 
fi


OS_TARGET_VERSION_ID=7
OS_TARGET_ID="centos"

OS_ID=$(sed -e 's/^"//' -e 's/"$//' <<< `awk -F= '$1=="ID" { print $2  ;}' /etc/*-release`)
OS_VERSION_ID=$(sed -e 's/^"//' -e 's/"$//' <<< `awk -F= '$1=="VERSION_ID" { print $2  ;}' /etc/*release`)




# BEGIN: argv.sh https://github.com/kaelzhang/shell-argv/blob/master/argv.sh
# Copyright (c) 2013 Kael Zhang <i@kael.me>, contributors
# http://kael.me/

# The MIT license

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ------------------------------------------------------------------------

# START #######################################################################

# For most cases, you should change these settings

# Print debug info or not
DEBUG=

# Usage information of your command.
# For most cases, you should change this.
# Take `rm` command for example
usage(){
    echo "usage: $COMMAND [-options] ..."
    echo "       for help run $COMMAND -h"
}

splash(){
    echo ""
    echo ""  
    echo "    Apache,MySQL,PHP installer on $OS_TARGET_ID $OS_TARGET_VERSION_ID for Agama project"
    echo "    Copyright (c) 2020 JordanGates Team  "
    echo "    Author: Mohammed AlShannaq"
    echo "    Under the MIT License, https://opensource.org/licenses/MIT"
    echo ""
    echo "  ----> FRESH OS IS RECOMMENDED <---- "
    echo ""
    echo " >>>> This script works only with $OS_TARGET_ID linux version $OS_TARGET_VERSION_ID"
    echo ""
    echo "  This installer will install:"
    echo "  - Apache Web server"   
    echo "  - MySQL 8 Database Server"
    echo "  - PHP 7.4"
    echo "  - PHP Composer"
    echo "  - phpMyAdmin"
    echo "  - Let’s Encrypt Certbot"
    echo ""

}
splash

STRICT_ARGV=1


##############################################################################
# DO NOT CHANGE THE LINES BELOW >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# Simple basename: /bin/rm -> rm
COMMAND=${0##*/}

# tools
debug(){
    if [ -n "$DEBUG" ]; then
        echo "[D] $@" >&2
    fi
}

# parse argv --------------------------------------------------------------------------------

invalid_option(){
    # if there's an invalid option, `rm` only takes the second char of the option string
    # case:
    # rm -c
    # -> rm: illegal option -- c
    echo "$COMMAND: illegal option -- ${1:1:1}"
    usage

    # if has an invalid option, exit with 64
    exit 64
}

# print usage
#@jordangates no need for arguments , instead of that we will set the defaults here
if [[ "$#" = 0 ]]; then
    #echo "$COMMAND"
    #usage 
    echo ""
    echo "    We will install the defaults with: "
    echo "     - PHP 7.4"
   

    # if has an invalid option, exit with 64
    #exit 64
fi


REMAINS=
FLAGS=

FLAG_END=

remain_i=0
arg_i=0

split_push_arg(){
    # remove leading '-' and split combined short options
    # -vif -> vif -> v, i, f
    split=`echo ${1:1} | fold -w1`

    local arg
    for arg in ${split[@]}
    do
        FLAGS[arg_i]="-$arg"
        ((arg_i += 1))
    done
}

push_arg(){
    FLAGS[arg_i]=$1
    ((arg_i += 1))
}

push_remain(){
    REMAINS[remain_i]=$1
    ((remain_i += 1))
}

# pre-parse argument vector
while [ -n "$1" ]
do
    # case:
    # rm -v abc -r --force
    # -> -r will be ignored
    # -> args: ['-v'], files: ['abc', '-r', 'force']
    if [[ -n "$FLAG_END" ]]; then
        push_remain $1

    else
        case $1 in

            # case:
            # rm -v -f -i a b

            # case:
            # rm -vf -ir a b

            # ATTENSION: 
            # A wildcard in bash is not perl regex,
            # in which `'*'` means "anything" (including nothing)
            -[a-zA-Z]*)
                split_push_arg $1; debug "short option $1"
                ;;

            # rm --force a
            --[a-zA-Z]*)
                push_arg $1; debug "option $1"
                ;;

            # rm -- -a
            --)
                FLAG_END=1; debug "divider --"
                ;;

            # case:
            # rm -
            # -> args: [], files: ['-']
            *)
                push_remain $1; debug "file $1"

                # If strict mode on, flags must come before any remain items
                if [[ -n "$STRICT_ARGV" ]]; then
                    FLAG_END=1
                fi
                ;;
        esac
    fi

    shift
done

# END #######################################################################
# END: argv.sh https://github.com/kaelzhang/shell-argv/blob/master/argv.sh








# Your own logic >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# parse options
for arg in ${FLAGS[@]}
do
    case $arg in

        # There's no --help|-h option for rm on Mac OS 
        # [hH]|--[hH]elp)
        # help
        # shift
        # ;;

        -f|--force)
            OPT_FORCE=1;        debug "force        : $arg"
            ;;

        -i|--interactive)
            OPT_INTERACTIVE=1;  debug "interactive  : $arg"
            ;;

        -h|--help)
            OPT_HELP=1;  debug "help  : $arg"
            ;;

        # both r and R is allowed
        -[rR]|--[rR]ecursive)
            OPT_RECURSIVE=1;    debug "recursive    : $arg"
            ;;

        # only lowercase v is allowed
        -v|--verbose)
            OPT_VERBOSE=1;      debug "verbose      : $arg"
            ;;
        # accept the notice of installation
        -[yY])
            OPT_YESFORINSTALL=1;  debug "yes-for-install  : $arg"
            ;;

        *)
            invalid_option $arg
            ;;
    esac
done



#start real work
#check if not --help
if [ "$OPT_HELP" == 1 ]; then
    echo "HELP HELP"
exit 1;
fi

#check for agree to install
if [ "$OPT_YESFORINSTALL" == 1 ]; then
response="Y"
else
read -r -p "Are you sure? [y/N] " response
fi

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then

##############################################################################
# Test cases, you DON'T NEED them in your project
echo "force: $OPT_FORCE"
echo "interactive: $OPT_INTERACTIVE"
echo "recursive: $OPT_RECURSIVE"
echo "verbose: $OPT_VERBOSE"
echo "flags: ${FLAGS[@]}"
echo "remains: ${REMAINS[@]}"
echo "help: $OPT_HELP"


echo "Preparing ..."
echo ""
if [ $OS_ID != $OS_TARGET_ID ]  ||  [ $OS_VERSION_ID -ne $OS_TARGET_VERSION_ID  ]; then
   echo "ERROR: This script is for $OS_TARGET_ID $OS_TARGET_VERSION_ID linux & it looks like you are running $OS_ID $OS_VERSION_ID" 1>&2
   echo "... Use the correct installation file"
   exit 1
fi

# Predicate that returns exit status 0 if the mysql(1) command is available,
# nonzero exit status otherwise.
is_mysql_command_available() {
  which mysql > /dev/null 2>&1
}

# Predicate that returns exit status 0 if the php(1) command is available,
# nonzero exit status otherwise.
is_php_command_available() {
  which php > /dev/null 2>&1
}

# Predicate that returns exit status 0 if the database root password
# is set, a nonzero exit status otherwise.
is_mysql_root_password_set() {
  ! mysqladmin --user=root status > /dev/null 2>&1
}


if is_php_command_available; then
  echo "ERROR: PHP looks like it's already installed ... cannot continue without fresh OS"
  echo "... Use this script with fresh linux"
  exit 1
fi

if is_mysql_command_available; then
  echo "ERROR: The MySQL/MariaDB Server looks like it is installed... cannot continue without fresh OS"
  echo "... Use this script with fresh linux"
  exit 1
fi

echo "Checking SELinux status .... "
SELINUXSTATUS=$(getenforce)
if [ $SELINUXSTATUS == "Disabled" ]
then
    echo "SELinux is Dsiabled .... i will skip into the next step"
else
    echo "SELinux is Enabled , It should be Disabled ..."
    echo "Disabling SELinux ..."
    setenforce 0
    SELINUXCONFIG="/etc/selinux/config"
echo "Permanently disable SELinux even after boot .. writing to $SELINUXCONFIG"
/bin/cat <<EOM >$SELINUXCONFIG
#generated by JordanGates Agama installer to disable the selinux
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted

EOM
fi


echo "Try to update the system ..."
yum -y update
echo "Installing necessary packages by agama ..."
yum -y install curl openssl zip unzip wget pv nano mlocate git

echo ""
echo "Installing Apache Server ..."
echo ""

yum -y install httpd
systemctl enable httpd
systemctl start httpd
systemctl status httpd
#installing mod_ssl
yum -y install mod_ssl
httpd -v
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
systemctl restart firewalld

echo ""
echo "Configuring Apache ... "
HTTPD_ADDITIONAL_CONFFILE="/etc/httpd/conf.d/agama-basic.conf"
echo "Allowing .htaccess file in /var/www/html ... "
/bin/cat <<EOM >$HTTPD_ADDITIONAL_CONFFILE
#generated by agama to allow .htacces file on /var/www/html
<Directory "/var/www/html">
    AllowOverride All
</Directory>
EOM

echo "Installing certbot-apache to handle SSL using Let's Encrypt ..."
yum -y install certbot-apache
echo "Restarting apache ... "
systemctl restart httpd
echo " >>> to run certbot run: "
echo " >>> $ certbot --apache "
echo " remember that if you want to renew ssl certificates cerbot handles you must add"
echo " * */12 * * * /usr/bin/certbot renew >/dev/null 2>&1 "
echo "to your server crontab"
echo "you are adviced to take a look into https://linuxhostsupport.com/blog/how-to-install-lets-encrypt-on-centos-7-with-apache/ "
echo "for more information about certbot"
echo ""
echo "Restarting Apache ..."
systemctl restart httpd

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum-config-manager --enable remi-php74

echo ""
echo "Installing PHP ..."
echo ""

yum -y module install php:remi-7.4
yum -y update
yum -y install php php-common php-mysqlnd php-opcache php-gd php-xml php-mbstring php-intl php-json php-cli php-zip php-xmlrpc php-pear php-devel gcc 
yum -y install ImageMagick ImageMagick-devel ImageMagick-perl

echo "Installing Database server .."
echo ""
echo "Remove any MariaDB repo.."
echo ""
yum -y remove mariadb.x86_64 mariadb-libs.x86_64 mariadb-server.x86_64
yum -y remove mariadb.x86_64 mariadb-bench.x86_64 mariadb-devel.i686 mariadb-devel.x86_64 mariadb-embedded.i686 mariadb-embedded.x86_64 mariadb-embedded-devel.i686 mariadb-embedded-devel.x86_64 mariadb-libs.i686 mariadb-libs.x86_64 mariadb-server.x86_64 mariadb-test.x86_64
yum -y remove phpMyAdmin.noarch
rpm -e --nodeps "mariadb-libs-5.5.56-2.el7.x86_64"
rpm -e --nodeps "mariadb-server-5.5.56-2.el7.x86_64"

echo "Install MySQL Server ..."
echo ""
yum -y localinstall https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
yum -y install mysql-community-server
echo "Starting MySQL Services ..."
systemctl start mysqld
systemctl enable --now mysqld
systemctl status mysqld
echo "Stoping Mysql for some tricks ...."
systemctl stop mysqld
RNDPWD1=`openssl rand -base64 32`
echo ""
echo "mysql root password set to: $RNDPWD1"
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$RNDPWD1';" > /tmp/init-file.txt
echo "running MySQL root password change command and give it 10 seconds to complete .."
timeout 10 mysqld --user=mysql --init-file=/tmp/init-file.txt 


#kill prev mysql user session
pkill -U mysql



echo "writing ~/.my.cnf file ..."
FILE="/root/.my.cnf"
/bin/cat <<EOM >$FILE
#.my.cnf generated by JordanGates team while installing mysql/mariadb server
#JordanGates team
[client]
user=root
password="$RNDPWD1"
EOM
echo "Killing Temp Mysql session ..."
pkill -U mysql
echo "Try to restart MySQL in normal way .."
systemctl enable --now mysqld
systemctl restart mysqld
systemctl status mysqld

#demonstrate mysql_secure_installation programmatically
echo "Demonstrate mysql_secure_installati	on programmatically ..."
SQLFILE="/tmp/sql.sql"
/bin/cat <<EOM >$SQLFILE
#sql.sql generated by JordanGates team while installing mysql/mariadb server
#demonstrate mysql_secure_installation programmatically
#This file should be deleted after success of install.
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
  create database agama;
EOM
echo "execute some sql command from tmp .."
mysql < /tmp/sql.sql



echo "Remove tmp files .."
rm -fr /tmp/init-file.txt
rm -fr /tmp/sql.sql
echo ""
echo "Restarting Mysql Again and Enable it ... "
systemctl restart mysqld
systemctl status mysqld



echo ""
echo "Installing PHP composer .. may be we need it in future"
echo ""

EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --install-dir=/bin --filename=composer
RESULT=$?
rm composer-setup.php

echo "Installing ioncube loader for PHP ..."
yum -y install pv
wget -P /tmp/ https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
cd /tmp/
pv /tmp/ioncube_loaders_lin_x86* | tar xzf -
cd ioncube/
mv /tmp/ioncube/ioncube_loader_lin_7.4.so /usr/lib64/php/modules/
chmod 755 /usr/lib64/php/modules/ioncube_loader_lin_7.4.so
echo "zend_extension=/usr/lib64/php/modules/ioncube_loader_lin_7.4.so" > /etc/php.d/00-ioncube.ini
rm -dfr /tmp/ioncube_loaders_lin_x86-64*
rm -dfr /tmp/ioncube

systemctl restart httpd

echo "Installing phpMyAdmin without any configuration change ... "
yum -y install phpmyadmin
echo ""
echo " >>> You must enable access to phpMyAdmin manually if you want to access it from outsite , reffer for "
echo " https://unix.stackexchange.com/questions/214881/why-am-i-denied-access-to-phpmyadmin"
echo "" 
systemctl restart httpd




echo "Thank you for using Agama project ..... "
exit 0;


else
echo ""
echo "ERROR: Exit without installing due not accepting"
echo ""
exit 1;

fi #for $response

