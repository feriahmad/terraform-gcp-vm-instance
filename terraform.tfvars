# Project and region settings
project_id = "polished-tube-312806"
region     = "us-central1"
zone       = "us-central1-a"

# VM settings
machine_type = "e2-small"

# SSH settings
ssh_username    = "admin"
ssh_pub_key_file = "~/.ssh/id_rsa.pub"
ssh_pub_key     = "" # Will be populated in CI/CD environment or can be set manually
