prod:
  '*web':
    - script.web
    - cron.web
  'HD2_yunpay_cc,HD2_yunpay_v2,HD2_yunpay_red,HD2_yunpay_static,HD2_yunpay_admin,HD2_yunpay_credit,HD2_yunpay_flow,HD2_yunpay_site':
    - match: list
    - script.web
    - cron.web
  'E@.*web_test or E@.*web_pre or HD2_yunpay_credit_test':
    - match: compound
    - script.web
  '*oracle':
    - script.oracle
    - cron.oracle
  'E@.*db or HD2_yffs_oracle or HD2_yunpay_site':
    - match: compound
    - script.mysql
    - cron.mysql
  'HD2_yunpay_vpn':
    - script.vpn
  'PT230,PT231,PT232':
    - match: list
    - script.web
    - script.oracle
    - script.mysql
