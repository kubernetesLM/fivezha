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
      - traceroute

# 关闭不常用的服务
service-disable:
  service.disabled:
    - name: postfix
