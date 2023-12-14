#!/bin/bash

sleep 20
echo "Disabling swap ..."
sudo swapoff -a && sudo chmod 755 /var/lib/kubelet/