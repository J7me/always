#!/bin/bash
#############################################################
#
# V2ray for Alwaysdata.com (VMess + VLESS + HTTP-Proxy via PHP)
#
#############################################################

TMP_DIRECTORY=$(mktemp -d)

UUID=$(grep -o 'UUID=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/UUID=//' | head -1)
VMESS_WSPATH=$(grep -o 'VMESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VMESS_WSPATH=//' | head -1)
VLESS_WSPATH=$(grep -o 'VLESS_WSPATH=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/VLESS_WSPATH=//' | head -1)
SOCKS_USER=$(grep -o 'SOCKS_USER=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/SOCKS_USER=//' | head -1)
SOCKS_PASS=$(grep -o 'SOCKS_PASS=[^ ]*' $HOME/admin/config/apache/sites.conf 2>/dev/null | sed 's/SOCKS_PASS=//' | head -1)

UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
SOCKS_USER=${SOCKS_USER:-'user'}
SOCKS_PASS=${SOCKS_PASS:-'pass123'}
URL=${USER}.alwaysdata.net

echo "Downloading files..."
wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/j7me/always/main/config.json
wget -q -O $TMP_DIRECTORY/v2ray-linux-64.zip https://github.com/v2fly/v2ray-core/releases/download/v4.45.0/v2ray-linux-64.zip
wget -q -O $TMP_DIRECTORY/proxy.php https://raw.githubusercontent.com/j7me/always/main/proxy.php

echo "Extracting V2Ray..."
unzip -oq -d $HOME $TMP_DIRECTORY/v2ray-linux-64.zip v2ray v2ctl geoip.dat geosite.dat geoip-only-cn-private.dat 2>/dev/null || unzip -oq -d $HOME $TMP_DIRECTORY/v2ray-linux-64.zip

sed -i "s#UUID#$UUID#g" $TMP_DIRECTORY/config.json
sed -i "s#VMESS_WSPATH#$VMESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#VLESS_WSPATH#$VLESS_WSPATH#g" $TMP_DIRECTORY/config.json
sed -i "s#SOCKS_USER#$SOCKS_USER#g" $TMP_DIRECTORY/config.json
sed -i "s#SOCKS_PASS#$SOCKS_PASS#g" $TMP_DIRECTORY/config.json

cp $TMP_DIRECTORY/config.json $HOME

sed -i "s#SOCKS_USER_PLACEHOLDER#$SOCKS_USER#g" $TMP_DIRECTORY/proxy.php
sed -i "s#SOCKS_PASS_PLACEHOLDER#$SOCKS_PASS#g" $TMP_DIRECTORY/proxy.php

mkdir -p $HOME/www
cp $TMP_DIRECTORY/proxy.php $HOME/www/proxy.php

rm -rf $TMP_DIRECTORY

Advanced_Settings=$(cat <<-EOF
#UUID=${UUID}
#VMESS_WSPATH=${VMESS_WSPATH}
#VLESS_WSPATH=${VLESS_WSPATH}
#SOCKS_USER=${SOCKS_USER}
#SOCKS_PASS=${SOCKS_PASS}

ProxyRequests off
ProxyPreserveHost On

ProxyPass "${VMESS_WSPATH}" "ws://services-autosyst3m.alwaysdata.net:8300${VMESS_WSPATH}"
ProxyPassReverse "${VMESS_WSPATH}" "ws://services-autosyst3m.alwaysdata.net:8300${VMESS_WSPATH}"

ProxyPass "${VLESS_WSPATH}" "ws://services-autosyst3m.alwaysdata.net:8400${VLESS_WSPATH}"
ProxyPassReverse "${VLESS_WSPATH}" "ws://services-autosyst3m.alwaysdata.net:8400${VLESS_WSPATH}"
EOF
)

vmlink=vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"Alwaysdata-VMess\",\"add\":\"$URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$URL\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\"}" | base64 -w 0)
vllink="vless://"$UUID"@"$URL":443?encryption=none&security=tls&type=ws&host="$URL"&path="$VLESS_WSPATH"#Alwaysdata-VLESS"

if command -v qrencode &> /dev/null; then
    qrencode -o $HOME/www/M$UUID.png "$vmlink" 2>/dev/null
    qrencode -o $HOME/www/L$UUID.png "$vllink" 2>/dev/null
    QM="<div><img src=\"/M$UUID.png\"></div>"
    QL="<div><img src=\"/L$UUID.png\"></div>"
else
    QM="<div>QR недоступен</div>"
    QL="<div>QR недоступен</div>"
fi

cat > $HOME/www/$UUID.html<<-EOF
<html>
<head>
<meta charset="utf-8">
<title>Alwaysdata Proxy</title>
<style>
body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
.section { background: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; }
h2 { color: #333; border-bottom: 2px solid #009900; padding-bottom: 10px; }
.code { background: #f0f0f0; padding: 10px; border-radius: 4px; font-family: monospace; word-break: break-all; }
.success { color: #009900; font-weight: bold; }
</style>
</head>
<body>
<div class="section">
<h2>🔧 VMess</h2>
<div class="code">$vmlink</div>
$QM
</div>
<div class="section">
<h2>🔧 VLESS</h2>
<div class="code">$vllink</div>
$QL
</div>
<div class="section">
<h2>🌐 HTTP-прокси для SwitchyOmega</h2>
<p class="success">Работает напрямую в браузере!</p>
<p><b>Настройки SwitchyOmega:</b></p>
<ul>
<li>Протокол: <b>HTTP</b></li>
<li>Сервер: <b>$URL</b></li>
<li>Порт: <b>443</b></li>
</ul>
</div>
</body>
</html>
EOF

cat > $HOME/www/index.html<<-EOF
<html><head><title>Alwaysdata</title></head><body><h1>Hello World</h1></body></html>
EOF

clear
echo "=========================================="
echo "  УСТАНОВКА ЗАВЕРШЕНА!"
echo "=========================================="
echo ""
echo "SERVICE Command:"
echo "./v2ray -config config.json"
echo ""
echo "Advanced Settings:"
echo "$Advanced_Settings"
echo ""
echo "SwitchyOmega:"
echo "  Protocol: HTTP"
echo "  Server: $URL"
echo "  Port: 443"
echo ""
echo "Информация: https://$URL/$UUID.html"
echo "=========================================="
