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

redis-install-post:
  cmd.run:
    - name: |
        mkdir /data/redis
        useradd -s /sbin/nologin -d /data/redis redis
        chown -R redis:redis /data/redis
        echo 512 > /proc/sys/net/core/somaxconn
        echo never > /sys/kernel/mm/transparent_hugepage/enabled
        sysctl vm.overcommit_memory=1
        echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
        echo "echo 512 >  /proc/sys/net/core/somaxconn" >> /etc/rc.local
        echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
    - require:
      - file: redis-conf
    - onlyif: test -d /data
