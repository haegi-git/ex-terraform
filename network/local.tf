locals {
  azs        = data.aws_availability_zones.available_az.names
  tag_header = "${var.default_name}-"
  ami_id     = data.aws_ami.std11_ec2_ami.id
  region     = var.region
}
