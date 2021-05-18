#!/bin/bash
#################################################
#  CentOS 7.x system configure initial scripts
#################################################
#  $Version:    v2.0
#  $Author:     FLS
#  $Create_data:    20190702
#  $Description: CentOS 7.x system configure initial scripts
#################################################

# check user is root
if [ $(id -u) != "0" ]; then
    echo "Error: 你不是管理员账户身份，此脚本需要管理员身份运行，exit......"
    exit 1
fi

# check network
if ping -c2 baidu.com &>/dev/null ;then
    echo
else
    echo "当前机器网络不通，本脚本需要联网执行。"
    exit 2
fi

# check network_interface is eth0
if ifconfig | grep eth0  2>&1 > /dev/null ;then
    echo
else
    echo "当前机器没有 eth0 网卡，请检查."
    exit 3
fi


# PSF
IPS=''
CURRENT_PWD=$(pwd)
NET_IP=$(ifconfig eth0  |  grep  -w "inet" | awk '{print $2}')







# set format
format() {
#    echo -e "\033[32m Success!!!\033[0m\n"
    echo "#########################################################"
}


# install epel repo and updte yum repo.
update_yum_repo(){
    echo "开始更新系统 yum 仓库......"
    yum install epel-release -y
    yum install https://centos7.iuscommunity.org/ius-release.rpm  -y
    yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    yum clean all
    yum makecache
    yum  update --skip-broken  -y
    format
    sleep 3
}



# install basic package.
install_basic_package(){
    echo "开始更新软件包......"
    sleep 3
    yum install -y  \
wget \
openssl-devel  \
cpp \
binutils  \
gcc  \
make \
gcc-c++  \
glibc  \
glibc-kernheaders  \
glibc-common  \
glibc-devel  \
libstdc++-devel \
tcl \
ntpdate \
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
pcre  \
pcre-devel  \
ntpdate  \
lynx  \
tmux  \
mc  \
nload  \
atop  \
expect  \
dos2unix  \
unzip \
vim  \
jq   \
cronolog  \
zlib*  \
openssl*


    format
    sleep 3

}

# add hosts
add_hosts(){
cat << EOF >> /etc/hosts
EOF
}

format

set_machine_hostname(){
while :
    do
    clear
    echo "请输入你想设置的hostname："
    echo "输入确认： y"
    echo "重新输入： n"
    echo "退出脚本： q"
    read -p "Please input the machine hostname:[ " nodename
    read -p "You input hostname is : [ $nodename ]，are you sure (y/n/q): [ " choice
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
    if [ -n $NET_IP ];then
        echo "本机 eth0 网卡 ip 为： $NET_IP "
        echo "$NET_IP $nodename"
        echo "$NET_IP $nodename" >> /etc/hosts
        echo "添加主机名的解析记录OK"
    else
        echo "没有获取到有效的ip 地址，是确认网卡名称是否是 eth0"
        exit 1
    fi

    format
    sleep 3
}

# add user and set user authorization.
add_user(){
while :
do
    format
    echo "开始添加用户及设置用户密码:"
    echo "1、选择是否设置 root 密码."
    echo "2、选择添加用户、设置密码及创建 ssh-key."
    echo "3、选择是否为用户设置 sudoers 权限."

    read -p "是否要修改 root 密码(y/n): [ "  change_root_pass_or
    if [[ $change_root_pass_or == "y" ]];then
        read -p "请输入 root 的密码：[ "  root_pass
        echo "你要设置的 root 密码为：[ $root_pass"
        sleep 3
        echo "$root_pass" |  passwd  root  --stdin  &> /dev/null
    else
        echo "你已选择不设置 root 密码."
    fi
    echo
    while :
    do
        read -p "请输入要添加的用户名:[ "  add_user_name
        read -p "请输入要添加用户的密码:[ "  add_user_pass
        echo "将要创建的用户及密码为： $add_user_name   $add_user_pass"
        sleep 3
        useradd $add_user_name
        echo "$add_user_pass" |  passwd  $add_user_name --stdin  &> /dev/null
        echo "为用户生成 ssh-key"
        su -c 'ssh-keygen -t rsa  -P ""  -f ~/.ssh/id_rsa'  $add_user_name
        echo
        read -p "是否为用户设置 sudoers权限 (y/n):[ " set_sudoers_or
        if [[ $set_sudoers_or == "y" ]];then
            read -p "请输入 sudoers规则（root权限规则为: [ $add_user_name  ALL=(ALL)  NOPASSWD:ALL ]:  [ "  set_sudoers_content
            echo "$set_sudoers_content" > /etc/sudoers.d/$add_user_name
            echo "用户$add_user_name  sudoers 规则添加成功，规则如下："
            cat /etc/sudoers.d/$add_user_name
        else
            echo "您输入有误，此步骤跳过。"

        fi
        echo "添加用户 $add_user_name 成功。"
        echo

        read -p  "是否继续添加用户(y/n):[  " add_user_contine
        if [[ $add_user_contine == 'y' ]];then
            continue
         else
            echo "添加用户结束."
            break
        fi
    done
    break
done

    format
    sleep 3
}



