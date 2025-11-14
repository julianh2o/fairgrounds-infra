terraform {
  required_providers {
    truenas = {
      source = "baladithyab/truenas"
      version = "0.2.22"
    }
  }
}

variable "truenas_api_key" {
  type = string
}

provider "truenas" {
  api_key = var.truenas_api_key
  base_url = "http://truenas/api/v2.0"
}

resource "truenas_user" "julian" {
}