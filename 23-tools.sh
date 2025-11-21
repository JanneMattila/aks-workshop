# Collection of handy tools

# k9s
# https://github.com/derailed/k9s/
download_k9s=$(curl -sL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.assets[].browser_download_url' | grep k9s_Linux_amd64.tar.gz)
wget $download_k9s -O k9s.tar.gz
tar -xzf k9s.tar.gz --exclude='LICENSE' --exclude='README.md'
rm k9s.tar.gz
ls -lF

./k9s

# aks-node-viewer
# https://github.com/Azure/aks-node-viewer
download_aks_node_viewer=$(curl -sL https://api.github.com/repos/Azure/aks-node-viewer/releases/tags/v0.0.2-alpha | jq -r '.assets[].browser_download_url' | grep aks-node-viewer_Linux_x86_64)
wget $download_aks_node_viewer -O aks-node-viewer
ls -lF
chmod +x aks-node-viewer

./aks-node-viewer -disable-pricing -resources cpu,memory
