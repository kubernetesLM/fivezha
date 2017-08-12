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
    - source: salt://config/minion
    - template: jinja
    - defaults:
      master_ip: {{ pillar['salt-master']['ip'] }}
      minion_id: {{ grains['id'] }}
    - require:
      - pkg: salt-minion
