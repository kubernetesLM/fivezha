# 添加admin、super、tomcat群组sudo权限
/etc/sudoers:
  file.managed:
    - source: salt://init/config/sudoers
