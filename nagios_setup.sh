#!/usr/bin/bash
#Author: Manoj Gautam
#email: admin@fullstackadmin.openpy.com
#Date: 09/02/2015
#Purpose: Easy Installation for nagios

echo "Enter Password for nagios user"
read NAGIOSUSERPASSWD

echo "Enter an Administrative email address to receive alert message"
read ADMINEMAIL

echo "Enter password for 'nagiosadmin' user"
read NAGIOSADMINPASSWD

echo "Installing Necessary Prerequities"
yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp > /dev/null

useradd -m nagios
echo nagios:$NAGIOSUSERPASSWD | passwd

groupadd nagcmd
groupmod -a -G nagcmd nagios >& /dev/null
groupmod -a -G nagcmd apache >& /dev/null

echo "Downloading Nagios Source file"

cd /tmp/
rm -rf *

wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.4.tar.gz > /dev/null
wget http://nagios-plugins.org/download/nagios-plugins-2.0.tar.gz > /dev/null

echo "Extracting Nagios source code tarball"

tar -xvzf nagios-4.0.4.tar.gz > /dev/null
cd nagios-4.0.4
./configure --with-command-group=nagcmd > /dev/null
make all > /dev/null
make install > /dev/null 
make install-init > /dev/null
make install-config > /dev/null 
make install-commandmode > /dev/null

echo "Setting up Email for nagios admin "
sed "s/nagios@localhost/$ADMINEMAIL/" /usr/local/nagios/etc/objects/contacts.cfg  > /usr/local/nagios/etc/objects/test

mv /usr/local/nagios/etc/objects/test /usr/local/nagios/etc/objects/contacts.cfg > /dev/null


sudo make install-webconf > /dev/null

 htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin $NAGIOSADMINPASSWD #Tells htpasswd to run in batcmode  

echo "Starting Web server"
systemctl start httpd > /dev/null
if [$? -ne 0]; then
 echo "Cannot Start Web Server"
fi

echo "Compiling and Installing Nagios Plugins files.."
cd /tmp
tar -xvzf nagios-plugins-2.0.tar.gz > /dev/null
cd nagios-plugins-2.0
./configure --with-nagios-user=nagios --with-nagios-group=nagios > /dev/null
make > /dev/null
make install > /dev/null

echo "Starting Nagios.."
chkconfig --add nagios
chkconfig nagios on
chkconfig httpd on

echo "Verifying Sample Configuration files of nagios"

/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg > /dev/null
if [$? -ne 0 ]; then
 echo "Nagios Sample Configuration Failed"
 echo "Cannot Install Nagios"
 echo "Please refer to log files"
 exit 1
else 
 service nagios start > /dev/null
 if [$? -ne 0]; then
   echo "Cannot Start Nagios"
 else
  echo "Starting Nagios.."
 fi
fi 

echo "Modifying Selinux Contents.."

chcon -R -t httpd_sys_content_t /usr/local/nagios/sbin/ > /dev/null
chcon -R -t httpd_sys_content_t /usr/local/nagios/share/ > /dev/null

echo "Nagios Installation has been successfull.."
echo "Navigate to http://localhost/nagios/ using browser and log in to register clients"
