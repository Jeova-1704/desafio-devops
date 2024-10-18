
### 1. Análise Técnica do Código Terraform → [main.tf original](./arquivo%20original/mainOriginal.tf)
O [main.tf](./arquivo%20original/mainOriginal.tf) está configurado para provisionar uma infraestrutura básica na AWS que inclui a criação de uma Virtual Private Cloud (VPC), sub-rede, tabela de rotas, grupo de segurança, gateway de internet, uma instância EC2 e chaves SSH para acesso seguro à instância

##### 1.1. Provider e Variáveis

> **AWS Provider:** Define que os recursos serão criados na região us-east-1 da AWS.Variáveis:
> **Projeto:** Nome do projeto, valor padrão VExpenses.
>**candidato:** Nome do candidato, valor padrão "SeuNome".

Essas variáveis são usadas para nomear recursos na AWS.

<br>

##### 1.2. Key Pair
> **TLS Private Key:** Gera uma chave privada RSA de 2048 bits (tls_private_key.ec2_key) que será usada para acessar a instância EC2.
> **AWS Key Pair:** Cria um Key Pair na AWS usando a chave pública derivada da chave privada gerada. O nome do Key Pair segue o padrão ${var.projeto}-${var.candidato}-key.

<br>

##### 1.3. VPC e Subnet
> **VPC:** Cria uma VPC (aws_vpc.main_vpc) com o bloco CIDR 10.0.0.0/16 e suporte para DNS habilitado.
> **Subnet:** Cria uma subnet pública (aws_subnet.main_subnet) na zona de disponibilidade us-east-1a com o bloco CIDR 10.0.1.0/24, dentro da VPC.

<br>

##### 1.4. Internet Gateway e Rota
> **Internet Gateway:** Cria um gateway de internet (aws_internet_gateway.main_igw) associado à VPC, permitindo que a subnet tenha acesso à internet.
> **Route Table:** Cria uma tabela de rotas (aws_route_table.main_route_table) que direciona todo o tráfego (0.0.0.0/0) para o Internet Gateway.
> **Associação de Tabela de Rotas:** Associa a tabela de rotas à subnet (aws_route_table_association.main_association).

<br>

##### 1.5. Security Group
> **Security Group:** Cria um grupo de segurança (aws_security_group.main_sg) com as seguintes regras:
> **Ingress:** Permite tráfego SSH (porta 22) de qualquer lugar (IPv4 e IPv6).
> **Egress:** Permite todo o tráfego de saída.

<br>

##### 1.6. Instância EC2
> **AMI Debian 12:** Utiliza a imagem mais recente do Debian 12 na arquitetura AMD64, baseada em um filtro específico.
> **EC2 Instance:** Cria uma instância EC2 (aws_instance.debian_ec2) com as seguintes características:
> **AMI:** Usando a AMI do Debian 12.
> **Tipo de instância:** t2.micro, uma opção de instância gratuita.
> **Key Pair:** A instância é acessada pelo Key Pair gerado anteriormente.
> **Security Group:** Está associada ao grupo de segurança que permite SSH.
> **Disco raiz:** Configurado com 20 GB de armazenamento do tipo gp2.
> **User Data:** Script de inicialização que atualiza e faz o upgrade do sistema operacional.
> **IP público:** A instância é associada a um IP público.

<br>

##### 1.7. Outputs
> **private_key:** Exibe a chave privada gerada para acessar a instância EC2 (marcada como sensível).
> **ec2_public_ip:** Exibe o endereço IP público da instância EC2.

<br>

##### 1.8 Observações:
> **Segurança do SSH:** A permissão do SSH a partir de qualquer IP (0.0.0.0/0) é uma má prática que apresenta riscos de segurança, porque deixa instâncias expostas a qualquer testativas de acessos indesejados, é recomendável restringir o tráfego de SSH a IPs confiáveis.
> **Gerenciamento de Logs e Monitoramento:** Deveria ter algum sistema de monitoramento de logs e registros, como o AWS Systems Manager. que é recomendado para produção, pois permite monitorar a instância e obter detalhes sobre as falhas ou desempenho.

---

### 2. Modificação e Melhoria do Código Terraform -> [main.tf alterado](main.tf)
##### 2.1. modificações basicas

Antes:
```
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}
```
Depois
```
variable "desafio_cloud_devops" {
  description = "Projeto do desafio para estagio em cloud devops na VExpenses"
  type        = string
  default     = "VExpenses"
}

variable "Jeova" {
  description = "Nome do candidato é Jeova"
  type        = string
  default     = "SeuNome"
}
```
Obs: Alterações feitas nos campos das váriaveis e em todas as instancias que chama elas ou seus dados ao longo do código.

##### 2.2. Aplicação de melhorias de segurança
Em ves de deixar a permissão do SSH a partir de qualquer IP, é melhor restringir para apenas um específico, que pode ser definido como uma variável. Se precisar permitir mais IPS confíaveis, pode ser adicionado mais IPs na lista.

--- 
Antes:
```
resource "aws_security_group" "main_sg" {
  name        = "${var.desafio_cloud_devops}-${var.Jeova}-sg"
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-sg"
  }
}

```

Depois:
```
variable "allowed_ssh_ip" {
  description = "Endereço IP para permitir SSH"
  type        = string
  default     = "203.0.113.0/32"
}
```

---

Para aumentar a segurança, você deve substituir o bloco output "private_key" pelo novo bloco que utiliza o recurso local_file para armazenar a chave privada de forma local, assim como a saída (output) do caminho do arquivo.

antes:
```
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}
```

depois:
```
resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/private_key.pem"
  file_permission = "0400"  # Somente leitura pelo dono
}

output "private_key_path" {
  description = "Caminho para a chave privada localmente armazenada"
  value       = local_file.private_key.filename
  sensitive   = true
}
```

---

A criptografia do volume é uma medida de segurança crítica para proteger os dados armazenados em volumes anexados a instâncias, como os volumes EBS (Elastic Block Store) da AWS, contra acessos não autorizados. Quando a criptografia está habilitada, todos os dados gravados no volume são automaticamente criptografados, enquanto os dados lidos são descriptografados.

antes:
```
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              EOF

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-ec2"
  }
}
```

depois:
```
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = true  # Criptografia ativada
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              EOF

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-ec2"
  }
}
```

##### 2.3 Automação da Instalação do Nginx:
podemos adicionar comandos no user_data da instância EC2 que serão executados automaticamente assim que a instância for criada, para instalar e iniciar o Nginx.

antes:
```
user_data = <<-EOF
            #!/bin/bash
            apt-get update -y
            apt-get upgrade -y
            EOF
```

depois:
```
user_data = <<-EOF
            #!/bin/bash
            apt-get update -y
            apt-get upgrade -y
            apt-get install nginx -y
            systemctl start nginx
            systemctl enable nginx
            EOF
```

> **apt-get update -y :** Atualiza a lista de pacotes disponíveis para garantir que os pacotes mais recentes estejam instalados.
> **apt-get upgrade -y :** Atualiza todos os pacotes instalados para suas versões mais recentes.
> **apt-get install nginx -y :** Instala o Nginx, que é um servidor web usando para servir conteúdo estático e dinâmico.
> **systemctl start nginx :** Inicia o serviço do Nginx.
> **systemctl enable nginx :** Habilita o Nginx para iniciar automaticamente na inicialização do sistema.
