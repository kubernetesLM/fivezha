# 添加history时间格式
/etc/profile:
  file.managed:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - source: salt://init/config/profile-c6
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - source: salt://init/config/profile-c7
    {% endif %}
