#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <subnet>"
    exit 1
fi
echo "This script initialize a master with kubeadm"
echo "Removing old configuration files ..."
sudo kubeadm reset -f
echo "Removing old ${HOME}/.kube/ ..."
sudo rm -rf "${HOME}/.kube/"
echo "Disabling swap ..."
sudo swapoff -a

echo "Initializing kubeadm ..."
#./bypass.sh &
rm -f kubeadm-init.txt
sudo kubeadm init --pod-network-cidr=$1 | tee kubeadm-init.txt

if [ $? -ne 0 ]; then
    echo "kubeadm init failed, exiting ..."
    exit 1
fi
echo "Copying configuration files ..."
sudo mkdir -p "${HOME}/.kube"
echo "Copying admin.conf to ${HOME}/.kube/config"
sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
sudo chown $(id -u):$(id -g) ${HOME}/.kube/config

export KUBECONFIG=${HOME}/.kube/config

echo "Installing flannel ..."
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
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


# Parallelamente, mentre kubeadm init è in esecuzione, in particolare mentre aspetta kubelet, eseguire il comando:
# $ sudo swapoff -a && sudo chmod 755 /var/lib/kubelet/ 


#Se alla fine di kubeadm init viene restituito l'errore: x509: certificate signed by unknown authority
#Eseguire il comando:
# $ sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
