<?php

return [
    'seed_name' => env('ADMIN_SEED_NAME', 'Hello Homes Admin'),
    'seed_email' => env('ADMIN_SEED_EMAIL', 'admin@hellohomes.test'),
    'seed_password' => env('ADMIN_SEED_PASSWORD', 'HelloHomesAdmin!2026'),

    'emails' => array_values(array_filter(array_unique(array_map('trim', array_merge(
        explode(',', env('ADMIN_EMAILS', '')),
        [env('ADMIN_SEED_EMAIL', 'admin@hellohomes.test')]
    ))))),
];
