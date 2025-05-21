locals {
  region      = "us-east-1"
  name        = "amg-ex-${replace(basename(path.cwd), "_", "-")}"
  description = "AWS Managed Grafana service for ${local.name}"

# VPC
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

# ECS
  container_name = "ecsdemo-loki"
  container_port = 3100

#EC2
  user_data = <<-EOT
    #!/bin/bash
    set -e

    # Actualizar el sistema
    dnf update -y

    # Instalar Java 17 (Amazon Corretto)
    dnf install -y java-17-amazon-corretto

    # Crear usuario y grupo para WildFly
    groupadd -r wildfly
    useradd -r -g wildfly -d /opt/wildfly -s /sbin/nologin wildfly

    # Descargar y descomprimir WildFly
    cd /opt
    wget https://github.com/wildfly/wildfly/releases/download/28.0.0.Final/wildfly-28.0.0.Final.tar.gz
    tar -xvzf wildfly-28.0.0.Final.tar.gz
    ln -s wildfly-28.0.0.Final wildfly
    chown -R wildfly:wildfly /opt/wildfly*

    # Configurar WildFly como servicio systemd
    mkdir -p /etc/wildfly
    cat <<EOF > /etc/wildfly/wildfly.conf
    WILDFLY_HOME="/opt/wildfly"
    WILDFLY_USER="wildfly"
    EOF

    cat <<EOF > /etc/systemd/system/wildfly.service
    [Unit]
    Description=WildFly Application Server
    After=network.target

    [Service]
    Type=simple
    User=wildfly
    Group=wildfly
    ExecStart=/opt/wildfly/bin/standalone.sh -b=0.0.0.0
    ExecStop=/opt/wildfly/bin/jboss-cli.sh --connect command=:shutdown
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    EOF

    # Crear aplicación de ejemplo como WAR válido
    mkdir -p /opt/wildfly/standalone/deployments/sample.war/WEB-INF
    echo "<html><body><h1>Aplicación de ejemplo desplegada automáticamente</h1></body></html>" > /opt/wildfly/standalone/deployments/sample.war/index.html
    touch /opt/wildfly/standalone/deployments/sample.war.dodeploy
    chown -R wildfly:wildfly /opt/wildfly/standalone/deployments

    # Recargar systemd y habilitar WildFly
    systemctl daemon-reload
    systemctl enable wildfly
    systemctl start wildfly

    # Configurar repositorio de Fluent Bit
    cat <<EOF > /etc/yum.repos.d/fluent-bit.repo
    [fluent-bit]
    name=Fluent Bit
    baseurl=https://packages.fluentbit.io/amazonlinux/2023/
    gpgcheck=1
    gpgkey=https://packages.fluentbit.io/fluentbit.key
    enabled=1
    EOF

    # Instalar Fluent Bit
    dnf install -y fluent-bit

    # Crear archivo de configuración para Fluent Bit
    mkdir -p /etc/fluent-bit/
    cat <<EOF > /etc/fluent-bit/fluent-bit.conf
    [SERVICE]
        Flush        5
        Daemon       Off
        Log_Level    info
        Parsers_File parsers.conf

    [INPUT]
        Name         tail
        Path         /opt/wildfly/standalone/log/server.log
        Tag          wildfly
        Refresh_Interval 5
        Read_from_Head true

    [OUTPUT]
        Name         s3
        Match        wildfly
        bucket       simple-bucket987654321
        region       us-east-1
        total_file_size 5M
        upload_timeout 10m
        store_dir    /var/log/fluent-bit/s3
    EOF

    # Crear directorio para almacenamiento temporal de logs
    mkdir -p /var/log/fluent-bit/s3

    # Iniciar y habilitar Fluent Bit
    systemctl enable fluent-bit
    systemctl start fluent-bit

  EOT


  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-manage-service-grafana"
    GithubOrg  = "terraform-aws-modules"
  }
}