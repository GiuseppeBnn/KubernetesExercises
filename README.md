# una repo solo per esercitarmi in Kubernetes

Per installare kubernetes su Arch Linux avviare lo script (no root) installKubeArch.sh

Per settare il master del cluster e di conseguenza i worker, avviare start.sh specificando come primo parametro la subnet corretta (es. 192.168.0.0/16), come altri parametri coppia utente ip delle macchine worker.
In breve: 
$ ./start.sh <subnet> <user1> <user1 IP addr> <user2> <user2 IP addr>.....

Ad esempio

./start.sh 192.168.0.0/16 eren 192.168.1.39 mikasa 192.168.1.99 armin 192.168.1.56


STATUS
- L'inizializzazione del master/control plane worka su ubuntu, da testare su arch

-Al momento vi sono problemi negli script, in particolare problemi di configurazione workers con ansible (work in progress...)
