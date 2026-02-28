#!/bin/bash
#############################################################
#
# Simple PHP-Proxy for Alwaysdata.com (no V2Ray needed)
#
#############################################################

TMP_DIRECTORY=$(mktemp -d)
URL=${USER}.alwaysdata.net

echo "Downloading proxy.php..."
wget -q -O $TMP_DIRECTORY/proxy.php https://raw.githubusercontent.com/j7me/always/main/proxy.php

mkdir -p $HOME/www
cp $TMP_DIRECTORY/proxy.php $HOME/www/proxy.php

# Создаём простую страницу с настройками
cat > $HOME/www/proxy-info.html<<-EOF
<html>
<head>
<meta charset="utf-8">
<title>PHP Proxy - Alwaysdata</title>
<style>
body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
.box { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
h1 { color: #333; border-bottom: 3px solid #009900; padding-bottom: 10px; }
.code { background: #f0f0f0; padding: 15px; border-radius: 5px; font-family: monospace; font-size: 14px; margin: 15px 0; word-break: break-all; }
.success { color: #009900; font-weight: bold; }
.note { color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="box">
<h1>🌐 PHP HTTP-прокси</h1>
<p class="success">Работает без V2Ray! Только PHP.</p>

<h3>Настройки SwitchyOmega:</h3>
<ul>
<li><b>Протокол:</b> HTTP</li>
<li><b>Сервер:</b> <span class="code">$URL</span></li>
<li><b>Порт:</b> <span class="code">443</span></li>
</ul>

<h3>Или полный URL:</h3>
<div class="code">https://$URL/proxy.php</div>

<p class="note">
<b>Важно:</b> Этот прокси работает через PHP. Скорость может быть ограничена.<br>
Поддерживает HTTP и HTTPS сайты (через CONNECT метод).
</p>
</div>
</body>
</html>
EOF

cat > $HOME/www/index.html<<-EOF
<html><head><title>Alwaysdata</title></head><body><h1>Hello World</h1></body></html>
EOF

rm -rf $TMP_DIRECTORY

clear
echo "=========================================="
echo "  PHP-прокси установлен!"
echo "=========================================="
echo ""
echo "Настройки SwitchyOmega:"
echo "  Protocol: HTTP"
echo "  Server: $URL"
echo "  Port: 443"
echo ""
echo "Информация: https://$URL/proxy-info.html"
echo "=========================================="
