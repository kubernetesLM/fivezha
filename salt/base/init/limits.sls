# 修改nproc
limits.d:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - name: /etc/security/limits.d/90-nproc.conf
    - source: salt://init/config/90-nproc.conf
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - name: /etc/security/limits.d/20-nproc.conf
    - source: salt://init/config/20-nproc.conf
    {% endif %}
