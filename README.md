# Linux Ubuntu — Ambiente DevOps (Terraform + Ansible + Azure)

### Executar configuração com Ansible (Local, fora da VM)
```bash
ansible-playbook playbook.yml -u azureuser --private-key ~/.ssh/id_rsa_azure -i hosts.yml
```

### Conectar na vm da azure
```bash
ssh -i ~/.ssh/id_rsa_azure azureuser@<PUBLIC_IP>
```

### Comandos
```bash
ls
- tcc

cd tcc/
ls
- venv

. venv/bin/activate

pip freeze # para ver os pacotes instalados.

exit
```