# Processo de Deploy no GCP

## Serviços utilizados: VPC, Cloud DNS, Computer Engine, Cloud SQL

## Tecnologias utilizadas: PHP, Laravel, PostgreSQL, Nginx, PHP-FPM

1 - Criar uma conta no console do GCP

2 - Criar um projeto no GCP, nesse exemplo vamos chamar nosso projeto pelo nome: **php-manaus-lab**.

    Todos os recursos a seguir serão criados e configurados nesse projeto.

3 - Criar uma VPC Personalizada e configurar uma sub-rede.

    Nome da VPC será: **`web-app-network`**
    Descrição: Rede utilizada no projeto web
    Intervalo IPV6 interno de ULA da rede VPC: Desativados

    Modo de Criação da sub-rede: Personalizado
    Nome da Sub-rede: web-app-subnet
    Descrição da Sub-rede: Sub-rede que será utilizada no projeto web
    Região: us-centra-1
    Tipo de Pilha de IP: IPV4
    Intervalo IPV4: 10.10.0.0/24
    Acesso Privado do Google: Ativado
    Registros de Fluxo: Desativado
 
    Configuração de Regras de Firewall:
    Vamos Selecionar quais Protocolos Estão liberados no Firewall:
    1 - web-app-network-allow-icmp
    2 - web-app-network-allow-ssh

    Modo de roteamento dinâmico: Global 

Comando:
```
git clone https://github.com/franciscorjr/sisemes-backend.git
```




