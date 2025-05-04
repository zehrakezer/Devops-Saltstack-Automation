update_wordpress:
  file.replace:
    - name: /var/www/html/wp-config.php
    - pattern: "define\\('DB_NAME', '.*'\\);"
    - repl: "define('DB_NAME', 'wordpress');"

update_wordpress:
  file.replace:
    - name: /var/www/html/wp-config.php
    - pattern: "define\\('DB_USER', '.*'\\);"
    - repl: "define('DB_USER', 'wordpress');"

update_wordpress:
  file.replace:
    - name: /var/www/html/wp-config.php
    - pattern: "define\\('DB_PASSWORD', '.*'\\);"
    - repl: "define('DB_PASSWORD', 'wordpress');"


fetch_wp_salts:
  cmd.run:
    - name: curl -s https://api.wordpress.org/secret-key/1.1/salt/ -o /tmp/wp-salts.php

remove_old_wp_keys:
  cmd.run:
    - name: |
        sed -i '/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d' /opt/wordpress/wp-config.php
    - require:
        - cmd: fetch_wp_salts

inject_wp_salts:
  cmd.run:
    - name: cat /tmp/wp-salts.php >> /opt/wordpress/wp-config.php
    - require:
        - cmd: remove_old_wp_keys