# update kernel to ml
update_kernel(){
    echo "更新内核版本："
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install -y kernel-ml
    grub2-set-default 0
    grub2-mkconfig -o /boot/grub2/grub.cfg

    format
    sleep 3
}



#  NTP update
update_ntpdate(){
    echo "开始进行 ntpdate 时钟同步...."
    echo "0 0 * * * /usr/sbin/ntpdate ntp1.aliyun.com  &>/dev/null" >> /etc/crontab
    hwclock -w

    format
    sleep 3
}


# add public dns
add_public_dns(){
    echo "开始为系统增加公共 DNS"
    echo > /etc/resolv.conf
    echo  "nameserver  114.114.114.114" >> /etc/resolv.conf
    echo  "nameserver  223.5.5.5" >> /etc/resolv.conf
    echo  "nameserver  8.8.8.8" >> /etc/resolv.conf

    format
    sleep 3
}


# disable selinux add iptables 
disable_firewalld(){
    echo "开始关闭系统防火墙......"
    [ `getenforce` != "Disabled" ] && setenforce 0 &> /dev/null && sed -i s/"^SELINUX=.*$"/"SELINUX=disabled"/g /etc/sysconfig/selinux
    systemctl stop firewalld  &> /dev/null
    systemctl disable firewalld &> /dev/null
    systemctl stop  iptables  &> /dev/null
    systemctl disable iptables  &> /dev/null

    format
    sleep 3
}


# set history format
set_history(){
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

    format
    sleep 3
}


# lock keyfile.  NOTICE：设置完 keyfile 后不能再对这些文件进行修改，会影响添加用户及修改密码功能。
set_lock_keyfile(){
    chattr +ai /etc/passwd
    chattr +ai /etc/shadow
    chattr +ai /etc/group
    chattr +ai /etc/gshadow
}


# stop system services:
disable_system_service(){
    echo "开始关闭系统服务......"
    systemctl stop NetworkManager
    systemctl disable NetworkManager

    format
    sleep 3
}


# set ssh config
set_sshd_config(){
    sed -i 's/\#Port 22/Port 10222/' /etc/ssh/sshd_config
    sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    systemctl  restart  sshd
    echo "修改 ssh 配置完成"

    format
    sleep 3
}


# disable ipv6
disable_ipv6(){
    cat > /etc/modprobe.d/ipv6.conf << EOF
alias net-pf-10 off
options ipv6 disable=1
EOF
    echo "NETWORKING_IPV6=off" >> /etc/sysconfig/network
    echo "禁用 ipv6 配置完成"

    format
    sleep 3
}



# set system limits
set_system_limits(){
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
    format
    sleep 3
}


#  kernel optimizer
update_kernel_parameter(){
    cat > /etc/sysctl.conf  << EOF

# this  configuration is add by centos7_init_scripts.
net.ipv4.ip_forward = 1
vm.swappiness = 0
vm.max_map_count= 262144
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

    format
    sleep 3
}


# install java 1.80
install_openjdk(){
    yum remove -y java  &> /dev/null
    yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel  -y
    echo "open jdk 安装完成·"

    format
    sleep 3

}


