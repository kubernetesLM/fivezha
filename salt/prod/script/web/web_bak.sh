#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

projects="yunpay_v2 yunpay_cc yunpay_red yunpay_service yunpay_credit \
yfqc yfqc_v2 yfqc_admin \
yfpw yfpw_admin yfpw_service \
yfjd yfjd_admin \
yzyj yzyj_pos \
yfly yfly_admin"

# 备份tomcat项目
for project in $projects
do
	case_yunpay
	case_project2
	project_dir=$web_dir/tomcat_$project
	[ -d $project_dir ] && {
		mkdir -p $web_bak_dir
		cd $project_dir/webapps
		tar zcfh $web_bak_dir/full_${project}_${ymd}.tgz $root_name
	}
done

# 备份nginx配置文件
[ -d /usr/local/nginx ] && {
	cd /usr/local/nginx
	tar zcf $web_bak_dir/nginx_conf_${HOSTNAME}_${ymd}.tgz conf
}

# 备份云支付官网
[ -d $web_dir/www.ipaye.cn ] && {
	cd $web_dir
	tar zcf $web_bak_dir/full_www.ipaye.cn_${ymd}.tgz www.ipaye.cn
}

# 删除过期备份
find $web_bak_dir -maxdepth 1 -type f \( -name "full_*" -o -name "nginx_conf_*" -o -name "inc_update_*" \) -mtime +14 -exec rm -f {} \;
find $web_bak_dir -maxdepth 1 -type d -name "update_*" -mtime +14 -exec rm -rf {} \;
