#!/bin/bash
# PATH变量
JAVA_HOME=/usr/java/jdk1.7.0_80
MYSQL_HOME=/usr/local/mysql
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$JAVA_HOME/bin:$MYSQL_HOME/bin

# 时间变量
ymd=$(date +%Y%m%d)
hm=$(date +%H%M)
day_of_week=$(date +%u)

# 目录变量
bak_dir=/data/backup
web_bak_dir=$bak_dir/web
svn_bak_dir=$bak_dir/svn
log_bak_dir=$bak_dir/log
mysql_bak_dir=$bak_dir/mysql
oracle_bak_dir=$bak_dir/oracle

web_dir=/data/web
svn_dir=/data/svn
mysql_dir=/data/mysql
update_dir=/data/update
script_dir=/data/script

# 地址变量
ftp_ip=ftp.atenops.com
port1=10080
port2=10081

# 设置tomcat运行用户
run_user="tomcat"

# 字体打印红色
function echo_red()
{
	echo -ne "\033[1;31m"
	echo -n " $1"
	echo -e "\033[0m"
}

# 判断云支付项目project变量
function case_yunpay(){
	case $project in
		yunpay_v2)
			root_name="yunpay_v2";;
		yunpay_static)
			root_name="yunpay_static";;
		yunpay_cc)
			root_name="yunpay_cc";;
		yunpay_red)
			root_name="yunpay_red";;
		yunpay_credit)
			root_name="yunpay_credit";;
		yunpay_admin)
			root_name="ROOT";;
		yunpay_service)
			root_name="ROOT";;
		yunpay_flow_recharge)
			root_name="atflow";;
		*)
			echo_red "Undefine project";;
	esac
}


# 判断其他项目project变量
function case_project2(){
	case $project in
		yffs)
			root_name="yffs";;
		yffs_site)
			root_name="yffs_site";;
		yffs_job)
			root_name="yffs_job";;
		yffs_match)
			root_name="xp";;
		yfqc)
			root_name="yfqc";;
		yfqc_v2)
			root_name="ROOT";;
		yfqc_admin)
			root_name="ROOT";;
		yfqc_site)
			root_name="ROOT";;
		yfqc_mobile)
			root_name="ROOT";;
		yffdc)
			root_name="ROOT";;
		yfpw.bak)
			root_name="yunticket";;
		yfpw)
			root_name="ROOT";;
		yfpw_admin)
			root_name="FHADMINO";;
		yfpw_mobile)
			root_name="yfpw_site";;
		yfpw_service)
			root_name="ROOT";;
		yfjd)
			root_name="ROOT";;
		yfjd_admin)
			root_name="ROOT";;
		yfjd_partner)
			root_name="ROOT";;
		yfjd_job)
			root_name="ROOT";;
		yzyj)
			root_name="yzapp";;
		yzyj_pos)
			root_name="yzpos";;
		yzyj_job)
			root_name="yzjob";;
		yzyj_mobile)
			root_name="ROOT";;
		yfjy_site)
			root_name="yfjy_site";;
		yfly_site)
			root_name="ROOT";;
		yfly)
			root_name="ROOT";;
		yfly_admin)
			root_name="ROOT";;
		yfly_job)
			root_name="ROOT";;
		yfbx_site)
			root_name="yfbx_site";;
		yfglfw_site)
			root_name="yfglfw_site";;
		yszb)
			root_name="ROOT";;
		yszb_site)
			root_name="yszb_site";;
		yszb_admin)
			root_name="ROOT";;
		#艾腾项目
		aten_repertory)
			root_name="ROOT";;
		aten_site)
			root_name="aten_site";;
		aten_flow)
			root_name="jhflow";;
		*)
			echo_red "Undefine project";;
	esac
}