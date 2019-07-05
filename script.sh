#!/bin/bash
#################################################
#  Initialization CentOS 7.x script
#################################################
#  Auther: FANLIUSONG
#  Init_data: 20190702
#  Changelog:
#  1.add hosts
#################################################
# set hostname 
set_hostname(){
  choice='y'
  while(("$choice" == 'y' || "$choice" == 'Y'))
  do
    read -p "Please input mechine hostname:" nodename
    read -p "You set hostname : $nodename，are you sure [y/n]:" choice
    if [[ "$choice" == "y" ||   "$choice" == "Y" ||  "$choice" == "N" || "$choice" == "n" ]]
    then
      if [[ "$choice" == "y" ||  "$choice" == "Y" ]] 
      then
        hostnamectl set-hostname $nodename
        break
      fi
    else
      echo "you input error, exit"
      exit 0
    fi
  done
}

# add hosts
add_hosts(){
cat << EOF > /etc/hosts
127.0.0.1       localhost       localhost.localdomain   localhost4      localhost4.localdomain4
::1     localhost       localhost.localdomain   localhost6      localhost6.localdomain6
192.168.100.69 master1
192.168.100.67 master2
192.168.100.68 master3
192.168.100.63 work1
192.168.100.62 work2
EOF
}




# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to initialization OS."
    exit 1
fi

# set format
function format() {
    echo -e "\033[32m Success!!!\033[0m\n"
    echo "#########################################################"
}


# update kernel to ml
update_kernel(){
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
  yum --enablerepo=elrepo-kernel install -y kernel-ml
  grub2-set-default 0
  grub2-mkconfig -o /boot/grub2/grub.cfg
 }




#  NTP update
ntpdate(){
  echo "0 0 * * * /usr/sbin/ntpdate ntp1.aliyun.com  &>/dev/null" >> /etc/crontab
  hwclock -w
}

# add google dns
add_google_dns(){
echo  "nameserver  8.8.8.8" >> /etc/resolv.conf
}

# add public dns
public_dns(){
  echo > /etc/resolv.conf
  echo  "nameserver  114.114.114.114" >> /etc/resolv.conf
  echo  "nameserver  223.5.5.5" >> /etc/resolv.conf
  echo  "nameserver  8.8.8.8" >> /etc/resolv.conf
}

# add user fanliusong and set root and fanliusong ssh-key
add_user_fanliusong(){
  useradd fanliusong   &> /dev/null
  echo "yJNDSDcUjIDADJHe" |  passwd  fanliusong --stdin  &> /dev/null
  echo "fanliusong  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/fanliusong
  format 

  ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
  su - fanliusong
  ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
  format 
}


# disable selinux add iptables 
disable_firewalld(){
  [ `getenforce` != "Disabled" ] && setenforce 0 &> /dev/null && sed -i s/"^SELINUX=.*$"/"SELINUX=disabled"/g /etc/sysconfig/selinux
  systemctl stop firewalld
  systemctl disable firewalld
  systemctl stop  iptables  &> /dev/null
  systemctl disable iptables  &> /dev/null 
}

# set history format
history(){
  cat > /etc/profile.d/system-audit.sh << EOF
  HISTFILESIZE=20000            
  HISTSIZE=20000
  USER_IP=`who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'` 
  if [ -z $USER_IP ]
  then
    USER_IP=`hostname`
  fi
  HISTTIMEFORMAT="%F %T $USER_IP:`whoami` "     
  export HISTTIMEFORMAT
  EOF
  source  /etc/profile.d/system-audit.sh
}

# change i18n
i18n(){
  cp /etc/sysconfig/i18n /etc/sysconfig/i18n.bak
  echo 'LANG="en_US.UTF-8"' >/etc/sysconfig/i18n
}

# lock keyfile
chattr +ai /etc/passwd
chattr +ai /etc/shadow
chattr +ai /etc/group
chattr +ai /etc/gshadow
chattr +ai /etc/inittab


# stop system-services:
stop_service(){
  systemctl stop NetworkManager
  systemctl diable NetworkManager
  systemctl stop dnsmasq
  systemctl disable dnsmasq
}

# add yum repo
add_yum_repo(){
  yum install epel-release -y 
  yum clean all 
  yum makecache
  yum update -y
}

# set ssh  config
sshd_config(){
  sed -i 's/\#Port 22/Port 52113/' /etc/ssh/sshd_config
  sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  systemctl  restart  sshd 
}

# disable ipv6
disable_ipv6(){
  cat > /etc/modprobe.d/ipv6.conf << EOF
  alias net-pf-10 off
  options ipv6 disable=1
  EOF
  echo "NETWORKING_IPV6=off" >> /etc/sysconfig/network
}


# install basic command 
install_yum(){
yum install -y  vim wget openssl-devel ntpdate make gcc-c++  ncurses-devel net-snmp sysstat lrzsz zip unzip tree net-tools telnet screen gd asciinema 
yum groupinstall -y "development tools"  "Server Platform Development" 
}

# set system limits
set_limits(){
  ulimit -SHn 1024000 

  echo "ulimit -SHn 1024000" >> /etc/rc.d/rc.local 
  source /etc/rc.d/rc.local

  cat << EOF > /etc/security/limits.conf
  *    soft    nofile  655350
  *    hard    nofile  655350
  *    soft    nproc 655350
  *    hard    nproc 655350
  EOF
  sed -i 's/4096/655350/g' /etc/security/limits.d/20-nproc.conf
 }


#  kernel optimizer
kernel_parameter(){
cat > /etc/sysctl.conf  << EOF
net.ipv4.ip_forward = 1
vm.swappiness = 0
net.ipv4.neigh.default.gc_stale_time = 120

net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2

net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_max_orphans = 262114

net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144

net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

kernel.sysrq = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536

net.ipv4.ip_local_port_range = 1024 65000
EOF
}


##### install java 
install_java(){
  yum remove -y java  &> /dev/null
  tar zxf  jdk-8u161-linux-x64.tar.gz   -C    /opt
  sleep 5
  cd /opt

  ln -s jdk1.8.0_161  jdk

  cat /dev/null  > /etc/profile.d/jdk.sh
  echo '# jdk plugin'  >> /etc/profile.d/jdk.sh
  echo 'export JAVA_HOME=/opt/jdk'  >> /etc/profile.d/jdk.sh
  echo 'export JRE_HOME=/opt/jdk/jre'  >> /etc/profile.d/jdk.sh
  echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib'  >> /etc/profile.d/jdk.sh
  echo 'export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH'  >> /etc/profile.d/jdk.sh

  which java 
  java -version
  format
  echo "JAVA 安装完成·"
}

## install maven 
install_maven(){
  tar zxf  apache-maven-3.5.3-bin.tar.gz  -C  /opt
  sleep 5
  cd /opt
  ln -s apache-maven-3.5.3 maven
  
  cat /dev/null  >   /etc/profile.d/maven.sh
  echo '# maven plugin'  >> /etc/profile.d/maven.sh
  echo 'export MAVEN_HOME=/opt/maven'  >> /etc/profile.d/maven.sh
  echo 'export PATH=$PATH:$MAVEN_HOME/bin'  >> /etc/profile.d/maven.sh
  which mvn
  echo "maven 安装完成"
  format
}



main(){
  set_hostname
#  add_hosts
  update_kernel
  ntpdate
  add_google_dns
#  public_dns
  add_user_and_sshkey
  disable_selinux
  history
#  i18n
#  chattr 
  stop_service
  add_yum_repo
#  sshd_config
  disable_ipv6
  install_package
  set_limits
  kernel_parameter
  install_java
  install_maven

}

main
reboot






