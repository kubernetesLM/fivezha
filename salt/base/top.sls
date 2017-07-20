base:
  '*':
    - init

prod:
  '*web':
    - jdk
    - script.web
    - cron.web
  '*web_test':
    - jdk
    - script.web
  '*oracle':
    - script.oracle
    - cron.oracle
  '*oracle_test':
    - script.oracle