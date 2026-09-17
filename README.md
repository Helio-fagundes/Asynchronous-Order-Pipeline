# 🚀 Asynchronous Order Processing Pipeline
Sistema distribuído de alta disponibilidade para processamento assíncrono e orientado a eventos de pedidos, totalmente provisionado como código na AWS via Terraform.
</br>
A aplicação foi desenvolvida para ser resiliente, altamente escalável e segura, utilizando uma rede 100% privada para execução dos containers no AWS ECS Fargate, dispensando a necessidade de NAT Gateways ao utilizar VPC Endpoints (AWS PrivateLink) para comunicação interna entre os serviços AWS.
</br>

<img width="962" height="862" alt="image" src="https://github.com/user-attachments/assets/21142ef5-677e-4436-ac88-e8e288ebcc1a" />

## 📐 Arquitetura da Solução
O diagrama abaixo ilustra toda a topologia de rede, serviços de mensageria, computação serverless e componentes de segurança provisionados no ambiente AWS em Multi-AZ (duas zonas de disponibilidade):
## 🔑 Legenda dos Componentes

| # | Componente | Papel na Arquitetura |
| :-: | :--- | :--- |
| **1** | 👥 Usuários / Clientes | Fazem a requisição inicial (POST de um novo pedido) e recebem a confirmação final por e-mail. |
| **2** | 🌐 Internet Gateway | Único ponto de entrada/saída de tráfego público da VPC — usado apenas pelo tráfego que chega ao Load Balancer. |
| **3** | ⚖️ Application Load Balancer (ALB) | Recebe as requisições HTTP e distribui entre as instâncias do serviço Producer, nas duas zonas de disponibilidade. |
| **4** | 🗄️ Amazon S3 (Access Logs) | Armazena os logs de acesso do ALB para fins de auditoria, análise e troubleshooting. |
| **5** | 🔗 VPC Endpoints (AWS PrivateLink) | Conjunto de endpoints de interface (ECR API, ECR DKR, CloudWatch Logs, SQS, SNS) e gateway (S3, DynamoDB) que permitem às tasks em subnet privada se comunicarem com serviços AWS sem trafegar pela internet pública. |
| **6** | 🔓 Subnets Públicas (AZ A / AZ B) | Hospedam apenas o Load Balancer — nenhuma task de aplicação roda aqui. |
| **7** | 🔒 Subnets Privadas (AZ A / AZ B) | Hospedam as tasks do ECS Fargate — sem IP público e sem rota direta para a internet. |
| **8** | 🚀 ECS Service — Producer (Fargate) | Recebe a requisição via ALB, valida os dados, grava o pedido no DynamoDB (status: PENDING) e envia a mensagem para a fila SQS. Escalado automaticamente via Application Auto Scaling. |
| **9** | ⚙️ ECS Service — Worker (Fargate) | Consome as mensagens da fila SQS, atualiza o status do pedido no DynamoDB (status: ACCEPTED) e publica uma notificação no tópico SNS. |
| **10** | 💾 Amazon DynamoDB | Banco NoSQL de baixa latência que armazena o estado de cada pedido (PENDING → ACCEPTED), indexado por chave de partição id (UUID). |
| **11** | 📥 Amazon SQS (Fila Principal + DLQ) | Desacopla o Producer do Worker, garantindo resiliência. Mensagens com falha repetida após múltiplas tentativas são movidas para a Dead Letter Queue (DLQ). |
| **12** | 📣 Amazon SNS | Recebe a notificação de pedido processado e distribui (fan-out) para os assinantes (função Lambda). |
| **13** | 📦 Amazon ECR | Repositório privado para armazenamento das imagens Docker do Producer e do Worker. |
| **14** | ⚡ AWS Lambda | Assina o tópico SNS, formata os dados do pedido e aciona o serviço de e-mail de forma 100% serverless. |
| **15** | ✉️ Amazon SES | Envia o e-mail de confirmação (ou falha) diretamente para o cliente final. |

## ⚙️ Como Funciona "Por Debaixo dos Panos"

1. **Entrada do Pedido:** O cliente envia uma requisição `POST /orders` para a API. A chamada passa pelo Internet Gateway `[2]` e atinge o Application Load Balancer `[3]` na subnet pública.
2. **Ingestão e Persistência Inicial:** O ALB encaminha a chamada para uma das instâncias do Producer `[8]` rodando em subnet privada. O Producer:
   * Gera um UUID único para o pedido.
   * Salva o pedido no DynamoDB `[10]` com o status `PENDING`.
   * Posta a mensagem com os detalhes do pedido na fila do Amazon SQS `[11]`.
   * Retorna imediatamente a resposta `202 Accepted` para o cliente.
3. **Processamento Assíncrono:** As instâncias do Worker `[9]` (também em subnets privadas) escutam a fila SQS `[11]`:
   * O Worker consome a mensagem e executa a regra de negócio/processamento.
   * Atualiza o registro no DynamoDB `[10]` mudando o status para `ACCEPTED`.
   * Dispara uma notificação para o Amazon SNS `[12]`.
