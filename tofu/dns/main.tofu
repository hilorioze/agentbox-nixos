terraform {
  required_providers {
    dns = {
      source = "hashicorp/dns"
    }
  }
}

# set through `TF_VAR_*` by `host/features/network/dns-update.nix`; run tofu inside the agentbox
variable "agentbox_update_server" {
  type = string
}

variable "agentbox_tsig_key_name" {
  type = string
}

variable "agentbox_tsig_secret_file" {
  type = string
}

variable "agentbox_zone" {
  type = string
}

variable "agentbox_edge" {
  type = string
}

provider "dns" {
  update {
    server = var.agentbox_update_server

    key_name = var.agentbox_tsig_key_name

    key_algorithm = "hmac-sha256"

    key_secret = trimspace(file(var.agentbox_tsig_secret_file))
  }
}
