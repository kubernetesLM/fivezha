{% set version = '8u112'  %}
{% set version2 = '1.8.0_112'  %}
jdk-install:
  file.managed:
    - name: /usr/local/src/jdk-{{ version }}-linux-x64.tar.gz
    - source: salt://soft/jdk-{{ version }}-linux-x64.tar.gz
  cmd.run:
    - name: |
        cd /usr/local/src
        tar -zxf jdk-{{ version }}-linux-x64.tar.gz
        mv jdk{{ version2 }} /usr/local
    - unless: test -d /usr/local/jdk{{ version2 }}

jdk-profile:
  file.managed:
    - name: /etc/profile.d/jdk.sh
    - source: salt://jdk/config/jdk-{{ version2 }}.sh
    - require:
      - cmd: jdk-install
