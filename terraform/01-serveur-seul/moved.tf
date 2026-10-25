# =============================================================================
# moved.tf : à garder tant qu'un LAB créé avec l'ANCIENNE version (avec for_each)
# existe encore. Sans for_each, l'adresse des ressources change :
#   hyperv_vhd.os["SRV01"]  devient  hyperv_vhd.os
# Sans ces blocs, Terraform croirait qu'il faut détruire l'ancienne VM et en créer
# une nouvelle. Avec eux, il renomme simplement les ressources dans le state.
# Une fois un « terraform apply » passé, ce fichier peut être supprimé.
# =============================================================================

moved {
  from = hyperv_vhd.os["SRV01"]
  to   = hyperv_vhd.os
}

moved {
  from = hyperv_machine_instance.vm["SRV01"]
  to   = hyperv_machine_instance.vm
}

moved {
  from = terraform_data.configuration["SRV01"]
  to   = terraform_data.configuration
}
