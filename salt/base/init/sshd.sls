# 关闭登录过程dns反解析
/etc/ssh/sshd_config1:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '#UseDNS yes'
    - repl: 'UseDNS no'

# 关闭密码登录
/etc/ssh/sshd_config2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^PasswordAuthentication yes'
    - repl: 'PasswordAuthentication no'
    - require:
      - ssh_auth: ssh_key_hujf 
  service.running:
    - name: sshd
    - reload: true
    - watch:
      - file: /etc/ssh/sshd_config2
