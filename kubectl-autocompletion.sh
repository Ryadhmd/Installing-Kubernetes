#! /bin/bash -e 

sudo apt install -y bash-completion

source /usr/share/bash-completion/bash_completion

source ~/.bashrc

echo 'source <kubectl completion bash)' >>~/.bashrc

source ~/.bashrc
