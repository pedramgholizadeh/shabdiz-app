<?php

declare(strict_types=1);

namespace Shabdiz\Core;

final class View
{
    /** @param array<string, mixed> $data */
    public static function render(string $template, array $data = [], ?string $layout = 'layout'): never
    {
        $file = SHABDIZ_ROOT . '/app/Views/' . $template . '.php';
        if (!is_file($file)) {
            Response::html('View not found: ' . e($template), 500);
        }
        extract($data, EXTR_SKIP);
        ob_start();
        require $file;
        $content = (string) ob_get_clean();

        if ($layout === null) {
            Response::html($content);
        }

        require SHABDIZ_ROOT . '/app/Views/' . $layout . '.php';
        exit;
    }
}
