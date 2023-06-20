# Collection of handy tools

# k9s
download_k9s=$(curl -sL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.assets[].browser_download_url' | grep k9s_Linux_amd64.tar.gz)
wget $download_k9s -O k9s.tar.gz
tar -xzf k9s.tar.gz --exclude='LICENSE' --exclude='READ.md'
ls -lF

./k9s
