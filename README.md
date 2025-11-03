# Linux Ubuntu — Ambiente DevOps (Terraform + Ansible + Azure)



# Playbook: Deploy .NET Forecast API (Ansible)

Este documento explica detalhadamente tudo que o playbook `playbook-dotnet.yml` faz: objetivos, pré-requisitos, variáveis, tarefas, handlers, idempotência e recomendações operacionais.

---

## Objetivo

Provisionar uma máquina Ubuntu e realizar o deploy de uma Web API .NET (template `webapi`, WeatherForecast) de forma automatizada usando Ansible.

O playbook realiza (resumo):

1. Instala dependências do sistema e adiciona o repositório oficial Microsoft para pacotes .NET.
2. Instala o .NET SDK (para compilar/publish).
3. Cria um usuário de runtime sem login (segurança).
4. Gera o template WebAPI (`dotnet new webapi`) caso ainda não exista.
5. Publica a aplicação em modo Release para um diretório final (`/var/www/forecastapi`).
6. Ajusta permissões do diretório publicado.
7. Cria e gerencia um serviço `systemd` para executar a aplicação em background.
8. Abre a porta da aplicação no UFW (se habilitado).
9. Inicia e habilita o serviço, espera a porta responder e verifica o endpoint `/weatherforecast`.

---

## Pré-requisitos (no controlador Ansible)

* Ansible instalado e acessando o(s) host(s) remotos via SSH (com `azureuser` ou outro usuário com `sudo`).
* Inventário com o grupo `terraform-ansible` apontando para as VMs alvo.
* Chave SSH configurada e com permissões corretas.

Exemplo de inventário (INI):

```ini
[terraform-ansible]
SEU_IP_PUBLICO ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/id_rsa_azure
```

---

## Variáveis principais do playbook

O playbook usa variáveis para facilitar reutilização e manutenção. Exemplos:

* `dotnet_sdk_pkg` — nome do pacote apt (`dotnet-sdk-8.0`).
* `app_name` — nome da aplicação (usado para nomes de diretório e service).
* `app_dir` — pasta destino onde o publish será colocado (`/var/www/forecastapi`).
* `app_port` — porta em que a aplicação expõe (ex.: 5000).
* `run_user` — usuário de sistema que executará o serviço.

---

## Explicação das seções do playbook

### `pre_tasks`

* `apt` (Instalar deps base): atualiza cache e instala pacotes necessários como `wget`, `apt-transport-https`, `gnupg`, `ca-certificates`.
* `shell` (Adicionar repositório Microsoft): baixa o pacote `packages-microsoft-prod.deb` e instala com `dpkg -i`. Usa `creates:` para garantir que a ação só ocorra se `/etc/apt/sources.list.d/microsoft-prod.list` não existir (idempotência).
* `apt` (Atualizar cache apt): atualiza o cache de pacotes após registrar o repositório.
* `apt` (Instalar .NET SDK): instala o pacote indicado por `dotnet_sdk_pkg`.

### `tasks`

