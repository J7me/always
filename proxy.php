<?php
// Простой PHP-HTTP-прокси без внешних зависимостей
// Работает напрямую через fsockopen

error_reporting(0);
set_time_limit(0);

// Получаем целевой URL
if ($_SERVER['REQUEST_METHOD'] === 'CONNECT') {
    // HTTPS-проксирование
    $target = $_SERVER['REQUEST_URI']; // host:port
    list($host, $port) = explode(':', $target);
    $port = intval($port) ?: 443;
    
    // Подключаемся к целевому серверу напрямую
    $remote = @fsockopen($host, $port, $errno, $errstr, 30);
    if (!$remote) {
        header('HTTP/1.1 502 Bad Gateway');
        echo "Cannot connect to $host:$port";
        exit;
    }
    
    // Отправляем успешный ответ клиенту
    header('HTTP/1.1 200 Connection established');
    header('Proxy-Agent: PHP-Proxy/1.0');
    ob_flush();
    flush();
    
    // Туннелируем данные
    $local = fopen('php://input', 'r');
    stream_set_blocking($local, 0);
    stream_set_blocking($remote, 0);
    
    while (!feof($local) && !feof($remote)) {
        if ($data = fread($local, 8192)) {
            fwrite($remote, $data);
        }
        if ($data = fread($remote, 8192)) {
            echo $data;
            ob_flush();
            flush();
        }
        usleep(1000);
    }
    
    fclose($remote);
    
} else {
    // HTTP-проксирование
    $method = $_SERVER['REQUEST_METHOD'];
    $url = $_SERVER['REQUEST_URI'];
    
    // Парсим URL если полный, или используем HOST
    if (strpos($url, 'http') === 0) {
        $parsed = parse_url($url);
        $host = $parsed['host'];
        $port = $parsed['port'] ?? 80;
        $path = $parsed['path'] . (isset($parsed['query']) ? '?' . $parsed['query'] : '');
        $scheme = $parsed['scheme'];
    } else {
        $host = $_SERVER['HTTP_HOST'];
        $port = 80;
        $path = $url;
        $scheme = 'http';
    }
    
    // Для HTTPS через обычный HTTP-прокси (не CONNECT)
    if ($scheme === 'https') {
        $port = 443;
    }
    
    // Подключаемся к целевому серверу
    $remote = @fsockopen($host, $port, $errno, $errstr, 30);
    if (!$remote) {
        header('HTTP/1.1 502 Bad Gateway');
        echo "Cannot connect to $host:$port - $errstr ($errno)";
        exit;
    }
    
    // Формируем HTTP-запрос
    $request = "$method $path HTTP/1.1\r\n";
    
    // Копируем заголовки
    $skip_headers = ['host', 'connection', 'proxy-connection', 'content-length', 'proxy-authorization'];
    foreach ($_SERVER as $key => $value) {
        if (strpos($key, 'HTTP_') === 0) {
            $header_name = str_replace('_', '-', substr($key, 5));
            if (!in_array(strtolower($header_name), $skip_headers)) {
                $request .= "$header_name: $value\r\n";
            }
        }
    }
    
    $request .= "Host: $host\r\n";
    $request .= "Connection: close\r\n";
    
    // Добавляем тело для POST/PUT
    $body = file_get_contents('php://input');
    if ($body) {
        $request .= "Content-Length: " . strlen($body) . "\r\n";
    }
    $request .= "\r\n";
    $request .= $body;
    
    // Отправляем запрос
    fwrite($remote, $request);
    
    // Читаем ответ и отправляем клиенту
    while (!feof($remote)) {
        echo fread($remote, 8192);
        flush();
    }
    
    fclose($remote);
}
?>
