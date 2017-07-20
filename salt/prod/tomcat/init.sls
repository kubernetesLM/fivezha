{% set version = '7.0.50' %}
tomcat-install:
  file.managed:
    - name: /usr/local/src/apache-tomcat-{{ version }}.tar.gz
    - source: salt://soft/apache-tomcat-{{ version }}.tar.gz
  cmd.run:
    - name: |
        cd /usr/local/src
        tar -zxf apache-tomcat-{{ version }}.tar.gz
        mv apache-tomcat-{{ version }} /data/web/tomcat
        rm /data/web/tomcat/webapps/* -rf
    - unless: test -d /data/web/tomcat

tomcat-conf1:
  file.managed:
    - name: /data/web/tomcat/conf/server.xml
    - source: salt://tomcat/config/server.xml
    - require:
      - cmd: tomcat-install

tomcat-conf2:
  file.managed:
    - name: /data/web/tomcat/conf/logging.properties
    - source: salt://tomcat/config/logging.properties
    - require:
      - cmd: tomcat-install

tomcat-catalina.sh:
  file.managed:
    - name: /data/web/tomcat/bin/catalina.sh
    - source: salt://tomcat/config/catalina.sh
    - require:
      - cmd: tomcat-install