#  install  oraclejdk 8u202
install_oraclejdk(){
    yum remove -y java  &> /dev/null
    wget https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
    tar zxf  jdk-8u202-linux-x64.tar.gz -C /opt
    sleep 2
    cd /opt
    ln -s jdk1.8.0_202  jdk
    cat /dev/null  > /etc/profile.d/jdk.sh
    echo '#jdk plugin profile'  >> /etc/profile.d/jdk.sh
    echo 'export JAVA_HOME=/opt/jdk'  >> /etc/profile.d/jdk.sh
    echo 'export JRE_HOME=/opt/jdk/jre'  >> /etc/profile.d/jdk.sh
    echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib'  >> /etc/profile.d/jdk.sh
    echo 'export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH'  >> /etc/profile.d/jdk.sh
    source /etc/profile.d/jdk.sh
    ln -s  /opt/jdk/bin/java   /usr/bin/java
    which java
    java -version
    cd ${CURRENT_PWD}
    echo "oraclejdk 安装完成·"

    format
    sleep 3

}


# install maven
install_maven(){
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
    format
    sleep 3
}



# install php
install_php(){
    yum install php72u* nginx httpd -y
    systemctl start php-fpm.service
    systemctl enable php-fpm.service
}



install_nodejs(){
    yum install https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_12.x/el/7/x86_64/nodesource-release-el7-1.noarch.rpm -y
    cat > /etc/yum.repos.d/nodesource-el7.repo <<EOF
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

    format
    sleep 3

}


# install mysql 55/56/57/80
install_mysql(){
    echo "开始安装mysql，下载官方仓库中......"
    yum install  https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm  -y
    format
    echo "下载成功，已添加的 mysql存储库："
    yum repolist enabled | grep "mysql.*-community.*"
    format
    echo "当前mysql 存储库中所有mysql版本如下："
    yum repolist all | grep mysql
    format
    read -p "请输入你想安装的mysql版本：[55/56/57/80]，选择版本后其他版本会禁用：[ "  mysql_version
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
        read -p "是否继续设置 root 密码及权限(y/n): [ " set_mysql_root_pass_or
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
            read -p "要设置grant rule: [ " mysql_grant_rule
            read -p "请输入当前mysql root的密码: [ "  mysql_root_pass
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
        read -p "是否继续设置 root 密码及权限(y/n): [ " set_mysql_root_pass_or
        if [[ "$set_mysql_root_pass_or" == "y" ]];then
            passlog=$(grep 'temporary password' /var/log/mysqld.log)
            pass=${passlog:${#passlog}-12:${#passlog}}
            mysql -uroot -p"${pass}" -e "set global validate_password_policy=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password_length=4;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password_mixed_case_count=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password_number_count=0;" --connect-expired-password
            read -p "请输入 mysql root 密码：" mysql_root_pass
            mysql -uroot -p"${pass}" -e "alter user 'root'@'localhost' identified by '${mysql_root_pass}' PASSWORD EXPIRE NEVER account unlock;" --connect-expired-password
            mysql -uroot -p"${mysql_root_pass}" -e "update mysql.user set host='%' where user='root';" --connect-expired-password
            mysql -uroot -p"${mysql_root_pass}" -e "flush privileges;" --connect-expired-password
            echo "mysql root 密码设置及授权完成,root 用户授权规则如下："
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'localhost';"
            format
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'%';"
            format
            
            # 创建用户及授权命令：
            # CREATE USER '用户名'@'登录地址（%百分号代表所有）' IDENTIFIED BY '密码'
            # GRANT SELECT, INSERT ON 数据库名.* TO '用户名'@'%';
          
            
            
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
        read -p "是否继续设置 root 密码及权限(y/n): [ " set_mysql_root_pass_or
        if [[ "$set_mysql_root_pass_or" == "y" ]];then
            passlog=$(grep 'temporary password' /var/log/mysqld.log |tail -n 1 )
            pass=${passlog:${#passlog}-12:${#passlog}}
            mysql -uroot -p"${pass}" -e "set global validate_password.policy=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password.length=4;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password.mixed_case_count=0;" --connect-expired-password
            mysql -uroot -p"${pass}" -e "set global validate_password.number_count=0;" --connect-expired-password
            read -p "请输入 mysql root 密码: [ " mysql_root_pass
            mysql -uroot -p"${mysql_root_pass}" -e "update mysql.user set host='%' where user='root';" --connect-expired-password
            mysql -uroot -p"${mysql_root_pass}" -e "flush privileges;" --connect-expired-password
            echo "mysql root 密码设置及授权完成,root 用户授权规则如下："
            mysql -uroot -p"${mysql_root_pass}" -e "show grants for 'root'@'%';"
        fi
    fi
    sleep 3
    echo  "开始测试 mysql root 登陆"
    mysql -uroot -p
    format
    sleep 3
}


# install redis and  configure
install_redis(){
    format
    echo -e "开始安装 redis，目前仅支持安装各主版本的最新次版本，对应如下:
3  --> 3.2.9
4  --> 4.0.9
5  --> 5.0.9
6  --> 6.0.9
62 --> 6.2.1

务必阅读以下安装说明！！！:
> 本安装脚本为源码编译安装，执行前请先执行 install_basic_package，安装软件包。
> 编译目录默认在/usr/local/redis目录下，可以在脚本中修改，最后安装命令在在/usr/local/bin 目录下
> redis 默认是用 root 用户启动
> 配置文件放在/etc/redis/redis.conf，备份配置文件为redis.conf.bak
> 日志文件会放在 /var/log/redis.log，需要提前创建
> 默认开启AOF，aof 和 dump文件默认会放在 /var/lib/redisdata目录下，请在脚本中修改说那个 dir
> 当 redis 开启的密码后，关闭 redis 使用 -a 进行输入密码，修改密码后需要更新 service 文件。
"

    REDIS_CONF_DIR="/etc/redis"
    REDIS_DATA_DIR="/var/lib/redisdata"


    which redis-cli 2>&1 > /dev/null
    if [[ $? -eq 0 ]];then
        "redis 已存在，请确认，脚本先退出。"
        exit  30
    fi
    read -p "请输入你想安装的 redis 主版本[3/4/5/6/62]: [ " redis_version
    read -p "请输入你想设置的 redis 密码: [ " redis_pass

    case ${redis_version} in
        3)
        redis_version_full="3.2.9"
       ;;
        4)
        redis_version_full="4.0.9"
        ;;
        5)
        redis_version_full="5.0.9"
        ;;
        6)
        redis_version_full="6.0.9"
        ;;
        62)
        redis_version_full="6.2.1"
        ;;
    esac

    echo "你想安装 redis 版本为 $redis_version_full  设置的密码为： $redis_pass 开始安装......"
    sleep 3
    wget  https://download.redis.io/releases/redis-$redis_version_full.tar.gz
    tar zxf redis-$redis_version_full.tar.gz  -C /usr/local/
    cd /usr/local/redis-$redis_version_full
    cd deps
    make jemalloc
    make hiredis
    make linenoise
    make lua
    sleep 5
    cd ../
    format
    make
    format
    sleep 5
    make test
    format
    sleep 5
    if [[ $? == 0 ]];then
       make install
       format
       sleep 5
