variable "DeploymentRegion" {
  default = "eu-north-1"
  type    = string
}

variable "DeploymentName" {
  default = "Rad-Lab"
  type    = string
}


variable "S3BucketName" {
  default = "changeme"
  type    = string
}

variable "ProjectName" {
  default     = "chamgeme"
  type        = string
  description = "Top level folder in S3"
}


variable "LogGroupCount" {
  default     = 10
  type        = number
  description = "Top level folder in S3"
}

variable "LogGroupPrefix" {
  default     = "/some/path/to/RadLog"
  type        = string
  description = "Prefix to be used to create log groups"
}

variable "LogRetention" {
  default     = 120
  type        = number
  description = "Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0"
}
