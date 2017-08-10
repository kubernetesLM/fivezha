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
    - source: salt://init/config/rsyslog-c6.conf
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
