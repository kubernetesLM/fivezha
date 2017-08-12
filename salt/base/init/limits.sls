# 修改nproc
{% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
/etc/security/limits.d/90-nproc.conf:
  file.replace:
    - pattern: '\*          soft    nproc     1024$'
    - repl: '*          soft    nproc     10240'
{% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
/etc/security/limits.d/20-nproc.conf:
  file.replace:
    - pattern: '\*          soft    nproc     1024$'
    - repl: '*          soft    nproc     10240'
{% endif %}
