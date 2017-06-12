minion.sls 通过salt-ssh直接推送客户端安装minion

`salt-ssh -i \* state.sls init.minion`

what.sls 对minion进行初始化，内容包括：yum安装常用软件、修改hostname、添加命令审计、关闭密码登录等

`salt \* state.sls init.what`

user.sls 调用pillar变量添加用户

`salt \* state.sls init.user`