#       make install PREFIX=/usr/local
       if [[ $? == 0 ]];then
            redis-cli  --version
            if [[ $? == 0 ]];then
                echo "redis-$redis_version_full 安装成功"
                sleep 5
            fi
       fi
    fi

    echo "开始修改redis.conf 配置文件...."
    format
    sleep 5
    echo "65535"  > /proc/sys/net/core/somaxconn
    if [ ! -d "${REDIS_CONF_DIR}" ];then
        mkdir ${REDIS_CONF_DIR}
    fi
    if [ ! -d "${REDIS_DATA_DIR}" ];then
        mkdir ${REDIS_DATA_DIR}
    fi
    echo "65535"  >  /proc/sys/net/core/somaxconn
    echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
    echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"   >> /etc/rc.local

    mv redis.conf redis.conf.bak
    echo "bind 0.0.0.0" >> redis.conf
    echo "port 6379" >> redis.conf
    echo "tcp-backlog 65535" >> redis.conf
    echo "tcp-keepalive 300" >> redis.conf
    echo "daemonize yes" >> redis.conf
    echo "pidfile /var/run/redis_6379.pid" >> redis.conf
    echo "loglevel notice" >> redis.conf
    echo 'logfile "/var/log/redis.log"' >> redis.conf
    echo "databases 16" >> redis.conf
    echo "always-show-logo yes" >> redis.conf
    echo "save 900 1" >> redis.conf
    echo "save 300 10" >> redis.conf
    echo "save 60 10000" >> redis.conf
    echo "stop-writes-on-bgsave-error yes" >> redis.conf
    echo "rdbcompression yes" >> redis.conf
    echo "rdbchecksum yes" >> redis.conf
    echo "dbfilename dump.rdb" >> redis.conf
    echo "dir /var/lib/redisdata" >> redis.conf
    echo "appendonly yes" >> redis.conf
    echo 'appendfilename "appendonly.aof"' >> redis.conf
    echo "appendfsync everysec" >> redis.conf
    echo "no-appendfsync-on-rewrite no" >> redis.conf
    echo "auto-aof-rewrite-percentage 100b" >> redis.conf
    echo "auto-aof-rewrite-min-size 64mb" >> redis.conf
    echo "aof-load-truncated yes" >> redis.conf
    echo "aof-use-rdb-preamble yes" >> redis.conf
    echo "slowlog-log-slower-than 10000" >> redis.conf
    echo "slowlog-max-len 128" >> redis.conf
    echo "latency-monitor-threshold 0" >> redis.conf
    echo "requirepass $redis_pass" >> redis.conf
    echo "protected-mode no" >> redis.conf

    cp redis.conf  redis.conf.bak  /etc/redis/

    cat > /usr/lib/systemd/system/redis.service <<-EOF
