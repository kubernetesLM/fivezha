{% set version = '2.8.19' %}
redis-install:
  pkg.installed:
    - pkgs:
      - gcc
  file.managed:
    - name: /usr/local/src/redis-{{ version }}.tar.gz
    - source: salt://soft/redis-{{ version }}.tar.gz
  cmd.run:
    - name: |
        cd /usr/local/src
        tar zxf redis-{{ version }}.tar.gz
        cd redis-{{ version }}
        make PREFIX=/usr/local/redis install &> /dev/null
    - require:
      - pkg: redis-install
    - unless: test -d /usr/local/redis

redis-conf:
  file.managed:
    - name: /etc/redis.conf
    - source: salt://redis/config/redis.conf
    - require:
      - cmd: redis-install
