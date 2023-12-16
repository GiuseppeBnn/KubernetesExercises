#!/bin/bash

# Controlla se ci sono argomenti
if [ "$#" -lt 2 ]; then
    echo "Errore: Devi fornire almeno una subnet e un host worker."
    echo "Uso: $0 <subnet> [<hostname_worker1> <IP_worker1> <hostname_worker2> <IP_worker2...]"
    exit 1
fi

# Memorizza gli argomenti in un array
args=("$@")


rm -f inventory.ini
touch inventory.ini
echo "[worker]" >> inventory.ini
# Loop sugli argomenti, saltando il primo
for ((i = 1; i < $#; i+=2)); do
    echo "host"$((i/2+1))" ansible_user="${args[$i]}" ansible_host="${args[$((i+1))]} >> inventory.ini
done

echo "File inventory.ini creato con successo."

## Esegui installazione locale di kubernetes
read -p "Vuoi eseguire l'installazione locale di kubernetes? [s/n] " 
echo
if [ "$REPLY" == "s" -o "$REPLY" == "S" ]; then
    echo "Istallazione master locale..."
        rm -f inventory.ini
        sudo ./startKube.sh $1
    echo "Script completato con successo."
fi
join_command1=$(grep "kubeadm join" kubeadm-init.txt | sed 's/[[:blank:]]\\*$//' | sed 's/\\$//')
join_command2=$(grep "discovery-token-ca-cert-hash" kubeadm-init.txt)
join_command="$join_command1 $join_command2"
echo "Join command: $join_command"

rm -f join_command.sh
echo "#!/bin/bash" >> join_command.sh
echo "$join_command" >> join_command.sh
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
sudo ansible-playbook -i inventory.ini initWorkers.yaml  --private-key ~/.ssh/id_rsa --ask-become-pass
if [ $? -ne 0 ]; then
    echo "Errore: ansible-playbook ha restituito un errore."
    exit 1
fi