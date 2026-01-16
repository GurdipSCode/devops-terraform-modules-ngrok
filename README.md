# devops-terraform-modules-ngrok

[![OpenTofu](https://img.shields.io/badge/OpenTofu-FFDA18?logo=opentofu&logoColor=black)](https://opentofu.org/)
[![ngrok](https://img.shields.io/badge/ngrok-1F1E37?logo=ngrok&logoColor=white)](https://ngrok.com)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/your-org/terraform-ngrok-module?color=green)](https://github.com/your-org/terraform-ngrok-module/releases)

[![Buildkite](https://img.shields.io/buildkite/your-buildkite-badge-id/main?logo=buildkite&label=build)](https://buildkite.com/your-org/terraform-ngrok-module)
[![CodeRabbit](https://img.shields.io/badge/CodeRabbit-Enabled-blue?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTEyIDRjLTQuNDIgMC04IDMuNTgtOCA4czMuNTggOCA4IDggOC0zLjU4IDgtOC0zLjU4LTgtOC04eiIvPjwvc3ZnPg==)](https://coderabbit.ai)
[![Security](https://img.shields.io/badge/Security-Trivy-1904DA?logo=aquasecurity&logoColor=white)](https://trivy.dev/)
[![Checkov](https://img.shields.io/badge/Checkov-Passing-4CAF50?logo=paloaltonetworks&logoColor=white)](https://www.checkov.io/)

---

OpenTofu module for managing [ngrok](https://ngrok.com) resources including tunnels, domains, edges, endpoints, and IP policies.

## ✨ Features

- 🚇 Create and manage ngrok tunnels
- 🌐 Configure custom domains and reserved addresses
- 🔀 Set up edges (HTTPS, TCP, TLS)
- 🔐 Manage IP policies and restrictions
- 🔑 Create and rotate API keys and credentials
- 📊 Configure traffic policies and backends
- 🛡️ Set up OAuth, OIDC, and SAML authentication

## 📋 Requirements

| Name | Version |
|------|---------|
| ![OpenTofu](https://img.shields.io/badge/-OpenTofu-FFDA18?logo=opentofu&logoColor=black&style=flat-square) | `>= 1.6.0` |
| ![ngrok](https://img.shields.io/badge/-ngrok-1F1E37?logo=ngrok&logoColor=white&style=flat-square) | `>= 0.1.0` |

## 🚀 Usage

### Basic Reserved Domain

```hcl
module "ngrok" {
  source  = "your-org/ngrok/ngrok"
  version = "1.0.0"

  domains = {
    api = {
      name        = "api.example.ngrok.app"
      description = "API endpoint"
    }
  }
}
```

### HTTPS Edge with Domain

```hcl
module "ngrok" {
  source  = "your-org/ngrok/ngrok"
  version = "1.0.0"

  domains = {
    app = {
      name        = "app.example.ngrok.app"
      description = "Main application endpoint"
    }
  }

  https_edges = {
    app_edge = {
      description = "Application HTTPS edge"
      hostports   = ["app.example.ngrok.app:443"]

      routes = [
        {
          match      = "/"
          match_type = "path_prefix"
          backend = {
            type    = "tunnel_group"
            labels  = { app = "web" }
          }
        }
      ]
    }
  }
}
```

### Complete Example

```hcl
module "ngrok" {
  source  = "your-org/ngrok/ngrok"
  version = "1.0.0"

  # 🌐 Reserved Domains
  domains = {
    api_prod = {
      name        = "api.example.ngrok.app"
      description = "Production API"
      region      = "us"
    }
    api_staging = {
      name        = "api-staging.example.ngrok.app"
      description = "Staging API"
      region      = "us"
    }
    webhooks = {
      name        = "webhooks.example.ngrok.app"
      description = "Webhook receiver"
      region      = "us"
    }
  }

  # 📍 Reserved Addresses (TCP)
  tcp_addresses = {
    database = {
      description = "Database tunnel"
      region      = "us"
    }
    ssh = {
      description = "SSH bastion"
      region      = "us"
    }
  }

  # 🔀 HTTPS Edges
  https_edges = {
    api_edge = {
      description = "API HTTPS edge"
      hostports   = ["api.example.ngrok.app:443"]

      mutual_tls = {
        enabled = true
        ca_ids  = [var.client_ca_id]
      }

      routes = [
        {
          match      = "/v1"
          match_type = "path_prefix"
          backend = {
            type   = "tunnel_group"
            labels = { service = "api-v1" }
          }
          compression = { enabled = true }
          circuit_breaker = {
            threshold         = 0.5
            num_buckets       = 10
            interval_seconds  = 10
            tripped_duration  = 30
          }
        },
        {
          match      = "/v2"
          match_type = "path_prefix"
          backend = {
            type   = "tunnel_group"
            labels = { service = "api-v2" }
          }
          rate_limit = {
            algorithm  = "sliding_window"
            rate       = 100
            per_second = 60
          }
        },
        {
          match      = "/health"
          match_type = "exact_path"
          backend = {
            type   = "tunnel_group"
            labels = { service = "health" }
          }
        }
      ]
    }

    webhooks_edge = {
      description = "Webhooks HTTPS edge"
      hostports   = ["webhooks.example.ngrok.app:443"]

      routes = [
        {
          match      = "/github"
          match_type = "path_prefix"
          backend = {
            type   = "tunnel_group"
            labels = { webhook = "github" }
          }
          webhook_verification = {
            provider = "github"
            secret   = var.github_webhook_secret
          }
        },
        {
          match      = "/stripe"
          match_type = "path_prefix"
          backend = {
            type   = "tunnel_group"
            labels = { webhook = "stripe" }
          }
          webhook_verification = {
            provider = "stripe"
            secret   = var.stripe_webhook_secret
          }
        }
      ]
    }
  }

  # 🔌 TCP Edges
  tcp_edges = {
    database_edge = {
      description = "Database TCP edge"
      address_ids = ["database"]

      backend = {
        type   = "tunnel_group"
        labels = { service = "postgres" }
      }

      ip_restriction = {
        policy_ids = ["office_ips"]
      }
    }

    ssh_edge = {
      description = "SSH TCP edge"
      address_ids = ["ssh"]

      backend = {
        type   = "tunnel_group"
        labels = { service = "ssh-bastion" }
      }

      ip_restriction = {
        policy_ids = ["office_ips", "vpn_ips"]
      }
    }
  }

  # 🛡️ IP Policies
  ip_policies = {
    office_ips = {
      description = "Office IP addresses"
      action      = "allow"

      rules = [
        {
          cidr        = "203.0.113.0/24"
          description = "Main office"
        },
        {
          cidr        = "198.51.100.0/24"
          description = "Branch office"
        }
      ]
    }
    vpn_ips = {
      description = "VPN egress IPs"
      action      = "allow"

      rules = [
        {
          cidr        = "192.0.2.0/24"
          description = "VPN cluster"
        }
      ]
    }
    blocked = {
      description = "Blocked IPs"
      action      = "deny"

      rules = [
        {
          cidr        = "10.0.0.0/8"
          description = "Private range"
        }
      ]
    }
  }

  # 🔑 Credentials
  credentials = {
    ci_tunnel = {
      description = "CI/CD tunnel credential"
      acl         = ["bind:*.example.ngrok.app"]
    }
    agent_prod = {
      description = "Production agent credential"
      acl         = ["bind:api.example.ngrok.app", "bind:webhooks.example.ngrok.app"]
    }
  }

  # 🔐 API Keys
  api_keys = {
    terraform = {
      description = "Terraform automation"
      owner_id    = var.owner_id
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
    ManagedBy   = "opentofu"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `domains` | Map of reserved domains to create | `map(object({ name = string, description = string, region = optional(string) }))` | `{}` | no |
| `tcp_addresses` | Map of reserved TCP addresses to create | `map(object({ description = string, region = string }))` | `{}` | no |
| `https_edges` | Map of HTTPS edges to create | `map(object({ description = string, hostports = list(string), routes = list(any) }))` | `{}` | no |
| `tcp_edges` | Map of TCP edges to create | `map(object({ description = string, address_ids = list(string), backend = object }))` | `{}` | no |
| `ip_policies` | Map of IP policies to create | `map(object({ description = string, action = string, rules = list(object({ cidr = string, description = string })) }))` | `{}` | no |
| `credentials` | Map of tunnel credentials to create | `map(object({ description = string, acl = list(string) }))` | `{}` | no |
| `api_keys` | Map of API keys to create | `map(object({ description = string, owner_id = string }))` | `{}` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| `domain_ids` | Map of domain names to their IDs |
| `domain_urls` | Map of domain names to their URLs |
| `tcp_address_ids` | Map of TCP address names to their IDs |
| `tcp_addresses` | Map of TCP address names to their addresses |
| `https_edge_ids` | Map of HTTPS edge names to their IDs |
| `tcp_edge_ids` | Map of TCP edge names to their IDs |
| `credential_ids` | Map of credential names to their IDs |
| `credential_tokens` | Map of credential names to their tokens (sensitive) |
| `api_key_ids` | Map of API key names to their IDs |
| `api_key_tokens` | Map of API key names to their tokens (sensitive) |
<!-- END_TF_DOCS -->

## ⚙️ Provider Configuration

Configure the ngrok provider in your root module:

```hcl
terraform {
  required_providers {
    ngrok = {
      source  = "ngrok/ngrok"
      version = "~> 0.1.0"
    }
  }
}

provider "ngrok" {
  api_key = var.ngrok_api_key  # Or set NGROK_API_KEY env var
}
```

## 📂 Examples

| Example | Description |
|---------|-------------|
| [🟢 Basic](./examples/basic) | Simple domain and tunnel setup |
| [🔵 Complete](./examples/complete) | Full configuration with edges and policies |
| [🟣 Webhooks](./examples/webhooks) | Webhook receiver with verification |
| [🟠 TCP Tunnels](./examples/tcp) | Database and SSH tunnels |
| [🔴 OAuth](./examples/oauth) | OAuth/OIDC protected endpoints |

## 🔒 Security Considerations

> ⚠️ **Important Security Notes**

| Item | Recommendation |
|------|----------------|
| 🔑 API Keys | Store in Vault or secure secrets manager |
| 🔐 Credentials | Use ACLs to restrict tunnel bindings |
| 🛡️ IP Policies | Whitelist known IPs for sensitive endpoints |
| 🔒 mTLS | Enable mutual TLS for API endpoints |
| 📋 Webhooks | Always verify webhook signatures |
| 🚫 Rate Limits | Configure rate limiting to prevent abuse |

## 🔄 Migration Guide

### v0.x → v1.0

> ⚠️ **Breaking changes in v1.0**

| Change | Before (v0.x) | After (v1.0) |
|--------|---------------|--------------|
| Domains | `domain` | `domains` (map) |
| Edges | `edge` | `https_edges` / `tcp_edges` (map) |
| Policies | `ip_policy` | `ip_policies` (map) |

```hcl
# ❌ Before (v0.x)
module "ngrok" {
  source      = "your-org/ngrok/ngrok"
  version     = "0.5.0"
  domain_name = "api.example.ngrok.app"
}

# ✅ After (v1.0)
module "ngrok" {
  source  = "your-org/ngrok/ngrok"
  version = "1.0.0"
  domains = {
    api = {
      name        = "api.example.ngrok.app"
      description = "API endpoint"
    }
  }
}
```

## 🤝 Contributing

1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feat/new-feature`)
3. 💾 Commit changes using [Conventional Commits](https://www.conventionalcommits.org/)
4. 📤 Push to the branch (`git push origin feat/new-feature`)
5. 🔃 Open a Pull Request

### 📝 Commit Message Format

```
<type>(<scope>): <description>
```

| Type | Description |
|------|-------------|
| `feat` | ✨ New feature |
| `fix` | 🐛 Bug fix |
| `docs` | 📚 Documentation |
| `refactor` | ♻️ Code refactoring |
| `test` | 🧪 Tests |
| `chore` | 🔧 Maintenance |

**Scopes:** `domains`, `edges`, `tunnels`, `policies`, `credentials`, `examples`, `docs`

### 🛠️ Local Development

```bash
# 🎨 Format code
tofu fmt -recursive

# ✅ Validate
tofu validate

# 📖 Generate docs
terraform-docs markdown table . > README.md

# 🧪 Run tests
cd examples/basic && tofu init && tofu plan
```

## 📄 License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Apache 2.0 - See [LICENSE](LICENSE) for details.

## 👥 Authors

Maintained by **Your Organization**.

## 🔗 Related

| Resource | Link |
|----------|------|
| 📖 ngrok Documentation | [ngrok.com/docs](https://ngrok.com/docs) |
| 🔌 ngrok Provider | [Registry](https://registry.terraform.io/providers/ngrok/ngrok/latest/docs) |
| 🔧 ngrok API | [API Docs](https://ngrok.com/docs/api) |
| 🚇 Traffic Policy | [Policy Reference](https://ngrok.com/docs/http/traffic-policy/) |
| 🔐 Authentication | [Auth Docs](https://ngrok.com/docs/http/oauth/) |
| 🟡 OpenTofu | [opentofu.org](https://opentofu.org/) |
| 🟢 Buildkite | [buildkite.com](https://buildkite.com/) |

---

<p align="center">
  <sub>Built with ❤️ using <img src="https://img.shields.io/badge/-OpenTofu-FFDA18?logo=opentofu&logoColor=black&style=flat-square" alt="OpenTofu" /> and <img src="https://img.shields.io/badge/-Buildkite-14CC80?logo=buildkite&logoColor=white&style=flat-square" alt="Buildkite" /></sub>
</p>
