variable "name_prefix" { type = string }
variable "environment" { type = string }

variable "budget_limit" {
  description = "Monthly hard cap in USD."
  type        = string
  default     = "50"
}

variable "alert_thresholds" {
  description = "ACTUAL-spend alert thresholds as percentages."
  type        = list(number)
  default     = [50, 80, 100]
}

variable "notification_emails" {
  description = "Emails to notify on budget alerts."
  type        = list(string)
}
