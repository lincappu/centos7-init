#!/bin/bash
#################################################
#  CentOS 7.x system configure initial scripts
#################################################
#  $Version:    v2.0
#  $Author:     FLS
#  $Create_data:    20190702
#  $Description: CentOS 7.x system configure initial scripts
#################################################
IPS=''
CURRENT_PWD=$(pwd)

# check user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to initialization OS."
    exit 1
fi


# set format
function format() {
#    echo -e "\033[32m Success!!!\033[0m\n"
    echo "#########################################################"
}


# install epel repo and updte yum repo.
function update_yum_repo(){
    echo "开始更新系统 yum 仓库......"
    yum install epel-release -y
    yum install https://centos7.iuscommunity.org/ius-release.rpm  -y
    yum clean all
    yum makecache
    yum  update --skip-broken  -y

}

format
sleep 3

# install basic package.
function install_basic_package(){
    echo "开始更新软件包......"
    yum install -y  \
wget \
openssl-devel  \
gcc \
gcc-c++  \
ntpdate \
make \
gcc-c++  \
ncurses* \
net-snmp \
sysstat \
lrzsz \
zip  \
unzip \
net-tools \
telnet \
screen \
gd \
sshpass  \
htop \
iftop \
net-tools  \
tree  \
yum-utils  \
git \
curl  \
telnet  \
pcre  \
pcre-devel  \
ntpdate  \
lynx  \
tmux  \
mc  \
nload  \
atop  \
expect



}

format
sleep 3

# add hosts
function add_hosts(){
cat << EOF >> /etc/hosts
EOF
}

format

function set_machine_hostname(){
while :
    do
    clear
    echo "请输入你想设置的hostname："
    echo "输入确认： y"
    echo "重新输入： n"
    echo "退出脚本： q"
    read -p "Please input the machine hostname:" nodename
    read -p "You input hostname is : [ $nodename ]，are you sure [y/n/q]:" choice
    if [[ "$choice" == "y"  || "$choice" == "n" ||  "$choice" == "q" ]];then
        if [[ "$choice" == "q" ]];then
            echo "scripts exit......"
            exit 0
        fi
        if [[ "$choice" == "n" ]];then
            echo "please input again"
            continue
        fi
        if [[ "$choice" == "y" ]];then
            hostnamectl set-hostname $nodename
            break
        fi
    else
        echo "you input error,please read above prompt and input again."
        continue
    fi
    done
    format
    # add hosts record.
    net_ip=$(ifconfig eth0  |  grep  -w "inet" | awk '{print $2}')
    if [ -n $net_ip ];then
        echo "本机 eth0 网卡 ip 为： $net_ip "
        echo "$net_ip $nodename"
        echo "$net_ip $nodename" >> /etc/hosts
        echo "添加主机名的解析记录OK:"
        sleep 3
    else
        echo "没有获取到有效的ip 地址，是确认网卡名称是否是 eth0"
        exit 1
    fi

}

format
sleep 3

