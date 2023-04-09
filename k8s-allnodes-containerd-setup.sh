#! /bin/bash -e
# 1- Install the container runtime 

# a- Forwarding IPv4 and letting iptables see bridged traffic 

# enable the kernel modules overlay and br_netfilter
sudo modprobe overlay
sudo modprobe br_netfilter
# make it permanent which will enable them during system boot
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# create the sysctl params required and make them persist
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
# applying the sysctl without reboot
sudo sysctl --system

# b- Turning off the swapp 

sudo swapoff -a
# make it persist 
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Download the latest version of containerd 
containerd_version=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/v//')
wget https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-${containerd_version}-linux-amd64.tar.gz

# Installing the latest version of runc 
runc_version=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget https://github.com/opencontainers/runc/releases/download/${runc_version}/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# Download the latest version of the CNI 
cni_version=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget https://github.com/containernetworking/plugins/releases/download/${cni_version}/cni-plugins-linux-amd64-${cni_version}.tgz

# target installation directory for the CNI plugin 
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-${cni_version}.tgz

# creating the containerd folder and a default configuration 
sudo mkdir -p /etc/containerd/
containerd config default | sudo tee /etc/containerd/config.toml

# enabling SystemdCgroup 
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# downloading the servicefile to manage containerd via systemd 
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service

# reloading the systemd manager 
sudo systemctl daemon-reload
sudo systemctl start containerd
sudo systemctl enable containerd

# 2- Installing Kubernetes Package 

# installing dependencies
sudo apt install apt-transport-https ca-certificates curl -y
# adding the kubernetes repp 
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
#update and install 
sudo apt update
sudo apt install kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl