| ⛔ 위험. 아직 완성되지 않은 쉘 스크립트입니다! 실행 시 당신의 시스템이 망가질 수 있습니다. |
|:---:|

# OpenVPN

OpenVPN 설정/설치 쉘스크립트입니다.

ubuntu 22.x 에서 정상 작동합니다.


## How to install?

```sh
git clone https://github.com/try-to-awakening/sh.git

cd open-vpn

chmod +x ./install.sh

# 쉘스크립트 최상단 변수를 자신의 시스템에 알맞게 변경하세요.(옵션)
vim install.sh 

# 도메인이나 hostname을 파라미터로 입력해주세요
sudo ./install.sh www.mydomain.com
```

## How to add new user?

```sh
cd open-vpn/easy-rsa

chmod +x ./generate-client-key.sh

sudo ./generate-client-key.sh "username"
```

`/etc/openvpn/client/easyrsa/{username}` 경로에 사용자의 OpenVPN 접속 프로필을 확인하세요.