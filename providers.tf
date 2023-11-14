provider "proxmox" {
  # Configuration options
  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  
  pm_tls_insecure = var.pm_tls_insecure
  pm_parallel     = var.pm_parallel
}