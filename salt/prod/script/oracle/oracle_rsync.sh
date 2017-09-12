#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

opts="-avz"
rsync_log=$log_bak_dir/rsync_${ymd}.log
data_file=$(ls -1 $oracle_bak_dir | grep "schemas.*$ymd")
ruser="backup"
rip=10.25.192.206
random_time=$(($RANDOM%1800))

# rsync同步
[ -n "$data_file" ] && {
	# 防止多台同时同步造成io紧张
	sleep $random_time
	cd $oracle_bak_dir
	rsync $opts -e "ssh -o StrictHostKeyChecking=no" --log-file=$rsync_log $data_file $ruser@$rip:$oracle_bak_dir
}

# 删除rsync日志
find $log_bak_dir -type f -name "rsync_*" -mtime +15 -exec rm -f {} \;
