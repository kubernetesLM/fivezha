# 添加命令审计
/etc/profile.d/cmd_log.sh:
  file.managed:
    - source: salt://init/config/cmd_log.sh
    - require:
      - file: /etc/profile

# 修改rsyslog
/etc/rsyslog.conf1:
  file.replace:
    - name: /etc/rsyslog.conf
    - pattern: '\*.info;mail.none;authpriv.none;cron.none                /var/log/messages'
    - repl: '*.info;mail.none;authpriv.none;cron.none;local1.none    /var/log/messages'
    - require:
      - file: /etc/profile.d/cmd_log.sh

/etc/rsyslog.conf2:
  # 收集客户端命令审计到远程rsyslog服务
  file.append:
    - name: /etc/rsyslog.conf
    - text: |
        local1.notice                                           /var/log/cmd.log
        local1.notice                                           @@{{ pillar['rsyslog']['ip'] }}:{{ pillar['rsyslog']['port'] }}
    - unless: grep "/var/log/cmd.log" /etc/rsyslog.conf
    - require:
      - file: /etc/profile.d/cmd_log.sh
  service.running:
    - name: rsyslog
    - watch:
      - file: /etc/rsyslog.conf2
    - require:
      - cmd: /etc/hosts

# cmd.log日志轮询
/etc/logrotate.d/cmd_log:
  file.managed:
    - source: salt://init/config/cmd_log
    - require:
      - file: /etc/rsyslog.conf
