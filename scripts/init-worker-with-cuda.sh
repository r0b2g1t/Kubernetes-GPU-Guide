#!/bin/sh
# Following arguments are necessary:
# 1. -> token ,  e.g. "f38242.e7f3XXXXXXXXe231e"
# 2. -> IP:port of the master
# 3. -> ca-cert-hash of the master, e.g. "sha256:ad9425abcf02e4d8a476da11f3672d5bc7255cd7494a4fdd4f8c0092a13f9737"

echo "The following token will be used: ${1}"
echo "The master nodes IP:Port is: ${2}"
echo "The following master node ca cert hash will be checked: ${3}"

sudo bash -c 'apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF'

sudo apt-get update
sudo apt-get install -y docker.io
sudo apt-get install -y --allow-unauthenticated kubelet kubeadm kubectl kubernetes-cni
sudo groupadd docker
sudo usermod -aG docker $USER

# Install Cuda and Nvidia driver
sudo apt-get install -y linux-headers-$(uname -r)
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update
sudo apt-get install -y nvidia-375
sudo apt-get install -y nvidia-cuda-dev nvidia-cuda-toolkit nvidia-nsight

echo 'In order to use cudnn, you will need to install it seperadly. \nVisit https://developer.nvidia.com/cudnn'

sudo systemctl enable docker && systemctl start docker
sudo systemctl enable kubelet && systemctl start kubelet

echo 'You might need to reboot / relogin to make docker work correctly'

for file in /etc/systemd/system/kubelet.service.d/*-kubeadm.conf
do
    echo "Found ${file}"
    FILE_NAME=$file
done

echo "Chosen ${FILE_NAME} as kubeadm.conf"
sudo sed -i '/^ExecStart=\/usr\/bin\/kubelet/ s/$/ --feature-gates="Accelerators=true"/' ${FILE_NAME}

sudo systemctl daemon-reload
sudo systemctl restart kubelet

sudo kubeadm join --token $1 $2 --discovery-token-ca-cert-hash $3
