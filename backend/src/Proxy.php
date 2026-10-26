<?php

/**
 * Content proxy: forwards whitelisted read-only endpoints to the upstream
 * API with the secret key injected server-side. The client never sees the key.
 */
final class Proxy
{
    public function __construct(private array $upstream) {}

    public function handle(string $method, array $segments, array $query): array
    {
        if ($method !== 'GET') {
            Response::json(['error' => 'method_not_allowed'], 405);
        }
        $path = implode('/', $segments);
        $key  = $this->upstream['api_key'];

        switch ($segments[0]) {
            case 'movies':      // /movies?genre=&filter=&page=
                $url = "{$this->upstream['base_url']}/movie/by/filtres/"
                    . ($query['genre'] ?? 0) . '/' . ($query['filter'] ?? 'created') . '/'
                    . ($query['page'] ?? 0) . "/$key/";
                break;

            case 'series':      // /series?genre=&filter=&page=
                $url = "{$this->upstream['base_url']}/serie/by/filtres/"
                    . ($query['genre'] ?? 0) . '/' . ($query['filter'] ?? 'created') . '/'
                    . ($query['page'] ?? 0) . "/$key/";
                break;

            case 'search':      // /search?q=...
                $q = rawurlencode(trim((string) ($query['q'] ?? '')));
                $url = "{$this->upstream['base_url']}/search/$q/$key/";
                break;

            case 'genres':      // /genres/movie | /genres/serial
                $endpoint = ($segments[1] ?? 'movie') === 'serial' ? '/genre/all/serie' : '/genre/all';
                $url = "{$this->upstream['base_url']}$endpoint/$key";
                break;

            case 'countries':
                $url = "{$this->upstream['base_url']}/country/all/$key/";
                break;

            case 'posters':     // /posters?country=&filter=&page=
                $url = "{$this->upstream['base_url']}/poster/by/filtres/0/"
                    . ($query['country'] ?? 0) . '/' . ($query['filter'] ?? 'created') . '/'
                    . ($query['page'] ?? 0) . "/$key/";
                break;

            case 'seasons':     // /seasons/{seriesId}
                if (!ctype_digit((string) ($segments[1] ?? ''))) {
                    Response::json(['error' => 'invalid_input'], 422);
                }
                $url = "{$this->upstream['base_url']}/season/by/serie/{$segments[1]}/$key/";
                break;

            default:
                Response::json(['error' => 'not_found'], 404);
        }

        try {
            return ['data' => Http::getJson($url, $this->upstream)];
        } catch (RuntimeException $e) {
            error_log('[shabdiz] proxy failed: ' . $e->getMessage() . ' url=' . preg_replace("/$key/", '***', $url));
            Response::json(['error' => 'upstream_unavailable'], 502);
        }
    }
}
