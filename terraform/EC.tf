resource "aws_instance" "jenkins" {
  ami            = "ami-0aa2b7722dc1b5612"
  instance_type  = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.jenkins.name
  key_name       =  aws_key_pair.pem.key_name
  vpc_security_group_ids = [aws_security_group.Private_Instances_SG.id]
  subnet_id              = aws_subnet.private1.id
  tags = {
    Name = "jenkins"
    Project = var.Project
    Environment = var.Environment
  }

}

resource "aws_instance" "app" {
  ami = "ami-0aa2b7722dc1b5612"
  instance_type  = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.app.name
  key_name       = aws_key_pair.pem.key_name
  vpc_security_group_ids = [aws_security_group.Private_Instances_SG.id]
  subnet_id              = aws_subnet.private2.id
  tags = {
    Name = "app"
    Project = var.Project
    Environment = var.Environment
  }
}

resource "aws_instance" "bastion" {
  ami            = "ami-0aa2b7722dc1b5612"
  instance_type  = "t2.micro"
  key_name = aws_key_pair.pem.key_name
  vpc_security_group_ids = [aws_security_group.Bastion_host_SG.id]
  subnet_id              = aws_subnet.public1.id
  associate_public_ip_address = true
  depends_on = [aws_instance.jenkins,aws_instance.app,local_file.ansible_inventory]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./devopsninja.pem")
    host        = self.public_ip
  } 

  provisioner "remote-exec" {
    inline = [
        "echo 'Executing command  sudo-update with sleep 120 sec'",
        "sudo apt-get update && sudo apt upgrade -y",
        "sleep 120"
    ]
  }
  provisioner "remote-exec" {
    inline = [
        "echo 'Executing ssh-keyscan to add app and jenkins ip to known hosts'",
        "sudo ssh-keyscan ${aws_instance.jenkins.private_ip} >> ~/.ssh/known_hosts",
        "sudo ssh-keyscan ${aws_instance.app.private_ip} >> ~/.ssh/known_hosts",
        "sudo apt install software-properties-common",
        "sudo add-apt-repository --yes --update ppa:ansible/ansible"
    ]
  }
  provisioner "file" {
    source      = "./devopsninja.pem"
    destination = "/home/ubuntu/devopsninja.pem"
  }
  provisioner "file" {
    source      = "./inventory/inventory.ini"
    destination = "/home/ubuntu/inventory.ini"
  }
    provisioner "file" {
    source      = "./playbookdockerinstall.yml"
    destination = "/home/ubuntu/playbookdockerinstall.yml"
  }
    provisioner "file" {
    source      = "./playbookjrejqappinstall.yml"
    destination = "/home/ubuntu/playbookjrejqappinstall.yml"
  }
   provisioner "file" {
    source      = "./playbookawscliinstall.yml"
    destination = "/home/ubuntu/playbookawscliinstall.yml"
  }
  
    provisioner "file" {
    source      = "./script/packages_script.sh"
    destination = "/home/ubuntu/packages_script.sh"
  }

  provisioner "remote-exec" {
    inline = [
        "echo 'Executing command ansible install with sleep 90 sec'",
        "sudo apt-get install -y ansible",
        "sleep 90",
        "sudo chmod 600 devopsninja.pem",
        "sudo ansible --version",
        "echo 'Executing playbook for docker install on app and jenkins using ansbil sleep 120 sec'",
        "sudo ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini --limit '!host1' playbookdockerinstall.yml",
        "sleep  80",        
        "echo 'Executing playbook for jre jq and awscli install on jenkins using ansbil '",
        "sudo ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbookjrejqappinstall.yml",
        "sleep 80",
        "sudo chmod +x ./packages_script.sh",
        "sudo ./packages_script.sh"
        ]
  }


  tags = {
    Name = "bastion"
    Project = var.Project
    Environment = var.Environment
  }
}

# Ansible Inventory file
resource "local_file" "ansible_inventory" {
  depends_on = [aws_instance.jenkins,aws_instance.app]
  filename = "./inventory/inventory.ini"
  content = <<EOT
[jenkins]
${aws_instance.jenkins.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/devopsninja.pem
[app]
${aws_instance.app.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/devopsninja.pem
EOT
}

# Script to run jenkins container on Jenkins through ansible
resource "local_file" "packages_script" {
  depends_on = [aws_instance.jenkins,aws_instance.app]
  filename = "./script/packages_script.sh"
  content = <<EOT
sudo ansible  jenkins -i ./inventory.ini -b -m command -a "docker container run -d -p 8080:8080 -v jenkins:/var/jenkins_home --name jenkins-local --env JENKINS_OPTS="--prefix=/jenkins" jenkins/jenkins:lts"
sudo ansible  all -i ./inventory.ini -b -m command -a "sudo usermod -aG docker $USER"
sudo ansible  all -i ./inventory.ini -b -m command -a "sudo apt-get update -y"
sudo ansible  all -i ./inventory.ini -b -m command -a "sudo pip install awscli --ignore-installed six"
sudo ansible  app -i ./inventory.ini -b -m command -a "sudo apt-get install -y default-jre"
sudo ansible  app -i ./inventory.ini -b -m command -a "sudo apt-get install -y jq"
EOT
}