4. **Notificação e Finalização:** O AWS Lambda `[14]` é disparado pelo evento do SNS, monta a mensagem personalizada e chama o Amazon SES `[15]`, que envia o e-mail de confirmação para o cliente `[1]`.

## 📡 Endpoints da API e Respostas Esperadas

### Criar um Novo Pedido
* **URL:** `http://<ALB-DNS-NAME>/producers`
* **Método:** `POST`
* **Headers:** `Content-Type: application/json`

#### Payload de Exemplo (Request Body)
```json
{
  "name": "Helio Fagundes",
  "email": "seu-email@exemplo.com",
  "productName": "Curso Cloud Architecture",
  "price": 299.90
}
```

#### Resposta Imediata da API (Response Body - HTTP 202 Accepted)
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "name": "Helio Fagundes",
  "email": "seu-email@exemplo.com",
  "productName": "Curso Cloud Architecture",
  "price": 299.90,
  "status": "PENDING"
}
```

## 🛠️ Tecnologias Utilizadas

* **Linguagem & Framework:** Java 21, Spring Boot (Spring Web, Spring Cloud AWS, AWS SDK v2).
* **Containers:** Docker, Amazon ECR, Amazon ECS Fargate.
* **Infraestrutura como Código (IaC):** Terraform.
* **Provedor Cloud:** Amazon Web Services (AWS).
* **Serviços AWS:** VPC, Subnets, ALB, ECS, SQS, SNS, DynamoDB, S3, Lambda, SES, IAM, CloudWatch, VPC Endpoints.

## ⚙️ Variáveis de Ambiente e Configuração

Para provisionar a infraestrutura e executar o projeto, você precisará configurar o arquivo de variáveis do Terraform (`terraform.tfvars`).

Crie um arquivo chamado `terraform.tfvars` dentro do diretório `infra/terraform/` com a seguinte estrutura:

```hcl
region         = "us-east-1"
aws_access_key = "SUA_AWS_ACCESS_KEY"
aws_secret_key = "SUA_AWS_SECRET_KEY"
email          = "seu-email-para-notificacoes@exemplo.com"
```

> ⚠️ **Aviso de Segurança:** O arquivo `terraform.tfvars` e arquivos de estado `.tfstate` contêm informações sensíveis. Eles já estão configurados no `.gitignore` e nunca devem ser commitados no repositório.

## 🚀 Como Executar o Projeto

### Pré-requisitos
* AWS CLI instalado e autenticado.
* Terraform instalado (versão &ge; 1.5.0).
* Docker rodando na máquina local.
* JDK 21 e Maven/Gradle.

### Passo 1: Clonar o Repositório
```bash
git clone https://github.com/Helio-fagundes/Asynchronous-Order-Pipeline.git
cd Asynchronous-Order-Pipeline
```

### Passo 2: Provisionar a Infraestrutura com o Terraform
```bash
cd infra/terraform

# Inicializa os provedores e módulos
terraform init

# Valida os arquivos de configuração
terraform validate

# Exibe o plano de execução dos recursos
terraform plan

# Aplica e cria a infraestrutura na AWS
terraform apply -auto-approve
```
*Após a finalização, o Terraform retornará o DNS do Load Balancer e o nome dos repositórios ECR.*

### Passo 3: Build e Push das Imagens Docker
Faça o login no repositório Amazon ECR:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

Gere o build e envie a imagem do **Producer**:
```bash
cd ../../apps/producer
docker build -t order-producer .
docker tag order-producer:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/order-producer:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/order-producer:latest
```

Gere o build e envie a imagem do **Worker**:
```bash
cd ../worker
docker build -t order-worker .
docker tag order-worker:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/order-worker:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/order-worker:latest
```

### Passo 4: Confirmar o Envio de E-mail no SES
Após o deploy da infraestrutura, a AWS enviará um e-mail de verificação do Amazon SES para o endereço configurado na variável `email`. Acesse a caixa de entrada desse e-mail e clique no link de validação para autorizar o envio das notificações do sistema.

## 🔒 Segurança e Boas Práticas Implementadas

* **Zero Exposição Direta:** Nenhuma instância ou container possui IP público. O acesso às aplicações é feito estritamente através do ALB.
* **VPC Endpoints (AWS PrivateLink):** Comunicação entre os containers ECS e os serviços gerenciados (SQS, SNS, DynamoDB, ECR e CloudWatch) ocorre 100% via rede interna da AWS, evitando custos de NAT Gateway e exposição à internet.
* **Princípio do Menor Privilégio (IAM):** Roles e Policies do IAM restritas especificamente para cada serviço. O Producer possui permissão apenas para escrita no DynamoDB e envio ao SQS; o Worker possui permissão apenas para leitura do SQS, atualização do DynamoDB e publicação no SNS.

## 👨‍💻 Autor

Desenvolvido por **Helio Fagundes**.

Sinta-se à vontade para entrar em contato ou conectar através do [LinkedIn](seu-link-aqui)!
