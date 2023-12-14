#!/bin/bash
echo "This script initialize a master with kubeadm"
echo "and must be run as root and is intended to be run on a fresh install of Arch Linux"

echo "Disabling swap ..."
sudo swapoff -a

echo "Removing old configuration files ..."
sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/manifests/etcd.yaml
sudo rm -rf /var/lib/etcd
sudo rm -rf ${HOME}/.kube

read -p "Enter the correct IP and subnet mask of the current LAN (example: 192.168.0.0/16): " LAN_SUBNET
echo "Initializing kubeadm ..."
sudo kubeadm init --pod-network-cidr=${LAN_SUBNET}

if [ $? -ne 0 ]; then
    echo "kubeadm init failed, exiting ..."
    exit 1
fi

echo "Copying configuration files ..."
mkdir -p "${HOME}/.kube"
sudo cp -i /etc/kubernetes/admin.conf "${HOME}/.kube/config"
sudo chown "$(id -u):$(id -g)" "${HOME}/.kube/config"

echo "Installing flannel ..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo "Done, you can now join other nodes to the cluster"



# Se non configurato correttamente, il comando kubectl non funziona, restituendo l'errore:
# The connection to the server localhost:8080 was refused - did you specify the right host or port?
# Per risolvere, eseguire il comando:
# export KUBECONFIG=/etc/kubernetes/admin.conf
# Per rendere la modifica permanente, aggiungere la riga al file ~/.bashrc
# Per verificare che il comando funzioni, eseguire il comando:
# kubectl get nodes
# Deve restituire un output simile a questo:
# NAME     STATUS   ROLES                  AGE   VERSION
# arch     Ready    control-plane,master   10m   v1.21.1
# worker   Ready    <none>                 10m   v1.21.1
# Se non funziona, verificare che il file /etc/kubernetes/admin.conf esista e che contenga le credenziali corrette
# Un problema noto è il contesto sbagliato, per cambiare contesto eseguire:
# $ kubectl config current-context
# per avere un idea dei contesti disponibili e di conseguenza verificare che il contesto corrente sia quello corretto
# Per vedere il contesto corrente, eseguire:
# $ kubectl config view
# Per cambiare contesto, eseguire:
# $ kubectl config use-context <context-name>
