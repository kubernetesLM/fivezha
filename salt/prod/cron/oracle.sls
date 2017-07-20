oracle_bak:
  cron.present:
    - name: /data/script/oracle_bak.sh &> /dev/null
    - user: oracle
    - minute: 0
    - hour: 2
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'
    - onlyif: id oracle
oracle_rsync:
  cron.present:
    - name: /data/script/oracle_rsync.sh &> /dev/null
    - user: root
    - minute: 0
    - hour: 3
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'
