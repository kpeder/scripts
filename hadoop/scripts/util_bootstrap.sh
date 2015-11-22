#!/bin/bash

# ensure the system is up to date
yum update -y

# install some stuff
yum install bind-utils nc telnet nmap ntp sysstat httpd zip unzip wget -y

# install system stress tool
curl "http://dl.fedoraproject.org/pub/epel/6/x86_64/stress-1.0.4-4.el6.x86_64.rpm" -o stress-1.0.4-4.el6.x86_64.rpm
yum install -y stress-1.0.4-4.el6.x86_64.rpm

# install the aws command line
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# install ambari and hdp dependencies
  # set open file limit
  echo "fs.file-max = 12288" >> /etc/sysctl.conf; sysctl -p
  # selinux permissive mode
  setenforce 0 # needed for Ambari setup to run; not persistent
  # kill the firewall for now
  /etc/init.d/iptables stop; chkconfig iptables off
  # set up ntp; default configuration will do
  chkconfig ntpd on; ntpdate pool.ntp.org; /etc/init.d/ntpd start # rolled back systemctl for CentOS 6
  # grab the java RPM from S3 and install
  /usr/local/bin/aws s3 cp s3://kpedsotherbucket/packages/jre-7u45-linux-x64.rpm jre-7u45-linux-x64.rpm
  yum install jre-7u45-linux-x64.rpm -y
  # grab the Ambari repo
  wget -nv http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.1.1/ambari.repo -O /etc/yum.repos.d/ambari.repo
  mv ambari.repo /etc/yum.repos.d/
  # installation
  yum install ambari-server -y
  # configuration
  ambari-server setup -j /usr/java/default -s
  # startup
  nohup /etc/init.d/ambari-server start
 
# clean up
rm -rf awscli-bundle jre-7u45-linux-x64.rpm

# configure iam user/key and sudoers
useradd kpedersen -d /home/kpedersen -s /bin/bash
usermod -G wheel,adm kpedersen
mkdir -p /home/kpedersen/.ssh
curl -s "http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key/" -o /home/kpedersen/.ssh/authorized_keys
chmod 700 /home/kpedersen/.ssh
chmod 600 /home/kpedersen/.ssh/authorized_keys
chown -R kpedersen:kpedersen /home/kpedersen/.ssh
sed -i s/centos/kpedersen/g /etc/sudoers.d/*

# clean up bash history
cat /dev/null > /root/.bash_history
cat /dev/null > /home/centos/.bash_history