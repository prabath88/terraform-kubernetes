resource "aws_instance" "web1" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t2.micro"
    count = "${var.instance_count}"
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
    key_name = "${aws_key_pair.london-region-key-pair.id}"

    provisioner "remote-exec" {
        inline = [
             "sudo apt install git -y",
             "sudo mkdir /tmp/test",
             "touch /tmp/ela",
//             "git clone git@github.com:prabath88/kubernetes.git",
        ]
    }

    connection {
        user = "${var.EC2_USER}"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }

    user_data = <<HEREDOC
    #!/bin/bash
    sudo apt install git -y
    sudo touch /home/kkkkkk
    HEREDOC

}

// Sends your public key to the instance
resource "aws_key_pair" "london-region-key-pair" {
    key_name = "london-region-key-pair"
    public_key = "${file(var.PUBLIC_KEY_PATH)}"
}

