# OpenVPN sample scripts

Ubuntu 20.04, Ubuntu 22.0x LTS 에서 작동했던 OpenVPN 예제 스크립트입니다.

쉽게 도입하고 빠르게 만들어 사용하고 싶은 분들이 있다면 사용하시기 좋을 것 같습니다.


# 시작

```sh
# 필수 패키지를 설치합니다.
sudo apt-get install openvpn easy-rsa

# 기본적인 OpenVPN(RSA, 사용자/비밀번호 인증) 서버설정을 합니다
#   e.g. ./install-easy-rsa-and-generate-server-key.sh domain.org
./install-easy-rsa-and-generate-server-key.sh [도메인]
```

# 서버 작동 테스트

```sh
sudo systemctrl start openvpn@server
sudo systemctrl status openvpn@server
```

# 클라이언트 ovpn 파일 배포하기

```sh
# 현재 시스템에 등록되어 있는 사용자를 파라미터로 입력하세요.
#   e.g. etc/openvpn/easy-rsa/generate-client-key.sh ubuntu
sudo /etc/openvpn/easy-rsa/generate-client-key.sh [사용자명]

# 키파일 스토어
ls -al /etc/openvpn/client/client/keys/[사용자명]

# [사용자].ovpn 스토어
ls -al /etc/openvpn/client/ovpn
```

# Todo

  - [ ] install-easy-rsa-and-generate-server-key.sh 작성완료
