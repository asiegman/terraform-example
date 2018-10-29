output "bastion_ip" {
  value = "${aws_instance.ssh_bastion.public_ip}"
}
