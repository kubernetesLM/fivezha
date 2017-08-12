# 添加history时间格式
/etc/profile:
  file.append:
    - text: HISTTIMEFORMAT="%F %T "
    - unless: grep "HISTTIMEFORMAT" /etc/profile
