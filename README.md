# Linux Ubuntu

# copia o ssh key da pasta do windows para uma pasta no linux
mkdir -p ~/.ssh
cp /mnt/c/Users/riken/.ssh/id_rsa_azure ~/.ssh/
chmod 600 ~/.ssh/id_rsa_azure

# conectar na vm da azure
ssh -i /mnt/c/users/riken/.ssh/id_rsa_azure azureuser@172.171.110.2

# executar o playbook do ansible
ansible-playbook playbook.yml -u azureuser --private-key ~/.ssh/id_rsa_azure -i hosts.
yml