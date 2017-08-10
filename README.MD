安装minion软件

master配置好/etc/salt/roster后执行

`salt-ssh -i \* state.sls minion`

master接受客户端

`salt-key -a 'web1,web2'`

对minion环境初始化

`salt \* state.sls init`
