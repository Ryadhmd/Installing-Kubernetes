#! /bin/bash -e
#1- Install the container runtime

#a- Set up networking and forwarding

#Enable the necessary kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

#Make them load on system boot
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

#Set up sysctl parameters for networking
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
#Apply the sysctl settings
sudo sysctl --system

#b- Install and configure the container runtime

#Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^.∗.∗$/#\1/g' /etc/fstab
sudo swapoff -a

#Download and install containerd
containerd_version=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/v//')
wget https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-${containerd_version}-linux-amd64.tar.gz

#Download and install runc
runc_version=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget https://github.com/opencontainers/runc/releases/download/${runc_version}/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

#Download and install CNI plugins
cni_version=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget https://github.com/containernetworking/plugins/releases/download/${cni_version}/cni-plugins-linux-amd64-${cni_version}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-${cni_version}.tgz

#Create the containerd configuration file and enable SystemdCgroup
sudo mkdir -p /etc/containerd/
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

#Download and install the containerd systemd service file
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service

#Reload the systemd manager and start the container runtime
sudo systemctl daemon-reload
sudo systemctl start containerd
sudo systemctl enable containerd

#2- Install Kubernetes Package

#Install necessary dependencies
sudo apt install apt-transport-https ca-certificates curl -y

#Add the Kubernetes apt repository and install the Kubernetes packages
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet