#salt-ssh -i \* state.sls init.minion推送客户端安装minion
#cat /etc/salt/roster
#HOST102:
#  host: 192.168.137.102
#  user: root
#  passwd: box139

#HOST103:
#  host: 192.168.137.103
#  user: root
#  passwd: box139
epel-release:
  pkg.installed:
    - name: epel-release

salt-minion:
  pkg.installed:
    - require:
      - pkg: epel-release
  service.running:
    - enable: True
    - require:
      - pkg: salt-minion
    - watch:
      - file: /etc/salt/minion
  file.managed:
    - name: /etc/salt/minion
    - source: salt://init/config/minion
    - template: jinja
    - defaults:
      minion_id: {{ grains['id'] }}
    - require:
      - pkg: salt-minion
