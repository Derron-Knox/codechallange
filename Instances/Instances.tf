#Get Linux AMI ID using SSM Parameter endpoint in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


#Create and bootstrap docker EC2
resource "aws_instance" "docker" {
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance-type
  key_name                    = "terraform"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  subnet_id                   = aws_subnet.pubsub-1.id
  user_data                   = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y docker
                service docker start
                docker run -it --rm -d -p 8080:80 --name web nginx
              EOF

  tags = {
    Name = "docker"
  }

}