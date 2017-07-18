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
  host.present:
    - ip: {{ grains['fqdn_ip4'][0] }}
    - name: {{ grains['id'] }}

  cmd.run:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - name: sed -i "s/^HOSTNAME=.*/HOSTNAME={{ grains['id'] }}/" /etc/sysconfig/network
    - unless: grep "^HOSTNAME={{ grains['id'] }}$" /etc/sysconfig/network
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - name: hostnamectl set-hostname {{ grains['id'] }}
    - unless: hostname | grep "^{{ grains['id'] }}$"
    {% endif %}

# 修改dns
/etc/resolv.conf:
  file.managed:
    - source: salt://init/config/resolv.conf

# 添加crontab
set-crontab:
  cron.present:
    - name: ntpdate cn.pool.ntp.org &> /dev/null
    - user: root
    - minute: 10
    - hour: 0
    - require:
      - pkg: yum-list
    
# 添加history时间格式
/etc/profile:
  file.managed:
    - source: salt://init/config/profile

# 添加命令审计
/etc/profile.d/cmd_log.sh:
  file.managed:
    - source: salt://init/config/cmd_log.sh
    - require:
      - file: /etc/profile

# 修改rsyslog
/etc/rsyslog.conf:
  file.managed:
    - source: salt://init/config/rsyslog.conf
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
    - source: salt://init/config/sshd_config
    - require:
      - ssh_auth: ssh_key_root
  service.running:
    - name: sshd
    - reload: true
    - watch:
      - file: /etc/ssh/sshd_config
