#ubuntu
{% if grains['os'] == 'Ubuntu' and grains['osrelease'].startswith('24.04') %}

user_kartaca:
  user.present:
    - name: kartaca
    - shell: /bin/bash
    - home: /home/krt
    - uid: 2025
    - gid: 2025
    - password: {{ pillar['password'] }}

sudo_privileges:
  file.managed:
    - name: /etc/sudoers.d/salt_sudo
    - source: salt://files/sudo-privileges
    - user: root
    - group: root
    - attrs: i
    - mode: 0644

Europe/Istanbul:
  timezone.system



system:
  network.system:
    - enabled: True
    - hostname: kartaca1.local
    - apply_hostname: True

packages:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - iputils-ping
      - dnsutils
      - sysstat
      - mtr

ip_forward:
  sysctl.present:
    - name: net.ipv4.ip_forward 
    - value: 1
    - config: /etc/sysctl.conf


kartaca_host:
  host.present:
    - ip: {{ grains['ipv4'][0] }}
    - names:
      - kartaca1.local



include:
  - files.docker_install

docker_service:
  service.running:
    - name: docker
    - enable: True

/home/docker:
  file.directory:
    - user: root
    - group: root
    - mode: 755

    
docker_file:
  file.managed:
    - name: /home/docker/docker-compose.yml
    - source: salt://files/docker-compose.yml
    - user: root
    - group: root
    - mode: 644

start_wordpress_stack:
  cmd.run:
    - name: docker compose up -d
    - cwd: /home/docker/
    - require:
      - file: docker_file
      - service: docker_service


create_haproxy_dir:
  file.directory:
    - name: /etc/haproxy
    - mode: 755

haproxy_config:
  file.managed:
    - name: /etc/haproxy/haproxy.cfg
    - source: salt://files/haproxy.cfg
    - mode: 644
    - user: root
    - group: root

start_haproxy:
  cmd.run:
    - name: >
        docker run -d --name haproxy
        -p 80:80
        -v /etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
        haproxy:latest
    - unless: docker ps --format '{{"{{.Names}}"}}' | grep -w haproxy
    - require:
        - file: haproxy_config

{% endif %}




#Debian
{% if grains['os'] == 'Debian' and grains['osrelease'] == '12' %}

user_kartaca:
  user.present:
    - name: kartaca
    - shell: /bin/bash
    - home: /home/krt
    - uid: 2025
    - gid: 2025
    - password: {{ pillar['password'] }}

sudo_privileges:
  file.managed:
    - name: /etc/sudoers.d/salt_sudo
    - source: salt://files/sudo-privileges
    - user: root
    - group: root
    - attrs: i
    - mode: 0644

Europe/Istanbul:
  timezone.system



system:
  network.system:
    - enabled: True
    - hostname: kartaca1.local
    - apply_hostname: True

packages:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - iputils-ping
      - dnsutils
      - sysstat
      - rsync
      - mtr
      - php
      - php-fpm
      - php8.3-fpm
      - php-mysql
      - php-gd
      - php-xml

ip_forward:
  sysctl.present:
    - name: net.ipv4.ip_forward 
    - value: 1
    - config: /etc/sysctl.conf


kartaca_host:
  host.present:
    - ip: {{ grains['ipv4'][0] }}
    - names:
      - kartaca1.local



nginx:
  pkg.installed:
    - name: nginx

nginx_clean_restart:
  cmd.run:
    - name: |
        if lsof -i :80 >/dev/null; then
          echo "Port 80 in use. Restarting nginx..."
          systemctl stop nginx || true
          sleep 2
        fi
    - shell: /bin/bash
    - require:
      - pkg: nginx

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - require:
      - pkg: nginx
      - cmd: nginx_clean_restart
    - watch:
      - file: /etc/nginx/nginx.conf

wordpress_dir:
  file.directory:
    - name: /var/www/html
    - makedirs: True

download_wordpress:
  cmd.run:
    - name: wget https://wordpress.org/latest.tar.gz -O /var/www/html/latest.tar.gz
    - creates: /var/www/html/latest.tar.gz
    - require:
        - file: wordpress_dir

extract_wordpress:
  cmd.run:
    - name: tar -zxvf latest.tar.gz
    - cwd: /var/www/html
    - onlyif: test -f /var/www/html/latest.tar.gz
    - require:
        - cmd: download_wordpress


move_wordpress_files:
  cmd.run:
    - name: rsync -a wordpress/ .
    - cwd: /var/www/html
    - onlyif: test -d /var/www/html/wordpress
    - require:
        - cmd: extract_wordpress
        - pkg: packages

set_permissions:
  cmd.run:
    - name: chown -R www-data:www-data * && chmod -R 755 *
    - cwd: /var/www/html/wordpress
    - onlyif: test -d /var/www/html/wordpress

rename_wp_config:
  cmd.run:
    - name: mv wp-config-sample.php wp-config.php
    - cwd: /var/www/html/wordpress
    - onlyif: test -f /var/www/html/wordpress/wp-config-sample.php
    - unless: test -f /var/www/html/wordpress/wp-config.php

update_wordpressname:
  file.replace:
    - name: /var/www/html/wordpress/wp-config.php
    - pattern: "define\\('DB_NAME', '.*'\\);"
    - repl: "define('DB_NAME', 'wordpress');"

update_wordpressuser:
  file.replace:
    - name: /var/www/html/wordpress/wp-config.php
    - pattern: "define\\('DB_USER', '.*'\\);"
    - repl: "define('DB_USER', 'wordpress');"

update_wordpresspassword:
  file.replace:
    - name: /var/www/html/wordpress/wp-config.php
    - pattern: "define\\('DB_PASSWORD', '.*'\\);"
    - repl: "define('DB_PASSWORD', 'wordpress');"

fetch_wp_salts:
  cmd.run:
    - name: curl -s https://api.wordpress.org/secret-key/1.1/salt/ -o /tmp/wp-salts.php

remove_old_wp_keys:
  cmd.run:
    - name: sed -i '/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d' /var/www/html/wordpress/wp-config.php
    - require:
      - cmd: fetch_wp_salts

inject_wp_salts:
  cmd.run:
    - name: cat /tmp/wp-salts.php >> /var/www/html/wordpress/wp-config.php
    - require:
        - cmd: remove_old_wp_keys

create_ssl:
  cmd.run:
    - name: >
        openssl req -x509 -nodes -days 365 -newkey rsa:2048
        -keyout /etc/ssl/private/nginx-selfsigned.key
        -out /etc/ssl/certs/nginx-selfsigned.crt
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=MyCompany/CN=kartaca1.local"

update_nginxconf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://files/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: nginx_service

cron_package:
  pkg.installed:
    - name: cron


restartnginx_cron:
  cron.present:
    - name: "/bin/systemctl restart nginx"
    - user: root
    - minute: 0
    - hour: 0
    - daymonth: 1
    - require:
      - pkg: cron_package

nginx_logrotate:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://files/logrotate
    - user: root
    - mode: 644

{% endif %}
