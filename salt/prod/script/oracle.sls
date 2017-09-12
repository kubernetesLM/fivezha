include:
  - script.base
oracle-sh:
  file.recurse:
    - name: /data/script
    - source: salt://script/oracle
    - file_mode: 755
    - onlyif: test -d /data/script
