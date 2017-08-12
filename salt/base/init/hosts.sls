# 修改hosts
sed_hosts:
 cmd.run:
   - name: sed -i "s/^127.0.0.1.*/127.0.0.1 {{ grains['id'] }} localhost/" /etc/hosts
   - unless: grep "^127.0.0.1 {{ grains['id'] }} localhost$" /etc/hosts
