# 关闭selinux
/etc/sysconfig/selinux:
  file.managed:
    - source: salt://config/selinux
