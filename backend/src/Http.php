<?php

final class Http
{
    public static function jsonBody(): array
    {
        $raw = file_get_contents('php://input') ?: '';
        if ($raw === '') {
            return [];
        }
        $data = json_decode($raw, true);
        return is_array($data) ? $data : [];
    }

    /**
     * GET with short timeout and automatic fallback to helper servers.
     * Returns decoded JSON.
     */
    public static function getJson(string $url, array $upstream): mixed
    {
        $hosts = [parse_url($url, PHP_URL_SCHEME) . '://' . parse_url($url, PHP_URL_HOST)];
        foreach ($upstream['helper_servers'] as $helper) {
            $hosts[] = $helper;
        }

        $lastException = null;
        foreach ($hosts as $i => $host) {
            $candidate = $i === 0 ? $url : (string) preg_replace('#^https?://[^/]+#', $host, $url);
            try {
                return self::fetch($candidate, $upstream['timeout']);
            } catch (RuntimeException $e) {
                $lastException = $e;
            }
        }
        throw $lastException ?? new RuntimeException('upstream_unreachable');
    }

    private static function fetch(string $url, int $timeout): mixed
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => $timeout,
            CURLOPT_CONNECTTIMEOUT => $timeout,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_USERAGENT      => 'Shabdiz/1.0',
        ]);
        $body   = curl_exec($ch);
        $status = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        curl_close($ch);

        if ($body === false || $status !== 200) {
            throw new RuntimeException("upstream_status_$status");
        }
        $json = json_decode($body, true);
        if ($json === null && json_last_error() !== JSON_ERROR_NONE) {
            throw new RuntimeException('upstream_bad_json');
        }
        return $json;
    }
}
