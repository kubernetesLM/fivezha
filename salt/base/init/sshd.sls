# 关闭密码登录
/etc/ssh/sshd_config:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - source: salt://init/config/sshd_config-c6
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - source: salt://init/config/sshd_config-c7
    {% endif %}
    - require:
      - ssh_auth: ssh_key_hujf
  service.running:
    - name: sshd
    - reload: true
    - watch:
      - file: /etc/ssh/sshd_config
