#
# SSL Certificates
#

openssl:
  pkg.installed:
    - name: openssl


c_rehash:
  cmd.wait:
    - name: /usr/bin/c_rehash >/dev/null 2>/dev/null
    - watch: []


# FFHO internal CA
/etc/ssl/certs/ffho-cacert.pem:
  file.managed:
    - source: salt://certs/ffho-cacert.pem
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - cmd: c_rehash


# StartSSL Class1intermediate CA certificate
/etc/ssl/certs/StartSSL_Class1_CA.pem:
  file.managed:
    - source: salt://certs/StartSSL_Class1_CA.pem
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - cmd: c_rehash


# StartSSL Class2 intermediate CA certificate
/etc/ssl/certs/StartSSL_Class2_CA.pem:
  file.managed:
    - source: salt://certs/StartSSL_Class2_CA.pem
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - cmd: c_rehash


{% set certs = {} %}

# Are there any certificates defined or referenced in the node pillar?
{% set node_config = salt['pillar.get']('nodes:' ~ grains['id']) %}
{% for cn, cert_config in node_config.get ('certs', {}).items () %}
  {% set pillar_name = None %}

  {# "cert" and "privkey" provided in node config? #}
  {% if 'cert' in cert_config and 'privkey' in cert_config %}
    {% set pillar_name = 'nodes:' ~ grains['id'] ~ ':certs:' ~ cn %}

  {# <cn> only referenced in node config and cert/privkey stored in "cert" pillar? #}
  {% elif cert_config.get ('install', False) == True %}
    {% set pillar_name = 'cert:' ~ cn %}
  {% endif %}

  {% if pillar_name != None %}
    {% do certs.update ({ cn : pillar_name }) %}
  {% endif %}
{% endfor %}

# Are there any cert defined or referenced for this node or roles of this node?
{% set node_roles = node_config.get ('roles', []) %}
{% for cn, cert_config in salt['pillar.get']('cert', {}).items () %}
  {% for role in cert_config.get ('apply', {}).get ('roles', []) %}
    {% if role in node_roles %}
      {% do certs.update ({ cn : 'cert:' ~ cn }) %}
    {% endif %}
  {% endfor %}
{% endfor %}

# Install found certificates
{% for cn, pillar_name in certs.items () %}
/etc/ssl/certs/{{ cn }}.cert.pem:
  file.managed:
    {% if salt['pillar.get'](pillar_name ~ ':cert') == "file" %}
    - source: salt://certs/certs/{{ cn }}.cert.pem
    {% else %}
    - contents_pillar: {{ pillar_name }}:cert
    {% endif %}
    - user: root
    - group: root
    - mode: 644

/etc/ssl/private/{{ cn }}.key.pem:
  file.managed:
    - contents_pillar: {{ pillar_name }}:privkey
    - user: root
    - group: ssl-cert
    - mode: 440
{% endfor %}