[Unit]
Description=Redis persistent key-value database
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=root
Group=root
PrivateTmp=yes
Restart=on-failure
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli -h 127.0.0.1 -p 6379 -a $redis_pass shutdown


[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl start redis
    echo "redis已安装完成并启动......"
    format

}


install_zookeeper(){
    format
    echo "安装请 zookeeper 约则：
> 请先确认系统是否有java 环境.
> 请务必现在配置中完善 server 信息，并严格按照顺序进行安装执行顺序。
> 启动是以zookeeper 用户来启动的.
"

    # 检测 java 环境是否存在
    which java 2>&1  > /dev/null
    if [[ $? -ne 0 ]];then
        echo "目前系统没有java 环境，请先安装 java 环境"
        exit  31
    fi

    useradd zookeeper
    # 检测目录是否存在
    ZOOK_INSTALL_DIR="/usr/local"
    ZOOK_DATA_DIR='/var/lib/zookeeper_data'

    for dir in {$ZOOK_DATA_DIR}
        do
            if [ ! -d "${dir}" ];then
                mkdir -p  ${dir}
                chown -R  zookeeper:zookeeper  ${dir}

            fi
        done

    format
    echo "此机器的 ip 地址是: $NET_IP"
    ehco "server_id 对应的 ip 为：
server.1=172.16.1.146:2888:3888:participant;172.16.1.146:2181
server.2=172.16.1.147:2888:3888:participant;172.16.1.147:2181
server.3=172.16.1.145:2888:3888:participant;172.16.1.145:2181
server.4=172.16.1.142:2888:3888:participant;172.16.1.142:2181
server.5=172.16.1.143:2888:3888:participant;172.16.1.136:2181
"
    format
    read -p  "请输入此台机器在 zook 集群的编号，请严格按照 server.id 的顺序进行设置 [ " zook_id
    echo $zook_id | grep -q '[^0-9]'
    n1=$?
    if [ $n1 -eq 0 ]
    then
            echo "你输入id 编号不是数字，请执行程序重新输入。"
            exit 32
    fi

    wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/stable/apache-zookeeper-3.6.3-bin.tar.gz
    tar zxf apache-zookeeper-3.6.3-bin.tar.gz -C  $ZOOK_INSTALL_DIR
    ln -s $ZOOK_INSTALL_DIR/apache-zookeeper-3.6.3-bin   $ZOOK_INSTALL_DIR/zookeeper
    chown -R  zookeeper:zookeeper  $ZOOK_INSTALL_DIR/apache-zookeeper-3.6.3-bin
    chown -R  zookeeper:zookeeper $ZOOK_INSTALL_DIR/zookeeper

    cat > $ZOOK_INSTALL_DIR/zookeeper/conf/zoo.cfg <<-EOF
tickTime=2000
initLimit=10
syncLimit=5
maxClientCnxns=200
dataDir=$ZOOK_DATA_DIR
autopurge.snapRetainCount=5
autopurge.purgeInterval=1
4lw.commands.whitelist=*
clientPort=2181
server.1=172.16.1.146:2888:3888:participant;172.16.1.146:2181
server.2=172.16.1.147:2888:3888:participant;172.16.1.147:2181
server.3=172.16.1.145:2888:3888:participant;172.16.1.145:2181
server.4=172.16.1.142:2888:3888:participant;172.16.1.142:2181
server.5=172.16.1.143:2888:3888:participant;172.16.1.136:2181
EOF

    echo "#zookeeper plugin profile"   >> /etc/profile.d/zookeeper.sh
    echo "export ZOOKEEPER_HOME=$ZOOK_INSTALL_DIR/zookeeper" >> /etc/profile.d/zookeeper.sh
    echo "export PATH=$PATH:$ZOOKEEPER_HOME/bin"  >> /etc/profile.d/zookeeper.sh
    source  /etc/profile.d/zookeeper.sh


    cat > /usr/lib/systemd/system/zookeeper.service <<-EOF
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=forking
User=zookeeper
Group=zookeeper
PIDFile=$ZOOK_DATA_DIR/zookeeper_server.pid
ExecStart=$ZOOK_INSTALL_DIR/zookeeper/bin/zkServer.sh start
ExecStop=$ZOOK_INSTALL_DIR/zookeeper/bin/zkServer.sh stop
ExecReload=$ZOOK_INSTALL_DIR/zookeeper/bin/zkServer.sh restart
SyslogIdentifier=zookeeper
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    format
    echo "$zook_id" > $ZOOK_DATA_DIR/myid
    chown -R  zookeeper:zookeeper  $ZOOK_DATA_DIR/myid
    echo "id 文件内容如下："
    cat  $ZOOK_DATA_DIR/myid
    format
    echo "zookeeper 配置文件如下："
    cat $ZOOK_INSTALL_DIR/zookeeper/conf/zoo.cfg
    format
    echo "zookeeper.service文件如下："
    cat /usr/lib/systemd/system/zookeeper.service
    format
    echo "zookeeper profile文件如下："
    cat /etc/profile.d/zookeeper.sh
    format

    systemctl daemon-reload
    systemctl start zookeeper
    systemctl status zookeeper
    echo "zookeeper已安装完成......"
    format

}



