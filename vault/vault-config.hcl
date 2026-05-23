# ============================================
# VAULT CONFIGURATION
# Runs in dev mode on GitHub Actions
# ============================================

storage "inmem" {}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://0.0.0.0:8200"
ui       = false
log_level = "warn"