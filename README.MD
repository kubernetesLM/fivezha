安装minion客户端，master配置好/etc/salt/roster后执行

`salt-ssh -i \* state.sls minion`

master接受客户端

`salt-key -a 'web1,web2'`

对minion环境初始化

`salt \* state.sls init`

master配置信息

```
[root@salt-master ~]# grep -Ev "^$|#" /etc/salt/master 
interface: 0.0.0.0
file_roots:
  base:
    - /srv/salt/base
  prod:
    - /srv/salt/prod
pillar_roots:
  base:
    - /srv/pillar/base
  prod:
    - /srv/pillar/prod
```
