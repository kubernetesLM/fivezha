{% set version = '1.12.0' %}
nginx-install:
  pkg.installed:
    - pkgs:
      - pcre-devel
      - zlib-devel
      - openssl-devel
  file.managed:
    - name: /usr/local/src/nginx-{{ version }}.tar.gz
    - source: salt://soft/nginx-{{ version }}.tar.gz
  cmd.run:
    - name: |
        cd /usr/local/src
        tar zxvf nginx-{{ version }}.tar.gz
        cd nginx-{{ version }}
        ./configure --with-http_ssl_module --with-http_realip_module --with-http_stub_status_module
        make -j 2 && make install
    - require:
      - pkg: nginx-install
    - unless: test -d /usr/local/nginx

nginx-conf:
  file.managed:
    - name: /usr/local/nginx/conf/nginx.conf
    - source: salt://nginx/config/nginx.conf
    - require:
      - cmd: nginx-install

nginx-logrotate:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://nginx/config/nginx
    - require:
      - file: nginx-conf
