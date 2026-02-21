# 🚀 One-Click Grafana + Prometheus on AWS (Terraform + Docker)

![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple)
![AWS](https://img.shields.io/badge/AWS-EC2-orange)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)
![Grafana](https://img.shields.io/badge/Grafana-11.x-F46800)
![Prometheus](https://img.shields.io/badge/Prometheus-2.x-E6522C)

A fully automated, **one-click monitoring stack** deployed on AWS using Terraform.

This project provisions:

- ✅ EC2 (Amazon Linux 2023)
- ✅ Docker
- ✅ Prometheus
- ✅ Node Exporter
- ✅ Grafana
- ✅ Pre-configured dashboards (CPU & Memory)
- ✅ Grafana Alerting (CPU > 80%, Memory > 80%)

No manual configuration required after `terraform apply`.

---

# 🏗 Architecture


AWS EC2 (t3.micro)
│
├── Docker
│ ├── Prometheus
│ ├── Node Exporter
│ └── Grafana
│
└── Security Group (Lab Configuration)
├── 22 → SSH
├── 3000 → Grafana
└── 9090 → Prometheus


Prometheus scrapes:
- Itself
- Node Exporter (host metrics)

Grafana:
- Preconfigured Prometheus datasource
- Dashboard auto-loaded
- Alert rules provisioned via file provisioning

---

# ⚠️ Important: Lab Environment Security

This project is configured for **testing and learning purposes only**.

The following ports are intentionally open to the public (`0.0.0.0/0`):

| Port | Service     | Purpose        |
|------|------------|---------------|
| 22   | SSH        | Remote access |
| 3000 | Grafana    | UI access     |
| 9090 | Prometheus | Lab testing   |

---

## 🔐 Production Security Recommendations

Before using this in production:

- Restrict SSH to your IP address
- Do NOT expose Prometheus publicly
- Restrict Grafana access to VPN / internal network
- Use HTTPS (ALB + ACM)
- Move EC2 into private subnets
- Store secrets in AWS Secrets Manager or SSM
- Enable IAM roles
- Change default credentials immediately

---

# 🔑 Default Grafana Credentials (CHANGE IN PRODUCTION)


Username: admin
Password: adminadmin


Defined in Terraform variables:

```hcl
variable "grafana_admin_user"
variable "grafana_admin_password"

⚠️ These are basic credentials for lab purposes only.

In production:

Use strong passwords

Do not hardcode credentials

Store in a secure secrets manager

Consider SSO (OAuth / SAML)

🔐 Sensitive Variables To Secure in Production

The following variables should never be hardcoded in production:

SMTP (If Email Alerting Enabled)
variable "smtp_host"
variable "smtp_user"
variable "smtp_password"
variable "smtp_from_address"
SSH Public Key
variable "ssh_public_key"
Grafana Admin Password
variable "grafana_admin_password"
🧪 Free Tier Friendly

Default configuration:

t3.micro

12GB gp3 root disk

Docker containers

Local Prometheus storage

Suitable for:

Labs

Demonstrations

Learning Terraform / Monitoring

▶️ Deployment
1️⃣ Clone the repository
git clone git@github.com:grgithubpri/one-click-grafana-prom.git
cd one-click-grafana-prom
2️⃣ Initialize Terraform
terraform init
3️⃣ Deploy
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
4️⃣ Access Services

After deployment:

Grafana:    http://<public_ip>:3000
Prometheus: http://<public_ip>:9090
SSH:        ssh ec2-user@<public_ip>
📊 What Is Automatically Configured

✔ Prometheus datasource
✔ CPU dashboard
✔ Memory dashboard
✔ Alert rules:

CPU > 80%

Memory > 80%

No manual setup required.

🛑 Destroy Environment
terraform destroy
📌 Production Hardening Checklist

Before production use:

 Restrict Security Group ingress rules

 Change Grafana credentials

 Store secrets securely

 Enable HTTPS

 Remove public Prometheus access

 Implement IAM best practices

 Enable CloudWatch monitoring

📖 Project Purpose

This project demonstrates:

Infrastructure as Code (Terraform)

Containerized monitoring

Automated provisioning

File-based Grafana alerting

AWS EC2 infrastructure setup

Designed for:

DevOps portfolio

Cloud learning

Monitoring stack demonstrations

⚠ Disclaimer

This repository is intended for educational and lab use.

It is not production hardened by default.