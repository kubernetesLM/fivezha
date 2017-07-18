base:
  '*':
    - init

prod:
  'node*':
    - script.oracle
  'host*':
    - script.web
