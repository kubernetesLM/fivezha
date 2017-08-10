# 修改hostname
sed_hostname:
  cmd.run:
    {% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '6' %}
    - name: |
        sed -i "s/^HOSTNAME=.*/HOSTNAME={{ grains['id'] }}/" /etc/sysconfig/network
        hostname {{ grains['id'] }}
    - unless: grep "^HOSTNAME={{ grains['id'] }}$" /etc/sysconfig/network
    {% elif grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}
    - name: hostnamectl --static set-hostname {{ grains['id'] }}
    - unless: hostname | grep "^{{ grains['id'] }}$"
    {% endif %}
