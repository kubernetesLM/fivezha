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
{{ grains['id'] }}:
  host.present:
    - ip: {{ grains['ipv4'][1] }}
  cmd.run:
    - name: sed -i "s/^HOSTNAME=.*/HOSTNAME={{ grains['id'] }}/" /etc/sysconfig/network
    - unless: grep "HOSTNAME={{ grains['id'] }}" /etc/sysconfig/network

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

# 修改nproc
/etc/security/limits.d/90-nproc.conf:
  file.managed:
    - source: salt://init/config/90-nproc.conf

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
