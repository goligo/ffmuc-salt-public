#
# knot-recursor
#

knot-resolver-repo:
  pkgrepo.managed:
{% if grains.oscodename in ["stretch"] %}
    - name: "deb http://download.opensuse.org/repositories/home:/CZ-NIC:/knot-resolver-latest/Debian_9.0/ /"
    - key_url: https://download.opensuse.org/repositories/home:CZ-NIC:knot-resolver-latest/Debian_9.0/Release.key
{% elif grains.oscodename in ["buster"] %}
    - name: "deb http://download.opensuse.org/repositories/home:/CZ-NIC:/knot-resolver-latest/Debian_10/ /"
    - key_url: https://download.opensuse.org/repositories/home:CZ-NIC:knot-resolver-latest/Debian_10/Release.key
{% else %}
    - name: "deb http://download.opensuse.org/repositories/home:/CZ-NIC:/knot-resolver-latest/Debian_Next/ /"
    - key_url: https://download.opensuse.org/repositories/home:CZ-NIC:knot-resolver-latest/Debian_Next/Release.key
{% endif %}
    - clean_file: True
    - file: /etc/apt/sources.list.d/knot-resolver.list

knot-resolver:
  pkg.installed:
    - refresh: True
    - require:
      - pkgrepo: knot-resolver-repo
  service.running:
    - name: kresd@1
    - enable: True
    - restart: True
    - require:
      - file: knot-socket-config
      - file: /etc/knot-resolver/kresd.conf
    - watch:
      - file: /etc/knot-resolver/kresd.conf
      - cmd: systemd-reload

systemd-reload:
  cmd.run:
   - name: systemctl --system daemon-reload
   - onchanges:
     - file: knot-socket-config

/etc/systemd/system/kresd@1.service.d:
  file.absent

knot-socket-config:
  file.managed:
    - name: /etc/systemd/system/kresd.socket.d/override.conf
    - source: salt://knot-resolver/kresd.socket
    - template: jinja
    - makedirs: True
  service.running:
    - name: kresd.socket
    - enable: True
    - restart: True
    - require:
      - file: /etc/systemd/system/kresd.socket.d/override.conf
    - watch:
      - file: /etc/systemd/system/kresd.socket.d/override.conf

/etc/knot-resolver/kresd.conf:
  file.managed:
    - source: salt://knot-resolver/kresd.conf