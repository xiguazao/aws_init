output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    web = aws_security_group.web.id
    app = aws_security_group.app.id
    db  = aws_security_group.db.id
  }
}