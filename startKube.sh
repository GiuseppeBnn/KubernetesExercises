#!/bin/bash
sudo swapoff -a
sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/manifests/etcd.yaml

sudo rm -rf /var/lib/etcd

sudo systemctl enable --now kubelet.service
sudo systemctl start kubelet.service

sudo kubeadm init --pod-network-cidr=192.168.0.0/16
sudo systemctl restart kubelet.service