# 添加群组、用户
{% for user,args in pillar['users'].items() %}
{{ user }}:
  group.present:
    - name : {{ args['group'] }}
  user.present:
#    - fullname: {{ args['fullname'] }}
    - gid: {{ args['gid'] }}
  ssh_auth.present:
    - enc: {{ args['enc'] }}
    - name: {{ args['key'] }}
    - comment: {{ args['comment'] }}
{% endfor %}
