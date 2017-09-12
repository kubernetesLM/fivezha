#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

project="yunpay_cc"
project_dir=$web_dir/tomcat_$project
web_url=http://127.0.0.1:8085/$project/ping/

fail_ation(){
	ymd=$(date +%Y%m%d)
	hm=$(date +%H%M)
	#1.记录日志
	tail -n10000 $project_dir/logs/catalina.out > $log_bak_dir/${project}_catalina_${ymd}_$hm.out
	#echo > $project_dir/logs/catalina.out
	pid=$(ps -ef | grep java | grep "$project_dir/" | grep -v grep | awk '{print $2}')
	su $run_user -s /bin/bash -c "jstack $pid" > $log_bak_dir/${project}_jstack_${ymd}_$hm.log
	#2.重启
	$script_dir/ctrl_yunpay.sh $project restart
}

check_status(){
	http_code=$(curl -s -o /dev/null -m 3 --connect-timeout 3 $web_url -w %{http_code})
	web_code=$(curl -s -m 3 --connect-timeout 3 $web_url | head -n1)
	if [[ "$http_code" -ne "200" ]];then
		((fail_count1++))
	else
		unset fail_count1
		if [[ "$web_code" -ne 0 ]];then
			((fail_count2++))
			echo $(date "+%F %T") $web_code >> $log_bak_dir/web_code
		else
			unset fail_count2
		fi
	fi

}

while true
do
	check_status
	if [[ "$fail_count1" -eq 3 || "$fail_count2" -eq 3  ]];then
		fail_ation
		unset fail_count1
		unset fail_count2
	fi
	sleep 30
done
