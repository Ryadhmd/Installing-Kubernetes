# Installing-Kubernetes

This repository serves as a cheat sheet for installing Kubernetes. 

# 1- Installing tools on all nodes: 

The k8s-allnodes-containerd-setup.sh script installs all the necessary tools to set up Kubernetes with Kubeadm. 
After running it on the control plane, simply run:

```bash
sudo kubeadm config images pull
sudo kubeadm init --apiserver-advertise-address=10.0.2.5 \
--cri-socket=unix:///var/run/containerd/containerd.sock \
--pod-network-cidr=192.168.0.0/16
``` 
# 2- Kubelet Container runtime network not ready issue

If you encounter the error "Container runtime network not ready" after successfully initializing the cluster, 
it may be due to a problem with the CNI failing to load the config. Here is a solution to fix it:

a- Download the setup CNI file

```bash
curl https://raw.githubusercontent.com/containerd/containerd/main/script/setup/install-cni \ 
| sudo tee $HOME/install-cni
```
b- Install Go 
```bash
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile
```
c- Run the installation file:
```bash
cd ~
sudo chmod +x install-cni
sudo sed -i '/CNI_COMMIT/d' install-cni
./install-cni
```

d- Finally, restart Containerd and Kubelet:
```bash
sudo systemctl restart containerd
sudo systemctl restart kubelet
```


