provider "aws" {
  region = "us-west-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# This is the Offical Version that has instance stopped after creation to save costs.



# ------------------------------------------------------------------
# NOTES FOR YOU (Reference)
# ------------------------------------------------------------------
# in order to find this ssh link clck your ec2 then click connect, then ssh clinet and after that copy under "Example"
# SSH Command: ssh -i "keylab1.3.pem" ec2-user@ec2-54-70-89-79.us-west-2.compute.amazonaws.com
# Get Password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# ------------------------------------------------------------------
# ssh -i "keylab1.3.pem" ec2-user@35.88.46.221 or whatever your public IP is on the output
# sudo cat /var/lib/jenkins/secrets/initialAdminPassword -grab your password for jenkins setup
# type "exit" to exit the ssh session


# sudo systemctl restart jenkins this is the restart jenkins for permissions purposes

# cd desktop/allfolder/important/e5tech/aws


#this is to check if you have the necessary devops tools installed- for jenkins to work properly
/* echo "--- DEVOPS TOOL CHECK ---"
git --version
docker --version
terraform --version
python3 --version
java -version
aws --version
echo "-----------------------" */


# terraform apply -replace="aws_instance.jenkins_server"
# sudo chown jenkins:jenkins /var/lib/jenkins/secrets/initialAdminPassword

# this is to basically privatize your key
# sudo systemctl restart jenkins (this restarts jenkins)


# chmod 400 keypair.pem




# This is the Offical Version that has instance stopped after creation to save costs.
# 5. Stop the instance after creation to save costs


# 1. Get the latest Amazon Linux 2023 (Kernel 6.12)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    # UPDATED: Specifically looking for Kernel 6.12 as you requested
    values = ["al2023-ami-2023.*-kernel-6.12-x86_64"]
  }
}

# 2. Create a Security Group (Firewall)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-security-group"
  description = "Allow SSH and Jenkins Traffic"

  # Allow SSH (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Jenkins (Port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Create the EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.medium"

  # Attach the Security Group
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # CRITICAL UPDATE: This allows you to SSH in with your existing key
  key_name = "keypair"

  # NOTE: If you want this in your "Shared Services" VPC, 
  # you must uncomment and add your subnet ID below:
  # subnet_id = "subnet-xxxxxxxx"

  tags = {
    Name = "Jenkins-Server-Terraform"
  }



  # Ensure user data runs on changes
  user_data_replace_on_change = true

  # -------------------------------------------------------
  # User Data Script (Installs Jenkins)
  # -------------------------------------------------------
  user_data                  = file("${path.module}/user-data.sh")




}

# 4. Print the URL
output "jenkins_url" {
  value = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

# This is the Offical Version that has instance stopped after creation to save costs.
# 5. Stop the instance after creation to save costs