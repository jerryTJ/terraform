output "config" {
  value ={
    password = aws_iam_user_login_profile.login_profile.password
    encrypted_password = aws_iam_user_login_profile.login_profile.encrypted_password
    access_key_id = aws_iam_access_key.user_access_key.id
    access_key_secret = aws_iam_access_key.user_access_key.secret
  }
  sensitive = true
 
}