* `user` (Criar usuário de runtime): cria um usuário do sistema sem login (por segurança) que será dono dos arquivos e executará o serviço.
* `file` (Garantir diretórios do app): garante que os diretórios de código, build e deploy existam com as permissões corretas.
* `command` (Criar projeto WebAPI): executa `dotnet new webapi -n {{ app_name }} --no-https` dentro de `/opt/{{ app_name }}/src` se o projeto não existir (`creates` implícito via `args` `creates` no playbook). Isso cria o scaffold do projeto.
* `lineinfile` (Opcional para Swagger/CORS): insere linhas no `Program.cs` para habilitar Swagger/SwaggerUI (se o arquivo contiver o padrão procurado).
* `command` (Publicar em Release): roda `dotnet publish -c Release -o {{ app_dir }}` para gerar os binários prontos para execução na pasta de deploy.
* `file` (Ajustar permissões): recursivamente ajusta dono/grupo dos arquivos publicados para `run_user`.
* `copy` (Criar serviço systemd): cria o arquivo de unidade systemd em `/etc/systemd/system/{{ app_name | lower }}.service` com `ExecStart` apontando para o executável (ou para `dotnet <dll>` dependendo do publish). Notifica o handler `Restart api` quando o conteúdo muda.
* `command` (Abrir porta no UFW): executa `ufw allow {{ app_port }}` — a tarefa trata falhas de modo permissivo (`failed_when: false`) e normaliza mudança através de `changed_when`.
* `systemd` (Ativar serviço): habilita o serviço para iniciar no boot.
* `systemd` (Iniciar serviço): inicia o serviço imediatamente.
* `wait_for` (Aguardar API subir): espera até que o `app_port` esteja escutando em `127.0.0.1`.
* `uri` (Testar endpoint): faz um GET em `/weatherforecast` esperando status `200`.
* `debug` (Exibir resposta de teste): mostra o JSON retornado no output do playbook (útil para ver se a API respondeu corretamente).

### `handlers`

* `Restart api` — handler acionado por `notify` se o arquivo do serviço `systemd` for alterado. Ele executa `systemd` para reiniciar e recarregar a unidade quando necessário.

---

## Idempotência e boas práticas

* `creates:` em comandos evita reexecução desnecessária (filtra se a ação já foi feita).
* Uso de `file` e `user` garante que recursos existam sem recriá-los cada execução.
* `notify` + `handlers` evita reinícios redundantes de serviços.
* `register`, `failed_when` e `changed_when` permitem controlar resultado e comportamento das tarefas.

---

## Pontos de atenção e recomendações

* Certifique-se de que a versão do Ubuntu alvo (ex.: 22.04) coincide com o pacote de repositório Microsoft baixado. Se necessário, torne o download dinâmico conforme `ansible_distribution_version`.
* Se o `dotnet publish` gerar DLL em vez de binário nativo, ajuste o `ExecStart` do service para usar `dotnet /var/www/forecastapi/YourApp.dll`.
* Em produção, prefira usar *reverse proxy* (Nginx/Traefik) à frente da aplicação e habilitar HTTPS com Let's Encrypt.
* Evite usar `--no-https` em projetos reais: isso é só para simplificar o exemplo. Configure certificados e `ASPNETCORE_URLS` adequadamente.

---

## Como rodar o playbook

```bash
ansible-playbook playbook-dotnet.yml -u azureuser --private-key ~/.ssh/id_rsa_azure -i hosts.yml
```

Onde `hosts.yml` contém o host do grupo `terraform-ansible` e `playbook-dotnet.yml` é o playbook.

---

## Troubleshooting (erros comuns)

* **Problema**: `dpkg -i` falha por falta de dependências.

  * **Solução**: trocar o `shell` por instalação com `apt` após adicionar o repo, e rodar `apt-get -f install` se necessário.

* **Problema**: `dotnet` não encontrado após instalar o pacote.

  * **Solução**: verifique se `/usr/bin/dotnet` existe e rode `dotnet --info` manualmente; confirme `apt update` após adicionar o repo.

* **Problema**: service inicia mas retorna 502 pelo reverse proxy.

  * **Solução**: conferir `journalctl -u {{ app_name | lower }} -f` e logs do Nginx; confirmar `ASPNETCORE_URLS` e que a app esteja escutando no host/porta esperados.

---

## Extensões sugeridas

* Adicionar role `dotnet` e role `app` para modularizar o código.
* Adicionar integração com CI (GitHub Actions/GitLab CI) que roda `dotnet publish` e transfere artifacts para servidores, evitando builds no servidor.
* Configurar um template Jinja2 para o arquivo `systemd` e para a conf do Nginx.
* Automatizar obtenção de certificado (Certbot) no final do playbook.

---

### Conectar na vm da azure
```bash
ssh -i ~/.ssh/id_rsa_azure azureuser@<PUBLIC_IP>
```
