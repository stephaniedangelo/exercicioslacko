data "aws_ami" "slacko-amazon"{
	most_recent = true
	owners = ["amazon"]
	
	filter {
		name = "name"
		values = ["amazn2-*"]
	}
	
	filter {
		name = "architecture"
		values = ["x86_64"]
	}
	
	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}
}

data "aws_subnet" "slacko-app-subnet-public" {
	cidr_block = "10.0.102.0/24"
}

resource "aws_key_pair" "slacko-key-ssh"{
	key_name = "slacko-ssh-key"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCiqeEinye6sb6nDSrEn9ZN2YVGoouQ+CQ1Ol0B0WkXA9eNEJA9rQVZUocdl3AcLOHU3GSZZynAVCMdRhUyolrCHNcVK0iDdtDYEPUk8ozexiNr5WIV3UYXYtHJGjCwnJMkhTFdfsSmGQkS8/XwNckve5qGYbCOOjyBXUeAj7b/c5KusjtvQ7nkvTuVS1oS2BHczmh+XoZAVSTrpt5EM6m2Zf9tm5/uSxk1szo1ra91/lf6BHXhss6sOaQ9AobhbS1WbKZtpyKN8vk52ZrpoO0ooCalZRz+adOWk2tu0BeL6Cqx0ZGeGJXPWlzIxvz7TYpkOCXUm75WpHuPZ6B9MzXEgFefGYHwX1S+eJIrIfpAFq63rUr/z01M7Z03lkQx3OWLTdG4jrOHTcVgwjqCsup3h8RQDNEG68yjX1NtHwEGSrl3kGXADNKzX9xQcrBJ3sm6KtcC/aUu/rDWIojpEgp6xEMXrttN9izZn3PbKtQswdPvP+KA1MrHjeyZOZ8aurk= slacko"
}

resource "aws_instance" "slacko-app" {
	ami = data.aws_ami.slacko-amazon.id
	instance_type = "t2.micro"
	subnet_id = data.aws_subnet.slacko-app-subnet-public.id
	associate_public_ip_adress = true
	key_name = aws_key_pair.slacko-key-ssh.key_name
	user_data = file("ec2.sh")
	tags = {
		Name = "slacko-app"
	}
}

resource "aws_instance" "slacko-mongodb" {
	ami = data.aws_ami.slacko-amazon.id
	instance_type = "t2.small"
	subnet_id = data.aws_subnet.slacko-app-subnet-public.id
	associate_public_ip_adress = true
	key_name = aws_key_pair.slacko-key-ssh.key_name
	user_data = file("mongodb.sh")
	tags = {
		Name = "slacko-mongodb"
	}
}

resource "aws_security_group" "allow-http"{
	name = "allow_http_ssh"
	description = "Security group allows SSH and HTTP"
	vpc = "vpc-074ac28b0d10fd06f"
	
	ingress = [
		{
			description = "Allowe SSH"
			from_port = 22
			to_port = 22
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/0"]
			ipv6_cidr_blocks = []
			prefix_list_ids = []
			security_groups = []
			self = null
		},
		{
			description = "Allowe HTTP"
			from_port = 80
			to_port = 80
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/0"]
			ipv6_cidr_blocks = []
			prefix_list_ids = []
			security_groups = []
			self = null
		}
	]
	
	egress = [
		{
			description = "Allowe HTTP"
			from_port = 0
			to_port = 0
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/0"]
			ipv6_cidr_blocks = []
			prefix_list_ids = []
			security_groups = []
			self = null
		}
	]
	
	tags = {
		Name = "allow_ssh_http"
	}
}

resource "aws_network_interface_sg_attachment" "slacko-sg" {
	security_group_id = aws_security_group.allow_http_ssh.id
	network_interface_id = aws_instance.slacko-app.primary_network_interface_id
}

output "slacko-app-IP" {
	value = aws_instance.slacko-app.public_ip
}

output "slacko-mongodb-ip" {
	value = aws_instance.slacko-mongodb.private_ip
}