# main 函数
main(){
    add_hosts
    update_yum_repo
    install_basic_package
    set_machine_hostname
    add_user
    #update_kernel
    update_ntpdate
    #add_public_dns
    disable_firewalld
    set_history
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
    #instal_redis
    #install_zookeeper
#    set_lock_keyfile

}


# exec scripts
echo "本脚本执行两种执行方式
1、(默认执行方式)将需要执行的函数写入 main 函数内，然后执行此脚本，不要加任何参数！
2、执行本脚本加上需要执行的函数作为参数。"
format
sleep 3

if [[ -z $* ]]; then
    echo  "开始执行 main 函数进行系统初始化....."
    format
    sleep 5
    main
    format
    echo "脚本执行完成，请重启机器"
fi

if [[ $# -ge 1 ]]; then
    for arg in $* ; do
        case ${arg} in
        add_hosts)
        add_hosts
        ;;
        update_yum_repo)
        update_yum_repo
        ;;
        install_basic_package)
        install_basic_package
        ;;
        set_machine_hostname)
        set_machine_hostname
        ;;
        add_user)
        add_user
        ;;
        update_kernel)
        update_kernel
        ;;
        update_ntpdate)
        update_ntpdate
        ;;
        add_public_dns)
        add_public_dns
        ;;
        disable_firewalld)
        disable_firewalld
        ;;
        set_history)
        set_history
        ;;
        set_lock_keyfile)
        set_lock_keyfile
        ;;
        disable_system_service)
        disable_system_service
        ;;
        set_sshd_config)
        set_sshd_config
        ;;
        disable_ipv6)
        disable_ipv6
        ;;
        set_system_limits)
        set_system_limits
        ;;
        update_kernel_parameter)
        update_kernel_parameter
        ;;
        install_openjdk)
        install_openjdk
        ;;
        install_oraclejdk)
        install_oraclejdk
        ;;
        install_maven)
        install_maven
        ;;
        install_php)
        install_php
        ;;
        install_nodejs)
        install_nodejs
        ;;
        install_mysql)
        install_mysql
        ;;
        install_redis)
        install_redis
        ;;
        install_zookeeper)
        install_zookeeper
        ;;

        esac
    done
fi

