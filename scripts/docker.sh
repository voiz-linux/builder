curl -sf https://raw.githubusercontent.com/voiz-linux/builder/main/scripts/fastfetch.sh | bash

curl -L https://github.com/indigo-dc/udocker/releases/download/1.3.17/udocker-1.3.17.tar.gz -o udocker-1.3.17.tar.gz
tar -xzf udocker-1.3.17.tar.gz
cd udocker-1.3.17
./udocker --version

curl -sf https://raw.githubusercontent.com/voiz-linux/builder/main/scripts/prepare.sh | bash
