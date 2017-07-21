安装minion软件

master配置好/etc/salt/roster

`salt-ssh -i \* state.sls minion`

对minion环境初始化

`salt \* state.sls init`

添加用户

`salt \* state.sls users`
