
variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "domains" {
  description = "Domains to reserve in ngrok."

  type = map(object({
    domain      = string
    description = optional(string, "")
  }))
}

variable "cloud_endpoints" {
  description = "Cloud endpoints and their traffic policies."

  type = map(object({
    description    = optional(string, "")
    traffic_policy = any
  }))

  default = {}
}
