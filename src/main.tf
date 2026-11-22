
resource "ngrok_domain" "this" {
  for_each = var.domains

  domain      = each.value.domain
  description = each.value.description

  metadata = jsonencode({
    environment = var.environment
    managed_by  = "terraform"
    service     = each.key
  })

  certificate_management_policy {
    authority        = "letsencrypt"
    private_key_type = "ecdsa"
  }
}

resource "ngrok_cloud_endpoint" "this" {
  for_each = var.cloud_endpoints

  url = "https://${ngrok_domain.this[each.key].domain}"

  description = each.value.description

  traffic_policy = jsonencode(each.value.traffic_policy)

  metadata = jsonencode({
    environment = var.environment
    managed_by  = "terraform"
    service     = each.key
  })
}
