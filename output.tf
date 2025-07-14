output "aws_ami_id" {
  value = data.aws_ami.latest_amazon_linux_image.id
}