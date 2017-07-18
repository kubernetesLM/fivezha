jdk-install:
  file.managed:
    - name: /usr/local/src/jdk-7u80-linux-x64.tar.gz
    - source: salt://soft/jdk-7u80-linux-x64.tar.gz
  cmd.run:
    - name: |
        cd /usr/local/src
        tar -zxf jdk-7u80-linux-x64.tar.gz
        mv jdk1.7.0_80 /usr/local
    - unless: test -d /usr/local/jdk1.7.0_80

jdk-profile:
  file.managed:
    - name: /etc/profile.d/jdk.sh
    - source: salt://jdk/config/jdk.sh
    - require:
      - cmd: jdk-install