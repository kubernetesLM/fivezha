{% set version = '5.6.30' %}
mysql-install_pre:
  file.managed:
    - name: /usr/local/src/mysql-{{ version }}-linux-glibc2.5-x86_64.tar.gz
    - source: salt://soft/mysql-{{ version }}-linux-glibc2.5-x86_64.tar.gz
  cmd.run:
    - name: |
        cd /usr/local/src
        tar -zxf mysql-{{ version }}-linux-glibc2.5-x86_64.tar.gz
        mv mysql-{{ version }}-linux-glibc2.5-x86_64 /usr/local/mysql
        groupadd -g 27 mysql
        useradd -r -u 27 -g 27 -s /sbin/nologin mysql
    - unless: test -d /data/web/mysql

mysql-cnf:
  file.managed:
    - name: /etc/my.cnf
    - source: salt://mysql/config/my.cnf
    - require:
      - cmd: mysql-install_pre

mysql-install:
  cmd.run:
    - name: |
        cd /usr/local/mysql
        /usr/local/mysql/scripts/mysql_install_db --user=mysql
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
        chmod +x /etc/init.d/mysqld
        #/etc/init.d/mysqld start
        #/usr/local/mysql/bin/mysqladmin -uroot password
        sed -i 's@^PATH.*@&:/usr/local/mysql/bin@' /root/.bash_profile
    - require:
      - file: mysql-cnf
