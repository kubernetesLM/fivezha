/root/.ssh:
  file.directory:
    - dir_mode: 700

/root/.ssh/id_dsa:
  file.managed:
    - mode: 600
    - source: salt://sshkey/backup
