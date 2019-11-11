resource "aws_instance" "minion" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t2.medium"
    count = "${var.minion_count}"
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
    key_name = "${aws_key_pair.london-region-key-pair.id}"

    connection {
        user = "${var.EC2_USER}"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }

    user_data = <<HEREDOC
    #!/bin/bash
    sudo amazon-linux-extras install vim nginx1 -y
    HEREDOC

    tags = {
      Name = "minion-${count.index}"
    }
}

resource "aws_instance" "master" {
    depends_on = ["aws_instance.minion"]
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t2.medium"
    count = "${var.master_count}"
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
    key_name = "${aws_key_pair.london-region-key-pair.id}"

    provisioner "local-exec" {
    command = <<EOD
    cat <<EOF > hosts
[masters]
master ansible_host=${aws_instance.master.public_ip} ansible_user=ec2-user

[workers]
worker1 ansible_host=${aws_instance.minion.public_ip} ansible_user=ec2-user
EOF
EOD
  }

    provisioner "file" {
      source = "london-region-key-pair"
      destination = "/home/ec2-user/.ssh/ansible_key"
    }
    
    provisioner "file" {
      source = "ansible-runner.sh"
      destination = "/home/ec2-user/ansible-runner.sh"
    }

    provisioner "file" {
      source = "hosts"
      destination = "/home/ec2-user/hosts"
    }

    provisioner "remote-exec" {
        inline = [
             "sudo amazon-linux-extras install ansible2 -y",
             "sudo yum install git -y",
             "git clone https://github.com/prabath88/instant-kubernetes.git",
             "export ANSIBLE_HOST_KEY_CHECKING=False",
             "sudo chmod 400 /home/ec2-user/.ssh/ansible_key",
             "sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/ansible_key",
             "eval $(ssh-agent -s)",
             "ssh-add /home/ec2-user/.ssh/ansible_key",
             "cp /home/ec2-user/ansible-runner.sh /home/ec2-user/instant-kubernetes/",
             "cp /home/ec2-user/hosts /home/ec2-user/instant-kubernetes/",
             "chmod +x /home/ec2-user/instant-kubernetes/ansible-runner.sh",
             "sh /home/ec2-user/instant-kubernetes/ansible-runner.sh",
        ]
    }

    
    connection {
        user = "${var.EC2_USER}"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }

    user_data = <<HEREDOC
    #!/bin/bash
    sudo amazon-linux-extras install nginx1 -y
    HEREDOC
    
    tags = {
      Name = "master"
    }
    
}

resource "aws_key_pair" "london-region-key-pair" {
    key_name = "london-region-key-pair"
    public_key = "${file(var.PUBLIC_KEY_PATH)}"
}