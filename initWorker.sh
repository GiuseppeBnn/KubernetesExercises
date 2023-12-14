#!/bin/bash
#TODO: This script is not working, it must be fixed, especially the iptables part and kuebadm join part
#This scripts initialize a worker with kubeadm
TOKEN="t1ksg1.7utuwszhlj4e43d9"
DISCOVER_SHA="sha256:3ea357ea7da8fc6c7d11731dd610ade12b1f290e858c30fb86f6a094d891c60e"
IP_MASTER="192.168.1.236:6443"


echo "Disabling swap ..."
sudo swapoff -a

echo "Removing old configuration files ..."
sudo rm -f /etc/kubernetes/pki/ca.crt /etc/kubernetes/kubelet.conf /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/manifests/etcd.yaml
sudo rm -rf /var/lib/etcd

echo "Initializing kubeadm ..."
COMMAND="sudo kubeadm join ${IP_MASTER} --token ${TOKEN} --discovery-token-ca-cert-hash ${DISCOVER_SHA}"
${COMMAND}
if [ $? -ne 0 ]; then
    echo "kubeadm join failed, exiting ..."
    echo "Retrying with resetting kubeadm and iptables ..."
    sudo kubeadm reset
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    sudo su -c iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
    ${COMMAND}
    if [ $? -ne 0 ]; then
        echo "kubeadm join failed, exiting ..."
        exit 1
    fi

fi
