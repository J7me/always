<?php
define('SOCKS_HOST', '127.0.0.1');
define('SOCKS_PORT', 8500);
define('SOCKS_USER', 'SOCKS_USER_PLACEHOLDER');
define('SOCKS_PASS', 'SOCKS_PASS_PLACEHOLDER');

if ($_SERVER['REQUEST_METHOD'] === 'CONNECT') {
    $target = $_SERVER['REQUEST_URI'];
    handle_connect($target);
} else {
    $host = $_SERVER['HTTP_HOST'] ?? '';
    $port = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 443 : 80;
    handle_http($host, $port, $_SERVER['REQUEST_URI']);
}

function handle_connect($target) {
    list($host, $port) = explode(':', $target);
    $port = intval($port);
    
    $sock = create_socks5_connection($host, $port);
    if (!$sock) {
        header('HTTP/1.1 502 Bad Gateway');
        exit;
    }
    
    header('HTTP/1.1 200 Connection established');
    header('Proxy-Agent: PHP-SOCKS5-Bridge/1.0');
    ob_flush();
    flush();
    
    $local = fopen('php://input', 'r');
    stream_set_blocking($local, false);
    stream_set_blocking($sock, false);
    
    while (!feof($local) && !feof($sock)) {
        if ($data = @fread($local, 8192)) @fwrite($sock, $data);
        if ($data = @fread($sock, 8192)) { echo $data; ob_flush(); flush(); }
        usleep(1000);
    }
    fclose($sock);
}

function handle_http($host, $port, $url) {
    $sock = create_socks5_connection($host, $port);
    if (!$sock) {
        header('HTTP/1.1 502 Bad Gateway');
        exit;
    }
    
    $method = $_SERVER['REQUEST_METHOD'];
    $request = "$method $url HTTP/1.1\r\n";
    
    $skip = ['host', 'connection', 'proxy-connection', 'content-length'];
    foreach ($_SERVER as $key => $value) {
        if (strpos($key, 'HTTP_') === 0) {
            $header = str_replace('_', '-', substr($key, 5));
            if (!in_array(strtolower($header), $skip)) {
                $request .= "$header: $value\r\n";
            }
        }
    }
    $request .= "Host: $host\r\nConnection: close\r\n";
    
    $body = file_get_contents('php://input');
    if ($body) $request .= "Content-Length: " . strlen($body) . "\r\n";
    $request .= "\r\n$body";
    
    fwrite($sock, $request);
    while (!feof($sock)) { echo fread($sock, 8192); flush(); }
    fclose($sock);
}

function create_socks5_connection($target_host, $target_port) {
    $sock = @fsockopen(SOCKS_HOST, SOCKS_PORT, $errno, $errstr, 10);
    if (!$sock) return false;
    
    fwrite($sock, "\x05\x02\x00\x02");
    $resp = fread($sock, 2);
    if (strlen($resp) < 2) { fclose($sock); return false; }
    
    $auth_method = ord($resp[1]);
    if ($auth_method == 0x02) {
        $user = SOCKS_USER;
        $pass = SOCKS_PASS;
        $auth = "\x01" . chr(strlen($user)) . $user . chr(strlen($pass)) . $pass;
        fwrite($sock, $auth);
        $auth_resp = fread($sock, 2);
        if (strlen($auth_resp) < 2 || ord($auth_resp[1]) != 0x00) { fclose($sock); return false; }
    } elseif ($auth_method != 0x00) { fclose($sock); return false; }
    
    $req = "\x05\x01\x00\x03" . chr(strlen($target_host)) . $target_host . pack('n', $target_port);
    fwrite($sock, $req);
    $resp = fread($sock, 10);
    if (strlen($resp) < 10 || ord($resp[1]) != 0x00) { fclose($sock); return false; }
    
    return $sock;
}
?>
