#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

project=$1
action=$2
update_file=$3
project_dir=$web_dir/tomcat_$project
project_data_dir=$web_dir/${update_file%.*}
check_script=$script_dir/check_${project}.sh

# 脚本用法
function usage(){
	echo_red "脚本用法：sh $0 project atcion"
	echo "       project:{yunpay_static|yunpay_v2|yunpay_cc|yunpay_red|yunpay_admin}"
	echo "       action:{start|stop|restart|stauts}"
	echo_red "普通更新用法：sh $0 project update update_file"
	echo "       update_file:{yunpay_static_20170110-001.zip|yunpay_v2_20170110-001.zip|...}"
	echo "       更新并重启服务"
	echo_red "增量更新用法：sh $0 project inc_update update_file"
	echo "       update_file:{yunpay_static_inc_20170110-001.zip|yunpay_v2_inc_20170110-001.zip|...}"
	echo "       只更新不重启服务"
	exit 1
}

# 获取tomcat的pid
function get_pid(){
	pid=$(ps -ef | grep java | grep "$project_dir/" | grep -v grep | awk '{print $2}')
}

# 启动tomcat
function start(){
	get_pid
	[ -n "$pid" ] && {
		echo_red "$project 已经在运行."
		return
	}
	chown -RL $run_user:$run_user $project_dir
	echo "$project 开始启动."
	su -l $run_user -c "$project_dir/bin/startup.sh"
	
	# 开启检测脚本
	[ -f $check_script ] && {
		pid2=$(ps -ef | grep check_ | grep "$check_script" |grep -v grep |awk '{print $2}')
		[ -z "$pid2" ] && {
			cd ~
			nohup $check_script &
		}
	}
}

# 关闭tomcat
function stop(){
	get_pid
	[ -z "$pid" ] && {
		echo_red "$project 已经停止了."
		return
	}
	su -l $run_user -c "$project_dir/bin/shutdown.sh"
	echo -n "$project 开始关闭，预计30秒"
	for((i=0;i<10;i++))
	do
		for((j=0;j<3;j++))
		do
			echo -n "."
			sleep 1
		done
		get_pid
		[ -z "$pid" ] && {
			echo ""
			echo "关闭成功"
			break
		}
	done
	[ -n "$pid" ] && {
		echo ""
		echo "关闭失败，脚本强制停止进程$pid"
		kill -9 $pid
	}
	
	# 关闭检测脚本
	[ -f $check_script ] && {
		pid2=$(ps -ef | grep check_ | grep "$check_script" |grep -v grep |awk '{print $2}')
		[ -n "$pid2" ] && kill -9 $pid2
	}

	# 删除日志
	find $project_dir/logs -type f -mtime +30 -exec rm -f {} \;
}

# 查看状态
function status(){
	get_pid
	if [ -n "$pid" ];then
		echo "$project 正在运行中."
	else
		echo "$project 未启动."
	fi
}

