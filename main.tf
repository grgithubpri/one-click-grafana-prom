provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Amazon Linux 2023 AMI (x86_64)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, Grafana, Prometheus"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH (lab open)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus (lab)"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  cloud_dir = "${path.module}/cloudinit"

  prometheus_yml            = templatefile("${local.cloud_dir}/prometheus.yml.tftpl", {})
  grafana_datasource_yml    = templatefile("${local.cloud_dir}/grafana-datasource.yaml.tftpl", {})
  grafana_dash_provider_yml = templatefile("${local.cloud_dir}/grafana-dashboards-provider.yaml.tftpl", {})
  dashboard_json            = file("${local.cloud_dir}/dashboard-host-cpu-mem.json")
  grafana_alert_rules_yml   = templatefile("${local.cloud_dir}/grafana-alert-rules.yaml.tftpl", {})

  grafana_contact_points_yml = templatefile("${local.cloud_dir}/grafana-contact-points.yaml.tftpl", {
    enable_email = var.enable_email_contact_point
    email_to     = var.alert_email_to
  })

  grafana_notification_policy_yml = templatefile("${local.cloud_dir}/grafana-notification-policies.yaml.tftpl", {
    enable_email = var.enable_email_contact_point
  })

  docker_compose = templatefile("${local.cloud_dir}/docker-compose.yaml.tftpl", {
    grafana_admin_user     = var.grafana_admin_user
    grafana_admin_password = var.grafana_admin_password

    enable_email  = var.enable_email_contact_point
    smtp_host     = var.smtp_host
    smtp_user     = var.smtp_user
    smtp_password = var.smtp_password
    smtp_from     = var.smtp_from_address
  })

  # IMPORTANT: Use <<EOF (not <<-EOF) and do not indent the shebang.
  user_data = <<EOF
#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "[user-data] Starting bootstrap"

dnf -y update

# Install Docker reliably on AL2023
dnf -y install docker

systemctl enable docker
systemctl start docker

echo "[user-data] Docker installed:"
docker --version

# Install Docker Compose plugin (preferred). If unavailable, fallback to downloading compose plugin.
if dnf -y install docker-compose-plugin; then
  echo "[user-data] docker-compose-plugin installed"
else
  echo "[user-data] docker-compose-plugin not available; installing compose binary fallback"
  dnf -y install curl-minimal || true
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

echo "[user-data] Docker Compose version:"
docker compose version

mkdir -p /opt/monitoring/{prometheus,grafana/provisioning/datasources,grafana/provisioning/dashboards,grafana/provisioning/alerting,dashboards}

cat > /opt/monitoring/prometheus/prometheus.yml <<'PROM'
${local.prometheus_yml}
PROM

cat > /opt/monitoring/grafana/provisioning/datasources/datasource.yaml <<'DS'
${local.grafana_datasource_yml}
DS

cat > /opt/monitoring/grafana/provisioning/dashboards/dashboards.yaml <<'DBP'
${local.grafana_dash_provider_yml}
DBP

cat > /opt/monitoring/dashboards/host_cpu_mem.json <<'DASH'
${local.dashboard_json}
DASH

cat > /opt/monitoring/grafana/provisioning/alerting/alert-rules.yaml <<'AR'
${local.grafana_alert_rules_yml}
AR

cat > /opt/monitoring/grafana/provisioning/alerting/contact-points.yaml <<'CP'
${local.grafana_contact_points_yml}
CP

cat > /opt/monitoring/grafana/provisioning/alerting/notification-policies.yaml <<'NP'
${local.grafana_notification_policy_yml}
NP

cat > /opt/monitoring/docker-compose.yaml <<'DC'
${local.docker_compose}
DC

cd /opt/monitoring

docker compose pull
docker compose up -d

echo "[user-data] Containers:"
docker ps

echo "[user-data] Bootstrap completed"
EOF
}

resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = aws_key_pair.this.key_name

  associate_public_ip_address = true

  # "One click" even if bootstrap changes: instance will be replaced
  user_data_replace_on_change = true
  user_data                  = local.user_data

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}