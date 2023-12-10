#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o xtrace

# pass is for oath2tool.sh
apt-fast install msmtp-mta pass
cp oauth2tool.sh ~/bin/
cp oauth2.py ~/bin/
sudo cp msmtprc /usr/local/etc/msmtprc
sudo ln -s /usr/local/etc/msmtprc /etc/msmtprc
touch /var/log/msmtp
chmod ugo+w /var/log/msmtp
sudo cp .offlineimaprc /root/
cp offlineimap.py ~/bin/
