#!/bin/bash

if [ ! -e /etc/apt/sources.list.orig ];
  mv /etc/apt/sources.list /etc/apt/sources.list.orig
  cat >/etc/apt/sources.list <<EOF
###### Debian Main Repos
deb http://ftp.uk.debian.org/debian/ stretch main non-free

###### Debian Update Repos
#deb http://ftp.uk.debian.org/debian/ stretch-proposed-updates main non-free
deb http://security.debian.org/ stretch/updates main non-free
EOF
fi

apt-get update
apt-get install openssh-server vim git rsync

mkdir -p ~/.ssh
cd ~/.ssh
if [ ! -e authorized_keys ];
  if [ -e authorized_keys2 ];
    mv authorized_keys2 authorized_keys
  fi
  touch authorized_keys
fi

grep -qim 1 "# Anth 2016" authorized_keys || cat >>authorized_keys <<EOF

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQDB2YFm+WQlsLzXlYAcnBGMYAwnYb+cTH76vvJu8K4BoC9EgO1XZed2aaM9AASLf3m7n8IS7jnaMLOd5zrI3eM2odBR3EpiMFLeFvvSyx0Jwam+mS7SmNR6RIE9sbSYk3+puj6hW+Z8ynCa8gS1oIy4G/rMLXcwqg1wdegaP08nCaiHM4vSSTnsoIsoe8pdAuunzh9pZ0eLWUAHo/gGG+YDdjN8Z+NtRhuU57pRK1+e2hE7uzfqSeqsel/8fjXzpML0fh8uxBkoXcW0NnJEPO1A4bjaOk2R2IhoJGPxofcq7J4sGCK0xqOUGi8P79CQOcMkMCpvRexd6y0Fx1qCjspJvhj1egWSEoFUsE5ETUxORSSzUFXKp5yp9dSro4jqev/YYyMvo7QpKz+SJ4QCOLU/fBTYaUKVqiSX4ilc2jT32aR1c51lR1JCPGK+nGL5z17IFDDVR2fXZBWsjEJdtHA46lez5CD6EsiloVEBSggFWmLSx6tDNRvBwejM8K21pcasLlIfdx2rFMfyjoivuVOE4pBQlxsPLIzVOnpCXciLhVdOK0nE7KNnHGkEuUbXS/4ef12n7qb4mk/IuLyQ4blimqRn8UAU7M+6/T6vp8Ge02N5Ib/xZF81+pIcfCS2ouhTTMsD4xA44WWkldCmPgeUlOCjBFg0khXxujOVnKyHwiAlY6JDMT0ov8c1o64uXCF12BU8kc9aVCASrhT2gCH9l9FGoK/PKE+AdTveRa827ZjH3FGAmEFYizDiUrH9l4WGKu4vn2SCfoQ22wfmPoPKhqLWShK+ezgGcq3/eV/q2bzuyop+5UYT06UB48J91/pYTJWUy/GZDIuw956PhshulJojmAbqXCU3AJczVk8vYLp9fB5MjDPYglZAgw6pA/fPX0K4XuqIrL8hFPH+RQJDy+Pz03BkF/k4e+BdMxBpvRRSegQeHiWgyXhWkLOkYdLZQhKfgh0i8D3YKXsKvxVIsYmt68PEFr20OLS+Rcceu43cLqNVU0UlLCDZE1UYq/GSOsErTCwzWnNueI/aSAn5oTZjpQKO6OgDw8ipfr1V/eqIvXfVdZDbDXBYAVNjvBab2fVQg1tANpLHWHV4WjhBNBEaeMymTFlIq98e1u5JDP0twDfWxy7Vsm10z9RViSVUSrhWe2EB1VST44h/TFiVz1VLymTCSaMJ+Pf6/CNdD9I/zasrZ8McD8VwWuj6KFllgGndb8HYnnUYT2t5+zOEV4j7EMBrFW5LxB2SPNo/ZkLw13MuIfqbtQWnbgXGb8PBrGI5a9gYIWQYFKwjbdWefG6IP9L6kegKsVHyhk4CjvIGsFhMG7IqKntByxeEniuMFvcwFPzi1OohjcNhEjbr
# Anth 2016
EOF

grep -qim 1 "# Dirvish 2013" authorized_keys || cat >>authorized_keys <<EOF

command="rsync --server --sender -vlHogDtprx --numeric-ids . /",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDjFVYoEUGflfJYlZOHJKuv0AsaBwjA4QxNFVnmVEwcIoeKmZOZCjIciTeeJFG1kUjM7iEotJh9mhK04Gxn2DYt1qUhEk12bJ2XMzrCyHZlg0eyr3SQlNocIcIQDJ/wz0MQr+sUwA4wNQQsA8F6QL+e6UmHohu2VYRZrhIXOVkwnP+f68nTTsyvfG1hcUFg4gWKxDd6ppvbHwVzCBxvp3NO+c1Mv8sQh7OqdqCPcemYX/y0H0MQ4xQfl7hm+YUkohu8TdiAuSF7ZS1kJjbnyqTlxwDbFt3DbgwP9W0ApxIqNE7NbWlVam3+qLsMeflXoMni+obfvHoYpIWqP3spBk6h dirvish-2013
# Dirvish 2013
EOF

grep -qim 1 "# 2015-01-14" authorized_keys || cat >>authorized_keys <<EOF

ssh-rsa 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
# 2015-01-14 DLS
EOF

cd
if [ ! -e scripts ];
  git clone https://github.com/Anthchirp/scripts.git
else;
  cd scripts
  git pull
fi
