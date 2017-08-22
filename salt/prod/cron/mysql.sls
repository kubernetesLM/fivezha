mysql_bak:
  cron.present:
    - name: /data/script/mysql_bak.sh &> /dev/null
    - user: root
    - minute: 0
    - hour: 2
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'

mysql_rsync:
  cron.present:
    - name: /data/script/mysql_rsync.sh &> /dev/null
    - user: root
    - minute: 0
    - hour: 3
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'
