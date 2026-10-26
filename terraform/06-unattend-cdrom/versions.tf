terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.2"
    }
    # Nouveau dans cette variante : sert à mettre l'Autounattend.xml dans un zip,
    # que hyperv_iso_image transforme ensuite en ISO (voir main.tf).
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
