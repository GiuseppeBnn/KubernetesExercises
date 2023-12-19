#!/bin/bash

# Controlla se lo script non è stato avviato con sudo
if [ "$EUID" -eq 0 ]; then
    echo "Errore: questo script non deve essere avviato con sudo."
    exit 1
fi


H=$HOME
ID=$(id -u)
IDG=$(id -g)

# Controlla se ansible è installato
if ! command -v ansible &>/dev/null; then
    echo "Errore: ansible non è installato."
    exit 1
fi

# Controlla se ci sono argomenti
if [ "$#" -lt 2 ]; then
    echo "Errore: Devi fornire almeno una subnet e un host worker."
    echo "Uso: $0 <subnet> [<hostname_worker1> <IP_worker1> <hostname_worker2> <IP_worker2...]"
    exit 1
fi
#TODO: testings of this part of code
##Controlla se docker è installato, nel caso lo installa (controllando la distribuzione e se è presente la repository)  
#if ! command -v docker &>/dev/null; then
#    echo "Docker non è installato, procedo con l'installazione..."
#    if [ -f /etc/os-release ]; then
#        . /etc/os-release
#        OS=$NAME
#        VER=$VERSION_ID
#    else
#        echo "Errore: non è stato possibile rilevare la distribuzione."
#        exit 1
#    fi
#    if [ "$OS" == "Ubuntu" ]; then
#        sudo apt-get update
#        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
#        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#        sudo apt-get update
#        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
#    elif [ "$OS" == "Arch Linux" ]; then
#        sudo pacman -Syu --noconfirm docker
#        sudo systemctl enable docker.service
#        sudo systemctl start docker.service
#    else
#        echo "Errore: distribuzione non supportata."
#        exit 1
#    fi
#fi


args=("$@")

rm -f inventory.ini
touch inventory.ini
echo "[worker]" >>inventory.ini
# Loop sugli argomenti, saltando il primo
for ((i = 1; i < $#; i += 2)); do
    echo "host"$((i / 2 + 1))" ansible_user="${args[$i]}" ansible_host="${args[$((i + 1))]} >>inventory.ini
done

echo "File inventory.ini creato con successo."

## Esegui installazione locale di kubernetes
read -p "Vuoi eseguire l'installazione locale di kubernetes? [s/n] "
echo
if [ "$REPLY" == "s" -o "$REPLY" == "S" ]; then
    echo "Istallazione master locale..."
    rm -f inventory.ini

    echo "Initializing a master with kubeadm"
    echo "Removing old configuration files ..."
    sudo kubeadm reset -f
    echo "Removing old ${H}/.kube/ ..."
    sudo rm -rf "${H}/.kube/"
    echo "Disabling swap ..."
    sudo swapoff -a

    echo "Initializing kubeadm ..."
    rm -f kubeadm-init.txt
    sudo kubeadm init --pod-network-cidr=$1 | tee kubeadm-init.txt
    if [ $? -ne 0 ]; then
        echo "kubeadm init failed, exiting ..."
        exit 1
    fi
    
    echo "Copying configuration files ..."
    sudo mkdir -p "${H}/.kube"
    sudo echo "Copying admin.conf to ${H}/.kube/config"
    sudo cp -i /etc/kubernetes/admin.conf ${H}/.kube/config
    sudo chown ${ID}:${IDG} ${H}/.kube/config


    echo "Installing flannel ..."
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    echo "Done, you can now join other nodes to the cluster"

fi
join_command1=$(grep "kubeadm join" kubeadm-init.txt | sed 's/[[:blank:]]\\*$//' | sed 's/\\$//')
join_command2=$(grep "discovery-token-ca-cert-hash" kubeadm-init.txt)
join_command="$join_command1 $join_command2"
echo "Join command: $join_command"

rm -f join_command.sh
echo "#!/bin/bash" >>join_command.sh
echo "$join_command" >>join_command.sh
chmod +x join_command.sh
read -p "Vuoi installare prima docker e poi kubernetes nei worker? [s/n] "
echo
if [ "$REPLY" == "s" -o "$REPLY" == "S" ]; then
    echo "Installazione docker e kubernetes nei worker..."
    sudo ansible-playbook -i inventory.ini setupWorkers.yaml --private-key ~/.ssh/id_rsa --ask-become-pass
    if [ $? -ne 0 ]; then
        echo "Errore: ansible-playbook ha restituito un errore."
        exit 1
    fi

fi

echo "Esecuzione del playbook kubeadm..."
sudo ansible-playbook -i inventory.ini initWorkers.yaml --private-key ~/.ssh/id_rsa --ask-become-pass
if [ $? -ne 0 ]; then
    echo "Errore: ansible-playbook ha restituito un errore."
    exit 1
fi
