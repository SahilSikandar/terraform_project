output "instance_id" {
    value = aws_instance.test-server-1.public_ip
  
}
output "instance_id2" {
    value = aws_instance.test-server-2.public_ip
  
}
output "public_ip" {
    value = aws_iam_access_key.s3_user_key.id
  
}
output "secret_key" {
    value = aws_iam_access_key.s3_user_key.secret
     sensitive = true
}
output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}