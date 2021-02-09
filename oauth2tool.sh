#!/bin/bash

set -o errexit

# Found this via https://wiki.archlinux.org/index.php/Msmtp#OAUTH2_Authentication_for_Gmail

# Joseph Harriott - Sun 04 Oct 2020

# my adaptation of  oauth2token
# -----------------------------
#  "Msmtp setup for GMail with OAuth2" - Christian Tenllado
#  https://github.com/tenllado/dotfiles/tree/master/config/msmtp

# argument: your Gmail username
# output: an unexpired access token, to be used in your  ~/.config/msmtp/config

# This script assumes that you have done the following
#
#   1. Set up your Gmail API. I did it with the Python Quickstart
#        https://developers.google.com/gmail/api/quickstart/python
#      You will receive your Client ID and your Client Secret.
#
#   2. Generated your refresh token with a preliminary run of Gmail's  oauth2.py

#        $ python2 oauth2.py --user=<yourGmail> --client_id=<yourClientID> \
#            --client_secret=<yourClientSecret --generate_oauth2_token
#
#   3. Configured your  ~/.password-store
#
#        echo <yourClientID>     | pass insert -e username@domain/GmailAPI/CID
#        echo <yourClientSecret> | pass insert -e username@domain/GmailAPI/CS
#        echo <yourRefreshToken> | pass insert -e username@domain/GmailAPI/refresh
#        echo 0                  | pass insert -e username@domain/GmailAPI/token-expire
#
#       To make it work as root as well, run:
#       sudo cp ~/.password-store /root/
#
#        Note: this script will first check if your access token is expired
#          if no, it will just grab it from your  ~/.password-store
#          if yes, it will rerun  oauth2.py  to generate a new token and expiry time
#            and save them both in your  ~/.password-store

# My ~/.msmtprc  looks like this:
#
#        defaults
#        tls	on
#        tls_trust_file	/etc/ssl/certs/ca-certificates.crt
#        logfile	~/.config/msmtp/msmtp.log
#
#        account username
#        auth oauthbearer
#        host smtp.gmail.com
#        port 587
#        from username@gmail.com
#        user username@gmail.com
#        passwordeval bash oauth2tool.sh username@gmail.com
#        # echo "test of msmtpConfig" | msmtp -a username <destination_email_address>

handle=${1}  # for use in parameter expansions

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

USERNAME=$(id -u -n)
export PASSWORD_STORE_DIR="/home/${USERNAME}/.password-store"
if [[ "${USERNAME}" == "root" ]]; then
  export PASSWORD_STORE_DIR="/root/.password-store"
fi

get_access_token() {
    # $GNULE  should point to the directory that contains your local copy of  oauth2.py

    { IFS= read -r tokenline && IFS= read -r expireline; } < \
    <(python2 ${DIR}/oauth2.py --user=${handle} \
    --client_id=$(pass $handle/GmailAPI/CID) \
    --client_secret=$(pass $handle/GmailAPI/CS) \
    --refresh_token=$(pass $handle/GmailAPI/refresh))

    token=${tokenline#Access Token: }
    expire=${expireline#Access Token Expiration Seconds: }
}

token="$(pass $handle/GmailAPI/token)"
expire="$(pass $handle/GmailAPI/token-expire)"
now=$(date +%s)

if [[ $token && $expire && $now -lt $((expire - 60)) ]]; then
    echo $token
else
    get_access_token
    echo $token | pass insert -e $handle/GmailAPI/token
    expire=$((now + expire))
    echo $expire | pass insert -e $handle/GmailAPI/token-expire
    echo $token
fi