# add user and set user authorization.
function add_user(){
while :
do
    format
    echo "开始添加用户及设置用户密码:"
    echo "1、选择是否设置 root 密码."
    echo "2、选择添加用户、设置密码及创建 ssh-key."
    echo "3、选择是否为用户设置 sudoers 权限."

    read -p "是否要修改 root 密码（y/n）： "  change_root_pass_or
    if [[ $change_root_pass_or == "y" ]];then
        read -p "请输入 root 的密码：["  root_pass
        echo "你要设置的 root 密码为：[ $root_pass"
        sleep 3
        echo "$root_pass" |  passwd  root  --stdin  &> /dev/null
    else
        echo "你已选择不设置 root 密码."
    fi
    echo
    while :
    do
        read -p "请输入要添加的用户名:["  add_user_name
        read -p "请输入要添加用户的密码:["  add_user_pass
        echo "将要创建的用户及密码为： $add_user_name   $add_user_pass"
        sleep 3
        useradd $add_user_name
        echo "$add_user_pass" |  passwd  $add_user_name --stdin  &> /dev/null
        echo "为用户生成 ssh-key"
        su -c 'ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa'  $add_user_name
        echo
        read -p "是否为用户设置 sudoers权限 (y/n):[" set_sudoers_or
        if [[ $set_sudoers_or == "y" ]];then
            read -p "请输入 sudoers规则（root权限规则为: [ $add_user_name  ALL=(ALL)  NOPASSWD:ALL ]:  ["  set_sudoers_content
            echo "$set_sudoers_content" > /etc/sudoers.d/$add_user_name
            echo "用户$add_user_name  sudoers 规则添加成功，规则如下："
            cat /etc/sudoers.d/$add_user_name
        else
            echo "您输入有误，此步骤跳过。"

        fi
        echo "添加用户 $add_user_name 成功。"
        echo

        read -p  "是否继续添加用户(y/n)： " add_user_contine
        if [[ $add_user_contine == 'y' ]];then
            continue
         else
            break
        fi
    done
    break
done
}

format
sleep 3

# update kernel to ml
function update_kernel(){
    echo "更新内核版本："
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install -y kernel-ml
    grub2-set-default 0
    grub2-mkconfig -o /boot/grub2/grub.cfg
}

format
sleep 3

#  NTP update
function update_ntpdate(){
    echo "开始进行 ntpdate 时钟同步...."
    echo "0 0 * * * /usr/sbin/ntpdate ntp1.aliyun.com  &>/dev/null" >> /etc/crontab
    hwclock -w
}

format
sleep 3

# add public dns
function add_public_dns(){
    echo "开始为系统增加公共 DNS"
    echo > /etc/resolv.conf
    echo  "nameserver  114.114.114.114" >> /etc/resolv.conf
    echo  "nameserver  223.5.5.5" >> /etc/resolv.conf
    echo  "nameserver  8.8.8.8" >> /etc/resolv.conf
}

format
sleep 3


# disable selinux add iptables 
function disable_firewalld(){
    echo "开始关闭系统防火墙......"
    [ `getenforce` != "Disabled" ] && setenforce 0 &> /dev/null && sed -i s/"^SELINUX=.*$"/"SELINUX=disabled"/g /etc/sysconfig/selinux
    systemctl stop firewalld  &> /dev/null
    systemctl disable firewalld &> /dev/null
    systemctl stop  iptables  &> /dev/null
    systemctl disable iptables  &> /dev/null
}

format
sleep 3

