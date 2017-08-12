# 关闭不常用的服务
{% set service = 'postfix' %}
disable-{{ service }}:
  service.disabled:
    - name: {{ service }}
