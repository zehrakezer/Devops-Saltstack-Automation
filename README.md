# Kartaca SaltStack Automation

Bu proje, Kartaca'nın "Çekirdekten Yetişenler" programı kapsamında verilen görevi yerine getirmek için oluşturulmuştur. SaltStack kullanılarak Ubuntu 24.04 ve Debian 12 sunucularında otomatik sistem yapılandırmaları gerçekleştirilmiştir.

## İçerik

Bu repo aşağıdaki dosya ve dizinleri içerir:


## Özellikler

### Ortak Yapılandırmalar (Ubuntu 24.04 & Debian 12)

- `kartaca` adında kullanıcı oluşturma (UID/GID: 2025, shell: `/bin/bash`)
- Kullanıcıya parola yazmadan `sudo apt` izni
- Timezone: `Europe/Istanbul`
- Hostname: `kartaca1.local`
- Gerekli ağ araçlarının kurulumu: `htop`, `tcptraceroute`, `ping`, `dig`, `iostat`, `mtr`
- `/etc/hosts` dosyasına `kartaca1.local` girişi
- IP Forwarding aktif edilmesi

### Ubuntu 24.04 Ek İşlemleri

- Docker kurulumu
- WordPress için 3 replikalı Docker container kurulumu
- HAProxy kurulumu ve HTTPS isteklerini round-robin ile yönlendirme

### Debian 12 Ek İşlemleri

- Nginx kurulumu ve servisin etkinleştirilmesi
- PHP ve WordPress için gerekli yapılandırmalar
- WordPress arşivinin indirilip kurulum dizinine çıkarılması
- `nginx.conf` güncellenince servisin yeniden başlatılması
- `wp-config.php` dosyasının dinamik olarak yapılandırılması
- WordPress Key Generator ile otomatik `secret` oluşturulması
- Self-signed SSL sertifikası oluşturulması
- Her ayın ilk günü Nginx'i yeniden başlatan `cron` görevi
- Nginx loglarını saatlik döndüren `logrotate` yapılandırması

## Kullanım

Salt master üzerinden aşağıdaki komutları uygulayın:

```bash
# Dizine girin
$ git https://github.com/zehrakezer/Devops-Saltstack-Automation.git
$ cd Devops-Saltstack-Automation

# Dosyaları doğru dizinlere kopyalayın
$ cp -r files /srv/salt/
$ cp kartaca-wordpress.sls /srv/salt/kartaca-wordpress.sls
$ cp kartaca-pillar.sls /srv/pillar/kartaca-pillar.sls

# Test edin
$ salt "*" test.ping

# State dosyasını uygulayın
$ salt "*" state.sls kartaca-wordpress
