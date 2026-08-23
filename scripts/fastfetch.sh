#!/bin/env bash

install_fastfetch() { 
  sudo apt remove fastfetch || true
  curl -LO https://github.com/fastfetch-cli/fastfetch/releases/download/2.66.0/fastfetch-linux-amd64.deb || echo 'File download failed'
  sudo apt install ./fastfetch-linux-amd64.deb || echo 'Install failed'
}
install_fastfetch
fastfetch
