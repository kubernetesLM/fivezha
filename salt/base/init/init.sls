# yum安装常用软件
yum-list:
  pkg.installed:
    - pkgs: 
      - wget
      - lrzsz
      - vim-enhanced
      - dos2unix
      - unzip
      - telnet
      - ntpdate
      - rsync
      - bind-utils
      - tcpdump
      - lsof
      - epel-release

# 关闭不常用的服务
service-disable:
  service.disabled:
    - name: postfix

# 修改hostname
hostname:
  cmd.run:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - name: |
        sed -i "s/^HOSTNAME=.*/HOSTNAME={{ grains['id'] }}/" /etc/sysconfig/network
        hostname {{ grains['id'] }}
    - unless: grep "^HOSTNAME={{ grains['id'] }}$" /etc/sysconfig/network
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - name: hostnamectl set-hostname {{ grains['id'] }}
    - unless: hostname | grep "^{{ grains['id'] }}$"
    {% endif %}

# 修改hosts
hosts:
   cmd.run:
      - name: sed -i "s/^127.0.0.1.*/127.0.0.1 {{ grains['id'] }} localhost/" /etc/hosts
      - unless: grep "^127.0.0.1 {{ grains['id'] }} localhost$" /etc/hosts

# 修改dns
# 阿里云ecs不修改
#/etc/resolv.conf:
#  file.managed:
#    - source: salt://init/config/resolv.conf

# 添加crontab
# 阿里云ecs不添加
#set-crontab:
#  cron.present:
#    - name: ntpdate cn.pool.ntp.org &> /dev/null
#    - user: root
#    - minute: 10
#    - hour: 0
#    - require:
#      - pkg: yum-list
    
# 添加history时间格式
/etc/profile:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - source: salt://init/config/profile
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - source: salt://init/config/profile-c7
    {% endif %}

# 添加命令审计
/etc/profile.d/cmd_log.sh:
  file.managed:
    - source: salt://init/config/cmd_log.sh
    - require:
      - file: /etc/profile

# 修改rsyslog
/etc/rsyslog.conf:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - source: salt://init/config/rsyslog.conf
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - source: salt://init/config/rsyslog-c7.conf
    {% endif %}
    - require:
      - file: /etc/profile.d/cmd_log.sh
  service.running:
    - name: rsyslog
    - watch:
      - file: /etc/rsyslog.conf

# cmd.log日志轮询
/etc/logrotate.d/cmd_log:
  file.managed:
    - source: salt://init/config/cmd_log
    - require:
      - file: /etc/rsyslog.conf

# 修改nproc
limits.d:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - name: /etc/security/limits.d/90-nproc.conf
    - source: salt://init/config/90-nproc.conf
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - name: /etc/security/limits.d/20-nproc.conf
    - source: salt://init/config/20-nproc.conf
    {% endif %}

# 关闭selinux
/etc/sysconfig/selinux:
  file.managed:
    - source: salt://init/config/selinux

# 添加root密钥
ssh_key_root:
  ssh_auth.present:
    - user: root
    - source: salt://init/config/root.pub

# 关闭密码登录
/etc/ssh/sshd_config:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - source: salt://init/config/sshd_config
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - source: salt://init/config/sshd_config-c7
    {% endif %}
    - require:
      - ssh_auth: ssh_key_root
  service.running:
    - name: sshd
    - reload: true
    - watch:
      - file: /etc/ssh/sshd_config