# 添加群组admin sudo权限
/etc/sudoers:
   file.managed:
     - source: salt://config/sudoers

# 添加群组、用户
{% for user,args in pillar['users'].items() %}
{{ user }}:
  group.present:
    - name : {{ args['group'] }}
    - require:
      - file: /etc/sudoers
  user.present:
    - fullname: {{ args['fullname'] }}
    - gid: {{ args['gid'] }}
    - require:
      - group: {{ args['group'] }}
  ssh_auth.present:
    - user: {{ user }}
    - enc: {{ args['enc'] }}
    - name: {{ args['key'] }}
    - comment: {{ args['comment'] }}
    - require:
      - user: {{ user }}
{% endfor %}