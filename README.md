## Processo de Deploy no GCP

### Serviços utilizados: VPC, Cloud DNS, Computer Engine, Cloud SQL

### Tecnologias utilizadas: PHP, Laravel, PostgreSQL, Nginx, PHP-FPM

### 1 - Criar uma conta no console do GCP

### 2 - Criar um projeto no GCP, nesse exemplo vamos chamar o nosso projeto pelo nome: **`php-manaus-lab`**

Todos os recursos a seguir serão criados e configurados nesse projeto.

Durante esse processo, é possível que o GCP peça para que você ative algumas APIs.

Conforme imagem abaixo, isso é normal.

Leia e depois ative se fizer sentido, Exemplo:

![Ativar API](docs-img/img-4.png)

### 3 - Criar uma VPC Personalizada e configurar uma sub-rede.

![Criar nova rede VPC](docs-img/img.png)

![Criar nova sub-rede](docs-img/img-2.png)

![Acesso privado do Google](docs-img/img-3.png)

Nome da VPC será: **`web-app-network`**

Descrição: **`Rede utilizada no projeto web`**

Intervalo IPV6 interno de ULA da rede VPC: **`Desativados`**

Modo de Criação da sub-rede: **`Personalizado`**

Nome da Sub-rede: **`web-app-subnet`**

Descrição da Sub-rede: **`Sub-rede que será utilizada no projeto web`**

Região: **`us-central-1`**

Tipo de Pilha de IP: **`IPv4`**

Intervalo IPv4: **`10.10.0.0/24`**

Acesso Privado do Google: **`Ativado`**

Registros de Fluxo: **`Desativado`**

 
Configuração de Regras de Firewall:

Vamos Selecionar quais Protocolos devem ser liberados no Firewall:

![Regras de Firewall](docs-img/img-5.png)

1 - web-app-network-allow-icmp

2 - web-app-network-allow-ssh

![Continuação](docs-img/img-6.png)

Modo de roteamento dinâmico: **`Global`** 

Clique em Criar

Rede VPC Criada com Sucesso!

![Rede Criada](docs-img/img-7.png)

### 4 - Configuração de Chave SSH no GCP
![Criando Chave SSH](docs-img/img-8.png)
![Criando Chave SSH](docs-img/img-9.png)

Caso você ainda não tenha uma chave SSH Publica e Privada na sua máquina, você precisará criar uma.

Criar Diretório no padrão: `mkdir .ssh`

Gerar Chaves Publicas e Privadas: `ssh-keygen -m PEM -N '' -f ~/.ssh/id_rsa`

Visualizar o Conteúdo da Chave: `cat .ssh/id_rsa.pub`

Depois colocar no campo Chave SSH no GCP.

### 5 - Criar o Servidor de Aplicação Ubuntu 24.04 utilizando o Computer Engine e adicioná-lo a rede da VPC

![Criando Computer Engine](docs-img/img-10.png)
![Configuração da Máquina](docs-img/img-11.png)
![Configuração da Máquina](docs-img/img-12.png)
![Configuração do Disco e SO](docs-img/img-13.png)
![Configuração de Rede](docs-img/img-14.png)
![Configuração de Rede](docs-img/img-15.png)
![Computer Engine Criada](docs-img/img-16.png)

Nome da Computer Engine: **`web-app-server`**

Região: **`us-central1 (Iowa)`**

Zona: **`us-central1-a`**

Tipo: **`e2-small`**

Ubuntu: **`24.04 x64`**

CPU: **`1 VCPU`**

RAM: **`2GB`**

Disco Permanente Equilibrado: **`30GB`**

Em Interfaces de rede escolha a VPC criada anteriormente: **`web-app-network`**

Em Sub-rede escolha a sub-rede criada anteriormente: **`web-app-subnet`**

Clique em Criar

### 6 - Atribuir um nome de DNS na rede interna do VPC para o Servidor de Aplicação

Caso seja necessário ative a API Cloud DNS no projeto.

![Ativação da API Cloud DNS](docs-img/img-17.png)

Vamos agora criar a nossa zona DNS:

![Criar Zona de DNS](docs-img/img-18.png)
![Vinculando a nossa VPC](docs-img/img-19.png)
![Adicionar registro de DNS para nosso Servidor de Aplicação](docs-img/img-20.png)

Nome da Zona: **`php-manaus-lab-zone`**

Nome do DNS: **`php.manaus.lab.example`**

Descrição: **`Zona responsável em resolver, os nomes de domínios de serviços da GCP`**

Opções: **`Padrão Privado`**

Rede: **`web-app-network`**


Adicionar o Registro de DNS do Servidor de Aplicação

Nome de DNS do Servidor de aplicação: **`web-app-1`**

Tipo de Registro: **`A`**

TLL: **`5`**

Unidade de TLL: **`minutos`**

Endereço IPV4: **`Selecionar o IP Interno do Servidor de Aplicação web-app-server`**

Clique em Criar 

Pronto, agora o nosso Servidor de Aplicação pode ser acessado internamente pelo DNS: **`web-app-1.php.manaus.lab.example.`**

### 7 - Reservar um IP Externo Estático
Caso o nosso Servidor de Aplicação reinicie, ele poderá acabar recebendo um novo IP Externo/Publico.

Para evitar isso, precisamos reservar um IP Externo e atribuí-lo ao nosso Servidor de Aplicação.

Vamos fazer isso no console do GCP.

![Reservando IP Externo](docs-img/img-21.png)

Clique em **`Reservar externo`**

E preencha os campos:

Nome: **`web-app-server-ip`**

Descrição: **`Reservar de IP para o Servidor de Aplicação Web`**

Nível de Serviço de Rede: **`Premium`**

Versão do IP: **`IPv4`**

Tipo: **`Regional`**

Anexado: **`web-app-server`**

### 8 - Conectar ao servidor de Aplicação via SSH para testar
Você pode se conectar pela interface do Computer Engine ou pelo terminal.

Para se conectar via terminal, utilize o comando abaixo e lembre-se de alterar as informações para seu contexto.

Comando: `ssh usuario@ip-publico`


Comando:
```
git clone https://github.com/franciscorjr/sisemes-backend.git
```




