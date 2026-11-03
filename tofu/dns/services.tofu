# every name under the agentbox reaches de0, which passes https through to the agentbox's traefik
resource "dns_cname_record" "services" {
  zone = var.agentbox_zone
  name = "*"

  cname = var.agentbox_edge
}
