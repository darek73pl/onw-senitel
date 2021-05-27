variable "name" {
  description = "Name prefix to be used on generated resources"
  type        = string
}

variable "ssm_enabled" {
  description = "Should SSM role be attached to profile"
  type        = bool
  default     = false
}
