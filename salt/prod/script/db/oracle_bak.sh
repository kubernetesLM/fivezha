#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

export ORACLE_SID=yunpay
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
PATH=$PATH:$ORACLE_HOME/bin

rman_log=$log_bak_dir/rman_${ymd}.log
oracle_bak_log=/tmp/${USER}_bak.log
user=system
password=password
schemas="yunpay yffs yfqc yfpw yzyj"
fail_count=0


# 1.判断运行用户
if [ "$USER" != "oracle" ];then
	echo_red "请以oracle用户执行脚本" > $oracle_bak_log
	((fail_count++))
fi
# 2.判断oracle备份目录
if [ ! -d $oracle_bak_dir ];then
	echo_red "$oracle_bak_dir 备份目录不存在" >> $oracle_bak_log
	((fail_count++))
else
	result1=$(ls -ld $oracle_bak_dir | awk '$3=="oracle" && $4=="oinstall"')
	[ -z "$result1" ] && {
		echo_red "$oracle_bak_dir 目录属主错误，请运行chown -R oracle:oinstall $oracle_bak_dir." >> $oracle_bak_log
		((fail_count++))
	}
fi
# 3.判断oracle dba_directories
result2=$(echo "select directory_path from dba_directories where directory_name='BACKUP';" | sqlplus -S $user/$password | awk 'NR==4')
[ "$result2" != "/data/backup/oracle" ] && {
	echo_red "oracle dba_directories 配置不正确，请登录sqlplus运行create directory backup as '/data/backup/oracle';" >> $oracle_bak_log
	((fail_count++))
}
# 4.判断log目录
if [ ! -d $log_bak_dir ];then
	echo_red "$log_bak_dir 目录不存在" >> $oracle_bak_log
	((fail_count++))
else
	result3=$(stat $log_bak_dir | awk 'NR==4{if($2~777)print}')
	[ -z "$result3" ] && {
		echo_red "$log_bak_dir 目录权限错误，请运行chmod 777 $log_bak_dir" >> $oracle_bak_log
		((fail_count++))
	}
fi

[ "$fail_count" -ne 0 ] && {
	echo_red "备份先决条件出错，查看$oracle_bak_log 获取更多详细信息"
	exit 1
}

# 开始expdp备份
for schema in $schemas
do
	# yunpay_log每周备份一次
	if [[ $schema == "yunpay_log" && $day_of_week -ne 7 ]];then
		continue
	fi
	# yunpay每周全备一次
	if [[ $schema == "yunpay" && $day_of_week -ne 7 ]];then
		expdp $user/$password directory=backup dumpfile=schemas_${schema}_${ymd}.expdp logfile=schemas_${schema}_${ymd}.log schemas=$schema exclude=table:\"in\(\'Y_CLOUDBILL\',\'Y_BALANCEBILL\',\'Y_MSG\',\'Y_LOGIN_LOG\'\)\"
		mv $oracle_bak_dir/schemas_${schema}_${ymd}.log $log_bak_dir
		continue
	fi
	echo "select username from dba_users;" | sqlplus -S $user/$password | grep -qi "^$schema$" && {
		expdp $user/$password directory=backup dumpfile=schemas_${schema}_${ymd}.expdp logfile=schemas_${schema}_${ymd}.log schemas=$schema
		mv $oracle_bak_dir/schemas_${schema}_${ymd}.log $log_bak_dir
	}
done



if [ $day_of_week -eq 7 ];then
	bak_level=0
	level_name=complete
	# 删除15天前expdp备份
	find $oracle_bak_dir -maxdepth 1 -type f -name "schemas_*" -mtime +7 -exec rm -f {} \;
	# 删除15天前expdp日志和rman日志
	find $log_bak_dir -type f \( -name "schemas_*" -o -name "rman_*" \) -mtime +7 -exec rm -f {} \;
else
	bak_level=1
	level_name=incremental
fi

# 开始rman备份
rman target / log $rman_log <<- EOF
configure retention policy to recovery window of 7 days;
run
{
	allocate channel c1 type disk;
	allocate channel c2 type disk;
	backup incremental level $bak_level database tag="$level_name" format="$oracle_bak_dir/${ORACLE_SID}_%T_${level_name}_%s" skip inaccessible filesperset 10;
	sql 'alter system archive log current';
	backup archivelog all tag="arc_bak" format="$oracle_bak_dir/arch_%T_${level_name}_%s" skip inaccessible filesperset 10 delete input;
	release channel c1;
	release channel c2;
}
delete noprompt obsolete;
crosscheck backup;
delete noprompt expired backup;
EOF
