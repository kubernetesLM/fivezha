
安装minion软件

`salt-ssh -i \* state.sls init.minion`

对minion环境初始化

`salt \* state.sls init.what`

添加用户

`salt \* state.sls init.user`
