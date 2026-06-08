#!/bin/bash
# Módulo Xray para SSH_AVG
# Coexiste con V2Ray sin interferir

 RUTA_CONFIG="/etc/xray/config.json"
 RUTA_BIN="/usr/local/bin/xray"

install_xray() {
    echo -e "\n=== INSTALANDO XRAY CORE ==="
    apt-get update -y && apt-get install -y curl unzip -y
    
    # Descargar la última versión oficial de Xray Core
    curl -L -s https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o /tmp/xray.zip
    mkdir -p /etc/xray /usr/local/bin
    unzip -o /tmp/xray.zip xray -d /usr/local/bin/
    chmod +x $RUTA_BIN
    rm -f /tmp/xray.zip

    # Crear una configuración por defecto segura (VLESS + WebSocket)
    # Usamos el puerto 8085 para que NO choque con el de V2Ray
    cat > $RUTA_CONFIG << 'EOF'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 8085,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/xray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
    mkdir -p /var/log/xray

    # Crear el servicio independiente en systemd
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service por SSH_AVG
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartSec=10
LimitNOFILE=500000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray
    echo -e "=== XRAY INSTALADO Y LEVANTADO EN PUERTO 8085 ==="
}

status_xray() {
    if systemctl is-active --quiet xray; then
        echo "XRAY:activo"
    else
        echo "XRAY:inactivo"
    fi
}

# Control de argumentos para llamadas rápidas desde el panel o menú interno
case "$1" in
    install) install_xray ;;
    status) status_xray ;;
    start) systemctl start xray ;;
    stop) systemctl stop xray ;;
    restart) systemctl restart xray ;;
    *) echo "Uso: $0 {install|status|start|stop|restart}" ;;
esac