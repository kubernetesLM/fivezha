include:
  - script.base
vpn-sh:
  file.recurse:
    - name: /data/script
    - source: salt://script/vpn
    - file_mode: 755
    - onlyif: test -d /data/script
