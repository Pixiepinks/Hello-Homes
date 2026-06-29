<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MetaFeedController;
use App\Http\Controllers\TikTokFeedController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Laravel serves the compiled Hello Homes Flutter web app from public/.
| API routes remain registered separately in routes/api.php under /api.
|
*/

Route::get('/meta-feed.xml', [MetaFeedController::class, 'feed']);
Route::get('/feeds/tiktok.csv', [TikTokFeedController::class, 'feed']);

Route::get('/{path?}', function () {
    $index = public_path('index.html');

    abort_unless(file_exists($index), 503, 'Hello Homes frontend has not been built.');

    return response()->file($index);
})->where('path', '^(?!api(?:/|$)).*');
