output "internal_sg" {
  value = aws_security_group.internal_sg.id
}
output "load_balancer_sg" {
  value = aws_security_group.load_balancer_sg.id
}
