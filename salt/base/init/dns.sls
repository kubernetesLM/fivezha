# 修改dns
# 阿里云ecs不添加
/etc/resolv.conf:
  file.managed:
    - source: salt://init/config/resolv.conf
