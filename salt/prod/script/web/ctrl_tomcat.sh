#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

project=$1
action=$2
update_file=$3
project_dir=$web_dir/tomcat_$project
project_data_dir=$web_dir/${update_file%.*}


# 脚本用法
function usage(){
	echo_red "脚本用法：$0 project atcion"
	echo "       project:{yffs|yfpw|yfqc|yffdc|yzyj|...}"
	echo "       action:{start|stop|restart|stauts}"
	echo_red "普通更新用法：$0 project update update_file"
	echo "       update_file:{yffs_20170110-001.zip|yffs_site_20170110-001.zip|...}"
	echo "       更新并重启服务"
	echo_red "增量更新用法：$0 project inc_update update_file"
	echo "       update_file:{yffs_inc_20170110-001.zip|yffs_site_inc_20170110-001.zip|...}"
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
	[[ ! "$update_file" =~ [0-9]{8}-[0-9]{3} ]] && {
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
	http_code=$(curl -sI http://$ftp_ip:$port1/${project%%_*}/$update_file | awk 'NR==1{print $2}')
	if [ $http_code -eq 200 ];then
		wget -N http://$ftp_ip:$port1/${project%%_*}/$update_file
		[ $? -ne 0 ] && {
			echo_red "下载失败，请重试."
			exit 1
		}
	else
		if [ -e $update_file ];then
			echo "更新将使用本机文件：$update_dir/$update_file."
		else
			echo_red "请确保更新包已完整上传FTP服务器、或者已上传/data/update"
			exit 1
		fi
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
	
	# 项目云返服饰段落
	if [ "$project" == "yffs" ];then
		rm $project_data_dir/ueditor1_3_6 -rf
		rm $project_data_dir/upload -rf
		rm $project_data_dir/WEB-INF/views/index.jsp -rf
		mv $project_dir/webapps/$root_name/ueditor1_3_6 $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
		\cp $project_dir/webapps/$root_name/WEB-INF/views/index.jsp $project_data_dir/WEB-INF/views/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/application.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云返服饰官网段落
	elif [ "$project" == "yffs_site" ];then
		rm $project_data_dir/ueditor1_3_6 -rf
		rm $project_data_dir/upload -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/ueditor1_3_6 $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/application.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云返服饰job段落
	elif [ "$project" == "yffs_job" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/application.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云返服饰比赛段落
	elif [ "$project" == "yffs_match" ];then
		rm $project_data_dir/ueditor1_3_6 -rf
		rm $project_data_dir/upload -rf
		mv $project_dir/webapps/$root_name/ueditor1_3_6 $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/application.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云返汽车段落
	elif [ "$project" == "yfqc" ];then
		rm $project_data_dir/apkurl -rf
		rm $project_data_dir/brand -rf
		rm $project_data_dir/detail -rf
		rm $project_data_dir/success -rf
		rm $project_data_dir/upload -rf
		rm $project_data_dir/lib -rf
		rm $project_data_dir/maincar -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/apkurl $project_data_dir/
		mv $project_dir/webapps/$root_name/brand $project_data_dir/
		mv $project_dir/webapps/$root_name/detail $project_data_dir/
		mv $project_dir/webapps/$root_name/success $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
		mv $project_dir/webapps/$root_name/lib $project_data_dir/
		mv $project_dir/webapps/$root_name/maincar $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云返汽车v2段落
	elif [ "$project" == "yfqc_v2" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
	# 项目云返汽车site段落
	elif [ "$project" == "yfqc_site" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
	# 项目云返汽车mobile段落
	elif [ "$project" == "yfqc_mobile" ];then
		rm $project_data_dir/ueditor1_3_6 -rf
		rm $project_data_dir/upload -rf
		mv $project_dir/webapps/$root_name/ueditor1_3_6 $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
	# 项目云返汽车admin段落
	elif [ "$project" == "yfqc_admin" ];then
		rm $project_data_dir/upload -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
	# 项目云返房地产段落
	elif [ "$project" == "yffdc" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		rm $project_data_dir/static/image -rf
		rm $project_data_dir/ueditor -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		mv $project_dir/webapps/$root_name/static/image $project_data_dir/static/
		mv $project_dir/webapps/$root_name/ueditor $project_data_dir/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/application.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/logback.xml $project_data_dir/WEB-INF/classes/
	# 项目云返票务段落
	elif [ "$project" == "yfpw.bak" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		rm $project_data_dir/commons/images -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		mv $project_dir/webapps/$root_name/commons/images $project_data_dir/commons/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/yunpay-config.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/zhizhuwang-config.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/yataixin-config.properties $project_data_dir/WEB-INF/classes/
	elif [ "$project" == "yfpw" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		rm $project_data_dir/commons/images -rf
		rm $project_data_dir/WEB-INF/classes/third_config -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		mv $project_dir/webapps/$root_name/commons/images $project_data_dir/commons/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
		\cp -a $project_dir/webapps/$root_name/WEB-INF/classes/third_config $project_data_dir/WEB-INF/classes/
	# 项目云返票务后台段落
	elif [ "$project" == "yfpw_admin" ];then
		rm $project_data_dir/plugins -rf
		rm $project_data_dir/uploadFiles -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/plugins $project_data_dir/
		mv $project_dir/webapps/$root_name/uploadFiles $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/dbconfig.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/dbfh.properties $project_data_dir/WEB-INF/classes/
	# 项目云返票务段落
	elif [ "$project" == "yfpw_service" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		rm $project_data_dir/WEB-INF/classes/third_config -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp -a $project_dir/webapps/$root_name/WEB-INF/classes/third_config $project_data_dir/WEB-INF/classes/
	# 项目云返酒店admin段落
	elif [ "$project" == "yfjd_admin" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
	# 项目云返酒店admin段落
	elif [ "$project" == "yfjd_partner" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
	# 项目云智硬件段落
	elif [ "$project" == "yzyj" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云智硬件定时器段落
	elif [ "$project" == "yzyj_job" ];then
		rm $project_data_dir/head -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/head $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云智pos段落
	elif [ "$project" == "yzyj_pos" ];then
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
	# 项目云智mobile段落
	elif [ "$project" == "yzyj_mobile" ];then
		rm $project_data_dir/ueditor1_3_6 -rf
		rm $project_data_dir/upload -rf
		mv $project_dir/webapps/$root_name/ueditor1_3_6 $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
	# 项目云返旅游site段落
	elif [ "$project" == "yfly" ];then
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
	# 项目云返旅游site段落
	elif [ "$project" == "yfly_site" ];then
		rm $project_data_dir/ueditor1_3_6 -rf
		rm $project_data_dir/upload -rf
		mv $project_dir/webapps/$root_name/ueditor1_3_6 $project_data_dir/
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
	# 项目云返旅游site段落
	elif [ "$project" == "yfly_admin" ];then
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
	# 项目云返旅游site段落
	elif [ "$project" == "yfly_job" ];then
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
	# 项目云商珠宝admin段落
	elif [ "$project" == "yszb_admin" ];then
		rm $project_data_dir/upload -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/upload $project_data_dir/
		mv $project_dir/webapps/$root_name/WEB-INF/lib $project_data_dir/WEB-INF/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/jdbc.c3p0.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/log4j.properties $project_data_dir/WEB-INF/classes/
		\cp $project_dir/webapps/$root_name/WEB-INF/classes/redis.properties $project_data_dir/WEB-INF/classes/
	# 项目艾腾流量聚合段落
	elif [ "$project" == "aten_flow" ];then
		rm $project_data_dir/plugins -rf
		rm $project_data_dir/uploadFiles -rf
		rm $project_data_dir/static -rf
		rm $project_data_dir/WEB-INF/lib -rf
		mv $project_dir/webapps/$root_name/plugins $project_data_dir/
		mv $project_dir/webapps/$root_name/uploadFiles $project_data_dir/
		mv $project_dir/webapps/$root_name/static $project_data_dir/
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
case_project2
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