# 更新时，脚本传参检测
function check_update_value(){
	# 根据action值设定prefix_name
	if [ "$action" == "update" ];then
		# 唉
		[ -d $project_data_dir ] && {
			echo_red "$project_data_dir 版本已存在，不能更新"
			exit 1
		}
		prefix_name=${project}_
	elif [ "$action" == "inc_update" ];then
		prefix_name=${project}_inc_
	fi

	# 判断update_file前缀
	[ "${update_file%_*}_" != "$prefix_name" ] && {
		echo_red "$update_file 文件名前缀出错，格式必须如下："
		echo_red "$prefix_name"
		exit 1
	}
	
	# 判断update_file日期版本号格式
	! [[ "$update_file" =~ [0-9]{8}-[0-9]{3} ]] && {
		echo_red "$update_file 日期版本号出错，格式必须如下："
		echo_red "20170303-001"
		exit 1
	}
	
	# 判断update_file后缀
	[ "${update_file##*.}" != "zip" ] && {
		echo_red "$update_file 文件名后缀出错，格式必须如下："
		echo_red ".zip"
		exit 1
	}
	
	# 下载update_file
	[ -d $update_dir ] || mkdir -p $update_dir && cd $update_dir	
	if [ -e $update_file ];then
		http_code=$(curl -sI http://$ftp_ip:$port1/${project%%_*}/$update_file | awk 'NR==1{print $2}')
		if [ $http_code -eq 200 ];then
			wget -N http://$ftp_ip:$port1/${project%%_*}/$update_file
			[ $? -ne 0 ] && {
				echo_red "下载失败，请重试."
				exit 1
			}
		else
			echo "更新将使用本机文件：$update_dir/$update_file."
		fi
	else
		wget -N http://$ftp_ip:$port1/${project%%_*}/$update_file
		[ $? -ne 0 ] && {
			echo_red "下载失败，请重试."
			exit 1
		}
	fi
	
	# 判断update_file压缩后的首目录名
	result=$(unzip -l $update_file | awk 'NR==4{print $NF}' | sed 's@/@@')
	[ "$result" != "$root_name" ] && {
		echo_red "$update_file 文件解压后首目录出错"
		echo -n "目前结果是："
		echo_red "$result"
		echo -n "要求必须是："
		echo_red "$root_name"
		exit 1
	}
	echo "$update_file 名称合法性检测已通过"
}

# 普通更新，备份
function update(){
	# 解压新版本
	unzip -q $update_dir/$update_file -d $web_dir
	mv $web_dir/$root_name $project_data_dir

	# 项目云支付pc段落
	if [ "$project" == "yunpay_static" ];then
		rm $project_data_dir/commons/chat -rf
		rm $project_data_dir/commons/upload -rf
		rm $project_data_dir/commons/ueditor -rf
		rm $project_data_dir/commons/umeditor -rf
		rm $project_data_dir/commons/images/pictureCode -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/commons/chat $project_data_dir/commons/
		mv $project_dir/webapps/$root_name/commons/upload $project_data_dir/commons/
		mv $project_dir/webapps/$root_name/commons/ueditor $project_data_dir/commons/
		mv $project_dir/webapps/$root_name/commons/umeditor $project_data_dir/commons/
		mv $project_dir/webapps/$root_name/commons/images/pictureCode $project_data_dir/commons/images/
		cp -a $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis-config.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/mongodb.properties $project_data_dir/WEB-INF/classes/
	# 项目云支付v2段落
	elif [ "$project" == "yunpay_v2" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		cp -a $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis-config.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/mongodb.properties $project_data_dir/WEB-INF/classes/
	# 项目云支付cc段落
	elif [ "$project" == "yunpay_cc" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		cp -a $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis-config.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/mongodb.properties $project_data_dir/WEB-INF/classes/
	# 项目云支付red段落
	elif [ "$project" == "yunpay_red" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		cp -a $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis-config.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/mongodb.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redisson_config.json $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/quartz.properties $project_data_dir/WEB-INF/classes/
	# 项目云支付credit段落
	elif [ "$project" == "yunpay_credit" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		cp -a $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云支付api段落
	elif [ "$project" == "yunpay_service" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		cp -a $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云支付admin段落
	elif [ "$project" == "yunpay_admin" ];then
		rm $project_data_dir/commons -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/commons $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
	# 项目云支付flow_recharge段落
	elif [ "$project" == "yunpay_flow_recharge" ];then
		rm $project_data_dir/plugins -rf
		rm $project_data_dir/static -rf
		rm $project_data_dir/uploadFiles -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/plugins $project_data_dir/
		mv $project_dir/webapps/$root_name/static $project_data_dir/
		mv $project_dir/webapps/$root_name/uploadFiles $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/dbconfig.properties $project_data_dir/WEB-INF/classes/
	fi
	
	# 备份旧版本
	[ -d $web_bak_dir ] || mkdir -p $web_bak_dir
	pre_version=$(basename $(readlink $project_dir/webapps/$root_name))
	if [ -d $web_bak_dir/update_${pre_version} ];then
		mv $web_dir/$pre_version $web_bak_dir/update_${pre_version}_$hm
		echo_red "备份文件在：$web_bak_dir/update_${pre_version}_$hm"
	else
		mv $web_dir/$pre_version $web_bak_dir/update_${pre_version}
		echo_red "备份文件在：$web_bak_dir/update_${pre_version}"
	fi
	
	# 修改软链接
	rm $project_dir/webapps/$root_name -f
	ln -s $project_data_dir $project_dir/webapps/$root_name
	echo "更新已完成"
}

# 增量更新、备份
function inc_update(){
	temp_file=/tmp/file_list.$$
	unzip -l $update_dir/$update_file | awk 'NR>3&&NF>3{print $NF}' | grep -v '/$' > $temp_file
	# 增量更新前，备份文件
	pre_version=$(basename $(readlink $project_dir/webapps/$root_name))
	cd $project_dir/webapps
	tar zcf $web_bak_dir/inc_update_${pre_version}_${hm}.tgz -T $temp_file --ignore-failed-read
	echo_red "备份文件在：$web_bak_dir/inc_update_${pre_version}_${hm}.tgz"
	rm -f $temp_file
	# 增量更新
	su -l $run_user -c "unzip -qo $update_dir/$update_file -d $project_dir/webapps"
	echo "增量更新已完成"
}

# 判断参数个数
[ "$#" -lt 2 ] && {
	echo_red "脚本参数个数出错，至少2个."
	usage
}

# 判断运行用户是否存在
! id $run_user &> /dev/null && {
	echo_red "$run_user 该用户不存在，请先创建，运行项目所需."
	exit 1
}

# 判断项目目录是否存在
[ ! -d $project_dir ] && {
	echo_red "$project_dir 目录不存在，请检查."
	exit 1
}

# 判断project变量
case_yunpay
[ -z "$root_name" ] && {
	echo_red "你可能用错脚本了，云支付项目用ctrl_yunpay.sh,其他项目用ctrl_tomcat.sh."
	echo_red "脚本没用错，请联系系统管理员."
	exit 1
}

# 判断数据目录是否为软链接
[ ! -L $project_dir/webapps/$root_name ] && {
	echo_red "$project_dir/webapps/$root_name 不是软链接目录，脚本无法完成更新."
	exit 1
}

# 判断action变量
case $action in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		stop
		start
		;;
	status)
		status
		;;
	update)
		# 若action为update,参数只能3个
		[ "$#" -ne 3 ] && {
			echo_red "脚本参数个数出错，普通更新时只能是3个."
			usage
		}
		check_update_value
		# 确定是否更新
		read -p "确认更新请输入yes，其他值退出:" flag
		[ "$flag" != "yes" ] && {
			echo_red "输入的不是yes"
			exit 1
		}
		stop
		update
		start
		;;
	inc_update)
		# 若action为inc_update,参数只能3个
		[ "$#" -ne 3 ] && {
			echo_red "脚本参数个数出错，增量更新时只能是3个."
			usage
		}
		check_update_value
		inc_update
		;;
	*)
		echo_red "未定义的action"
		usage
		;;
esac
