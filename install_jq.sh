mkdir -p ~/.local/bin
curl -Lo ~/.local/bin/jq https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64
chmod +x ~/.local/bin/jq

# echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
# source ~/.bashrc