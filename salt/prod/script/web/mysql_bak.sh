#!/bin/bash
# 导入公共变量
source /data/script/aten_vars.sh

user=root
password=password
dbs=$(mysql -u$user -p$password -Nse "show databases;" | grep -Ev "information_schema|performance_schema|mysql|test")
[ -d $mysql_bak_dir ] || mkdir -p $mysql_bak_dir
for db in $dbs
do
	mysqldump -u$user -p$password $db > $mysql_bak_dir/${db}_$ymd.sql
	find $mysql_bak_dir -maxdepth 1 -type f -name "$db*" -mtime +15 -exec rm -f {} \;
done