# Linux Ubuntu — Ambiente DevOps (Terraform + Ansible + Azure)

## Requisitos

### Instalar Python
```bash
sudo apt install python3


- Para instalar o Terraform no Ubuntu
    - wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    - sudo apt update && sudo apt install terraform

 - Para instalar o Ansible no Ubuntu
    - sudo apt update
    - sudo apt install software-properties-common
    - sudo add-apt-repository --yes --update ppa:ansible/ansible
    - sudo apt-get install ansible

# Para conectar na vm Azure
- Gere uma chave RSA 4096
    - Windows (PowerShell)
        - ssh-keygen -t rsa -b 4096 -C "seu-email" -f C:\Users\riken\.ssh\id_rsa_azure
        ## vai criar:
        ##  - C:\Users\riken\.ssh\id_rsa_azure        (privada)
        ##  - C:\Users\riken\.ssh\id_rsa_azure.pub    (pública)

        ## copia da pasta do windows para o mnt do linux(precisa estar no linux)
        # 1️ Garantir pasta segura
        - mkdir -p ~/.ssh
        - chmod 700 ~/.ssh

        # 2️ Copiar a chave privada do Windows
        - cp /mnt/c/Users/riken/.ssh/id_rsa_azure ~/.ssh/
        - chmod 600 ~/.ssh/id_rsa_azure   # <- somente o dono pode ler

        # 3️ Copiar a chave pública (ou gerar, se não existir)
        - if [ -f /mnt/c/Users/riken/.ssh/id_rsa_azure.pub ]; then
        - cp /mnt/c/Users/riken/.ssh/id_rsa_azure.pub ~/.ssh/
        - else
        - ssh-keygen -y -f ~/.ssh/id_rsa_azure > ~/.ssh/id_rsa_azure.pub
        fi
        chmod 644 ~/.ssh/id_rsa_azure.pub  # <- leitura liberada (normal para chave pública)

    - Linux / WSL / macOS
        ssh-keygen -t rsa -b 4096 -C "seu-email" -f ~/.ssh/id_rsa_azure
        ## cria ~/.ssh/id_rsa_azure (privada) e ~/.ssh/id_rsa_azure.pub (pública)

# conectar na vm da azure
ssh -i ~/.ssh/id_rsa_azure azureuser@<PUBLIC_IP>

# executar o playbook do ansible
ansible-playbook playbook.yml -u azureuser --private-key ~/.ssh/id_rsa_azure -i hosts.yml