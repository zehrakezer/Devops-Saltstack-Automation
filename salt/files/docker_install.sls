# /srv/salt/files/docker_install.sls

install_prerequisites:
  pkg.installed:
    - pkgs:
      - ca-certificates
      - curl
      - gnupg
      - lsb-release

add_docker_gpg_key:
  cmd.run:
    - name: |
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    - unless: test -f /etc/apt/keyrings/docker.gpg

add_docker_repository:
  file.managed:
    - name: /etc/apt/sources.list.d/docker.list
    - contents: |
        deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu {{ grains['lsb_distrib_codename'] }} stable
    - mode: 644
    - user: root
    - group: root
    - require:
      - cmd: add_docker_gpg_key

apt_update:
  cmd.run:
    - name: apt-get update
    - require:
      - file: add_docker_repository

install_docker:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
    - require:
      - cmd: apt_update

enable_and_start_docker:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: install_docker
