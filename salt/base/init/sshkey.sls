# 添加root密钥
ssh_key_root:
  ssh_auth.present:
    - user: root
    - source: salt://init/sshkey/root.pub

# 添加admin群组
groupadd_admin:
  group.present:
    - name: admin

# 添加super群组
groupadd_super:
  group.present:
    - name: super

# 添加admin成员密钥
ssh_key_hujf:
  user.present:
    - name: hujf
    - gid: admin
    - require:
      - group: groupadd_admin
  ssh_auth.present:
    - user: hujf
    - source: salt://init/sshkey/hujf.pub
    - require:
      - file: /etc/sudoers

# 添加super成员密钥
{% for user in 'huangzhx','sheab' %}
ssh_key_{{ user }}:
  user.present:
    - name: {{ user }}
    - gid: super
    - require:
      - group: groupadd_super
  ssh_auth.present:
    - user: {{ user }}
    - source: salt://init/sshkey/{{ user }}.pub
{% endfor %}
