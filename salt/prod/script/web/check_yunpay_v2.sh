#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

project="yunpay_v2"
project_dir=$web_dir/tomcat_$project
web_url=http://127.0.0.1:8084/$project/api/v2/user/login

fail_ation(){
	ymd=$(date +%Y%m%d)
	hm=$(date +%H%M)
	#1.记录日志
	tail -n10000 $project_dir/logs/catalina.out > $log_bak_dir/${project}_catalina_${ymd}_$hm.out
	pid=$(ps -ef | grep java | grep "$project_dir/" | grep -v grep | awk '{print $2}')
	su -l $run_user -s /bin/bash -c "jstack $pid" > $log_bak_dir/${project}_jstack_${ymd}_$hm.log
	#2.重启
	$script_dir/ctrl_yunpay.sh $project restart
}

check_status(){
	http_code=$(curl -s -o /dev/null -m 3 --connect-timeout 3 $web_url -w %{http_code})
	if [[ "$http_code" != "200" ]];then
		((fail_time++))
	else
		unset fail_time
	fi
}


while true
do
	check_status
	if [[ "$fail_time" -eq 3 ]];then
		fail_ation
		unset fail_time
	fi
	sleep 30
done

