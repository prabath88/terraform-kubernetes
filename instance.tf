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
      Name = "minion"
    }
}



resource "aws_instance" "master" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t2.medium"
    count = "${var.master_count}"
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
    key_name = "${aws_key_pair.london-region-key-pair.id}"

    provisioner "file" {
      source = "london-region-key-pair"
      destination = "/home/ec2-user/.ssh/ansible_key"
    }

    provisioner "remote-exec" {
        inline = [
             "sudo yum install git vim ansible -y",
             "sudo mkdir -p /tmp/paas",
             "git clone https://github.com/prabath88/instant-kubernetes.git",
             "export ANSIBLE_HOST_KEY_CHECKING=False",
             "chmod 400 /home/ec2-user/.ssh/ansible_key",
             "chown ec2-user:ec2-user /home/ec2-user/.ssh/ansible_key",
             "eval $(ssh-agent -s)",
             "ssh-add /home/ec2-user/.ssh/ansible_key"
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

// Sends your public key to the instance
resource "aws_key_pair" "london-region-key-pair" {
    key_name = "london-region-key-pair"
    public_key = "${file(var.PUBLIC_KEY_PATH)}"
}