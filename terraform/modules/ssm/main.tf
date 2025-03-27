resource "aws_ssm_parameter" "min_score_threshold" {
  name  = "/bordercontrol/config/min_score"
  type  = "String"
  value = "10"
}

resource "aws_ssm_parameter" "debug_mode" {
  name  = "/bordercontrol/config/debug"
  type  = "String"
  value = "false"
}

resource "aws_ssm_parameter" "allowed_countries" {
  name  = "/bordercontrol/config/allowed_countries"
  type  = "StringList"
  value = "CZ,SK,DE,PL"
}

output "config_params" {
  value = {
    min_score        = aws_ssm_parameter.min_score_threshold.name
    debug_mode       = aws_ssm_parameter.debug_mode.name
    allowed_countries = aws_ssm_parameter.allowed_countries.name
  }
}
