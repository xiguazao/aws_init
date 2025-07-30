# Web Server Instance
resource "aws_instance" "web" {
  count         = length(var.public_subnet_ids)
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.public_subnet_ids[count.index]
  vpc_security_group_ids = [var.security_group_ids["web"]]

  tags = {
    Name = "${var.project_name}-web-server-az${count.index + 1}"
  }
}

# Application Server Instance
resource "aws_instance" "app" {
  count         = length(var.private_subnet_ids)
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [var.security_group_ids["app"]]

  tags = {
    Name = "${var.project_name}-app-server-az${count.index + 1}"
  }
}