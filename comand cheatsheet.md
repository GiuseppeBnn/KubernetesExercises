Se non configurato correttamente, il comando kubectl non funziona, restituendo l'errore:
The connection to the server localhost:8080 was refused - did you specify the right host or port?
Per risolvere, eseguire il comando:
export KUBECONFIG=/etc/kubernetes/admin.conf
Per rendere la modifica permanente, aggiungere la riga al file ~/.bashrc
Per verificare che il comando funzioni, eseguire il comando:
kubectl get nodes
Deve restituire un output simile a questo:
NAME     STATUS   ROLES                  AGE   VERSION
arch     Ready    control-plane,master   10m   v1.21.1
worker   Ready    <none>                 10m   v1.21.1
Se non funziona, verificare che il file /etc/kubernetes/admin.conf esista e che contenga le credenziali corrette
Un problema noto è il contesto sbagliato, per cambiare contesto eseguire:
$ kubectl config current-context
per avere un idea dei contesti disponibili e di conseguenza verificare che il contesto corrente sia quello corretto
Per vedere il contesto corrente, eseguire:
$ kubectl config view
Per cambiare contesto, eseguire:
$ kubectl config use-context <context-name
Parallelamente, mentre kubeadm init è in esecuzione, in particolare mentre aspetta kubelet, eseguire il comando:
$ sudo swapoff -a && sudo chmod 755 /var/lib/kubelet/
Se alla fine di kubeadm init viene restituito l'errore: x509: certificate signed by unknown authority
Eseguire il comando:
$ sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