# set history format
function set_history(){
    echo "开始为系统配置历史命令记录......"
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

format
sleep 3

# lock keyfile.  NOTICE：设置完 keyfile 后不能再对这些文件进行修改，会影响添加用户及修改密码功能。
function set_lock_keyfile(){
    chattr +ai /etc/passwd
    chattr +ai /etc/shadow
    chattr +ai /etc/group
    chattr +ai /etc/gshadow
}


# stop system services:
function disable_system_service(){
  systemctl stop NetworkManager
  systemctl disable NetworkManager
  systemctl stop dnsmasq
  systemctl disable dnsmasq
}

format
sleep 3

# set ssh config
function set_sshd_config(){
  sed -i 's/\#Port 22/Port 10222/' /etc/ssh/sshd_config
  sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  systemctl  restart  sshd
  echo "修改 ssh 配置完成"
  format
}

format
sleep 3

# disable ipv6
function disable_ipv6(){
  cat > /etc/modprobe.d/ipv6.conf << EOF
alias net-pf-10 off
options ipv6 disable=1
EOF
  echo "NETWORKING_IPV6=off" >> /etc/sysconfig/network
  echo "禁用 ipv6 配置完成"
}

format
sleep 3

# set system limits
function set_system_limits(){
    ulimit -SHn 102400
    echo "ulimit -SHn 102400" >> /etc/rc.d/rc.local
    source /etc/rc.d/rc.local
    cat << EOF > /etc/security/limits.d/90-nproc.conf
*    soft    nofile  65535
*    hard    nofile  65535
*    soft    nproc   65535
*    hard    nproc   65535
*    soft    core    unlimited
*    hard    core    unlimited
EOF
    sed -i 's/4096/655350/g' /etc/security/limits.d/20-nproc.conf
    echo "设置系统 limits 参数完成"
}

format
sleep 3

#  kernel optimizer
function update_kernel_parameter(){
    cat > /etc/sysctl.conf  << EOF

# this  configuration is add by centos7_init_scripts.
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
net.core.somaxconn = 65535

net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

kernel.sysrq = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536

net.ipv4.ip_local_port_range = 1024 65000
EOF
    sysctl -p
    echo "更新系统内核参数完成"
}

format
sleep 3

# install java 1.80
function install_openjdk(){
    yum remove -y java  &> /dev/null
    yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel  -y
    echo "open jdk 安装完成·"

}

format
sleep 3

#  install  oraclejdk 8u202
function install_oraclejdk(){
      yum remove -y java  &> /dev/null
      wget https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
      tar zxf  jdk-8u202-linux-x64.tar.gz -C /opt
      sleep 2
      cd /opt
      ln -s jdk1.8.0_202  jdk
      cat /dev/null  > /etc/profile.d/jdk.sh
      echo '#jdk plugin'  >> /etc/profile.d/jdk.sh
      echo 'export JAVA_HOME=/opt/jdk'  >> /etc/profile.d/jdk.sh
      echo 'export JRE_HOME=/opt/jdk/jre'  >> /etc/profile.d/jdk.sh
      echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib'  >> /etc/profile.d/jdk.sh
      echo 'export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH'  >> /etc/profile.d/jdk.sh
      source /etc/profile.d/jdk.sh
      which java
      java -version
      format
      echo "oracle jdk 安装完成·"

      cd ${CURRENT_PWD}

}

format
sleep 3

# install maven
function install_maven(){
  wget https://archive.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz
  tar zxf  apache-maven-3.5.3-bin.tar.gz  -C  /opt
  sleep 2
  cd /opt
  ln -s apache-maven-3.5.3 maven
  
  cat /dev/null  >   /etc/profile.d/maven.sh
  echo '# maven plugin'  >> /etc/profile.d/maven.sh
  echo 'export MAVEN_HOME=/opt/maven'  >> /etc/profile.d/maven.sh
  echo 'export PATH=$PATH:$MAVEN_HOME/bin'  >> /etc/profile.d/maven.sh
  which mvn
  echo "maven 安装完成"
}

format
sleep 3

# install php
function install_php(){
    yum install php72u* nginx httpd -y
    systemctl start php-fpm.service
    systemctl enable php-fpm.service
}

format
sleep 3

function install_nodejs(){
    yum install https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_12.x/el/7/x86_64/nodesource-release-el7-1.noarch.rpm -y
    cat > /etc/yum.repos.d/nodesource-el7.repo <<- "EOF"
[nodesource]
name=Node.js Packages for Enterprise Linux 7 - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_12.x/el/7/$basearch
enabled=1
gpgcheck=0

[nodesource-source]
name=Node.js for Enterprise Linux 7 - $basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_12.x/el/7/SRPMS
enabled=0
gpgcheck=1
EOF

    yum makecache
    yum install nodejs -y

    npm config set registry https://registry.npm.taobao.org/
    npm config set sass_binary_site https://npm.taobao.org/mirrors/node-sass/
    npm config set electron_mirror https://npm.taobao.org/mirrors/electron/

    npm cache clean -f
    npm completion >> /etc/bash_completion.d/npm
    npm install n npm get-port-cli hasha-cli http-server live-server prettier -g
    export NODE_MIRROR=https://npm.taobao.org/mirrors/node/
    echo "export NODE_MIRROR=https://npm.taobao.org/mirrors/node/" >> /etc/profile
    source /etc/profile
    n latest
    n stable

}

format
sleep 3

# install mysql 55/56/57/80
function install_mysql(){
    echo "开始安装mysql，下载官方仓库中......"
    yum install  https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm  -y
    format
    echo "下载成功，已添加的 mysql存储库："
    yum repolist enabled | grep "mysql.*-community.*"
    format
    echo "当前mysql 存储库中所有mysql版本如下："
    yum repolist all | grep mysql
    format
    read -p "请输入你想安装的mysql版本：[55/56/57/80]，选择版本后其他版本会禁用：["  mysql_version
    if [[ "$mysql_version" == "55" ||  "$mysql_version" == "56" ]];then
        yum-config-manager --disable mysql80-community
        yum-config-manager --enable mysql$mysql_version-community
        format
        echo "确认激活的 mysql 版本:"
        yum repolist all | grep mysql
        format
        sleep 6
        format
        echo "开始安装 mysql-community-server......"
        yum install mysql-community-server  -y
        systemctl start mysqld
        systemctl enable mysqld
        format
        echo "mysql 状态如下："
        systemctl status mysqld
        mysql_status=`systemctl status mysql | grep Active | awk '{print $3}'|awk -F '(' '{print $2}' | awk -F ')' '{print $1}'`
        if  [[ "$mysql_status" == "running" ]];then
            echo "mysql ${mysql_version} 已安装完成并启动"
        else
            echo "mysql 启动异常，请检查。"
            exit 20
        fi
        format
        read -p "是否继续设置 root 密码及权限(y/n): " set_mysql_root_pass_or
        if [[ "$set_mysql_root_pass_or" == "y" ]];then
            echo "下面将为 mysql 设置 root 密码，请按以下操作进行 \n
Enter password:  直接输入回车 \n
New password: 输入要设置的 root 密码 \n
Confirm new password: 重复输入要设置的 root 密码 "
            echo
            mysqladmin -u root -p password
            format
            echo "请在下面输入用户授权规则(用单引号)，例：\n
[ GRANT ALL privileges ON *.* TO 'root'@'%' identified by 'password' WITH GRANT OPTION; ]"
            read -p "要设置grant rule:[" mysql_grant_rule
            read -p "请输入当前mysql root的密码:["  mysql_root_pass
            mysql -uroot -p"${mysql_root_pass}" -e "${mysql_grant_rule}"
            mysql -uroot -p"${mysql_root_pass}" -e "flush privileges;"
            format
            echo "mysql root 密码设置及授权完成,root 用户授权规则如下："
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'localhost';"
            format
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'%';"
            format
        fi

    elif [[ "$mysql_version" == "57" ]];then
        yum-config-manager --disable mysql80-community
        yum-config-manager --enable mysql57-community
        format
        echo "确认激活的 mysql 版本:"
        yum repolist all | grep mysql
        sleep 6
        echo "开始安装 mysql-community-server......"
        yum install mysql-community-server  -y
        systemctl start mysqld
        systemctl enable mysqld
        format
        echo "mysql 状态如下："
        systemctl status mysqld
        mysql_status=`systemctl status mysqld | grep Active | awk '{print $3}'|awk -F '(' '{print $2}'| awk -F ')' '{print $1}'`
        if  [[ "$mysql_status" == "running" ]];then
            echo "mysql 5.7已安装完成并启动"
        else
            echo "mysql 启动异常，请检查。"
            exit 21
        fi
        format
        read -p "是否继续设置 root 密码及权限(y/n): " set_mysql_root_pass_or
        if [[ "$set_mysql_root_pass_or" == "y" ]];then
            passlog=$(grep 'temporary password' /var/log/mysqld.log)
            pass=${passlog:${#passlog}-12:${#passlog}}
            mysql -uroot -p"${pass}" -e "set global validate_password_policy=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password_length=4;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password_mixed_case_count=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password_number_count=0;" --connect-expired-password
            read -p "请输入 mysql root 密码：" mysql_root_pass
            mysql -uroot -p"${mysql_root_pass}" -e "update mysql.user set host='%' where user='root';" --connect-expired-password
            mysql -uroot -p"${mysql_root_pass}" -e "flush privileges;" --connect-expired-password
            echo "mysql root 密码设置及授权完成,root 用户授权规则如下："
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'localhost';"
            format
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'%';"
            format
        fi

    elif [[ "$mysql_version" == "80" ]];then
        echo "开始安装 mysql-community-server......"
        yum install mysql-community-server  -y
        systemctl start mysqld
        systemctl enable mysqld
        format
        echo "mysql 状态如下："
        systemctl status mysqld
        mysql_status=`systemctl status mysqld | grep Active | awk '{print $3}'|awk -F '(' '{print $2}'| awk -F ')' '{print $1}'`
        if  [[ "$mysql_status" == "running" ]];then
            echo "mysql 8.0已安装完成并启动"
        else
            echo "mysql 启动异常，请检查。"
            exit 21
        fi
        format
        read -p "是否继续设置 root 密码及权限(y/n): " set_mysql_root_pass_or
        if [[ "$set_mysql_root_pass_or" == "y" ]];then
            passlog=$(grep 'temporary password' /var/log/mysqld.log |tail -n 1 )
            pass=${passlog:${#passlog}-12:${#passlog}}
            mysql -uroot -p"${pass}" -e "set global validate_password.policy=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password.length=4;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password.mixed_case_count=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password.number_count=0;" --connect-expired-password
            read -p "请输入 mysql root 密码：[" mysql_root_pass
            mysql -uroot -p"${mysql_root_pass}" -e "update mysql.user set host='%' where user='root';" --connect-expired-password
            mysql -uroot -p"${mysql_root_pass}" -e "flush privileges;" --connect-expired-password
            echo "mysql root 密码设置及授权完成,root 用户授权规则如下："
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'%';"
        fi
    fi
}

format
sleep 3


# main 函数
function main(){
#    add_hosts
#    update_yum_repo
#    install_basic_package
#    set_machine_hostname
#    add_user
    #update_kernel
#    update_ntpdate
    #add_public_dns
#    disable_firewalld
#    set_history
    disable_system_service
    set_sshd_config
    disable_ipv6
    set_system_limits
    update_kernel_parameter
#    install_openjdk
    install_oraclejdk
    #install_maven
    #install_php
    #install_nodejs
    #install_mysql

    set_lock_keyfile

}

echo "111111"

# exec scripts
echo "本脚本执行两种执行方式：\n
1、(默认执行方式)将需要执行的函数写入 main 函数内，然后执行此脚本，不要加任何参数！\n
2、执行本脚本加上需要执行的函数作为参数。"
format
sleep 5

if [[ -z $* ]]; then
    echo  "开始执行 main 函数进行系统初始化....."
    main
    format
    echo "脚本执行完成，请重启"
fi

if [[ $# -ge 1 ]]; then
    for arg in $* ; do
        case ${arg} in
        add_hosts)
        add_hosts;;

        update_yum_repo)
        update_yum_repo;;

        install_basic_package)
        install_basic_package;;

        set_machine_hostname)
        set_machine_hostname;;

        add_user)
        add_user;;

        update_kernel)
        update_kernel;;

        update_ntpdate)
        update_ntpdate;;

        add_public_dns)
        add_public_dns;;

        disable_firewalld)
        disable_firewalld;;

        set_history)
        set_history;;

        set_lock_keyfile)
        set_lock_keyfile;;

        disable_system_service)
        disable_system_service;;

        set_sshd_config)
        set_sshd_config;;

        disable_ipv6)
        disable_ipv6;;

        set_system_limits)
        set_system_limits;;

        update_kernel_parameter)
        update_kernel_parameter;;

        install_openjdk)
        install_openjdk;;

        install_oraclejdk)
        install_oraclejdk;;

        install_maven)
        install_maven;;

        install_php)
        install_php;;

        install_nodejs)
        install_nodejs;;

        install_mysql)
        install_mysql;;
        esac
    done
fi













