web_sh:
  file.recurse:
    - name: /data/script
    - source: salt://script/web
    - file_mode: 755
    - onlyif: test -d /data/script
