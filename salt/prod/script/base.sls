base-sh:
  file.recurse:
    - name: /data/script
    - source: salt://script/base
    - file_mode: 755
    - onlyif: test -d /data/script
