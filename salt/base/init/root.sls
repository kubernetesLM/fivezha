# 添加root密钥
ssh_key_root:
  ssh_auth.present:
    - user: root
    - source: salt://sshkey/root.pub
