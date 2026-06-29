<?php

namespace App\Services\Feeds;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

/**
 * Shared catalog feed architecture for commerce channels.
 *
 * Meta and TikTok intentionally resolve products through this one service so both
 * feeds stay synchronized on business rules: active website-visible products,
 * valid prices, valid public images, stock availability, sale-price decisions,
 * category mapping, and URL/image generation. Future feeds such as Google
 * Merchant Center or Pinterest should add format-specific renderers/controllers
 * while continuing to call catalogProducts() and the mapping helpers here.
 */
class CatalogFeedService
{
    private const PRODUCTION_APP_URL = 'https://hellohomes.lk';

    public function catalogProducts(string $baseUrl)
    {
        return $this->feedQuery()->get()
            ->filter(fn (Product $product) => $this->isFeedEligible($product, $baseUrl))
            ->values();
    }

    public function feedQuery()
    {
        $query = Product::with(['category', 'subcategory', 'childCategory', 'brand'])
            ->whereNotNull('image_url')
            ->where('image_url', '!=', '');

        if (Schema::hasColumn('products', 'is_active')) {
            $query->where('is_active', true);
        }
        if (Schema::hasColumn('products', 'status')) {
            $query->whereNotIn('status', ['draft', 'hidden', 'disabled', 'inactive', 'deleted']);
        }
        if (Schema::hasColumn('products', 'stock_quantity')) {
            $query->where('stock_quantity', '>', 0);
        }
        if (Schema::hasColumn('products', 'deleted_at')) {
            $query->whereNull('deleted_at');
        }

        return $query->orderBy('id');
    }

    public function isFeedEligible(Product $product, string $baseUrl): bool
    {
        return $this->hasValidPrice($product->price) && !empty($this->imageUrls($product, $baseUrl));
    }

    public function baseUrl(Request $request): string
    {
        $configuredUrl = config('app.url');
        $candidate = is_string($configuredUrl) && trim($configuredUrl) !== ''
            ? $configuredUrl
            : $request->getSchemeAndHttpHost();

        $baseUrl = $this->httpsUrl($candidate);
        $host = parse_url($baseUrl, PHP_URL_HOST);

        if (!$host || in_array(strtolower($host), ['localhost', '127.0.0.1', '::1'], true)) {
            return self::PRODUCTION_APP_URL;
        }

        return rtrim($baseUrl, '/');
    }

    public function imageUrls(Product $product, string $baseUrl): array
    {
        $urls = array_filter(array_merge([$product->image_url], is_array($product->images) ? $product->images : []));
        $absolute = [];
        foreach ($urls as $url) {
            $https = $this->httpsUrl((string) $url, $baseUrl);
            if ($https !== '' && !in_array($https, $absolute, true)) {
                $absolute[] = $https;
            }
        }
        return $absolute;
    }

    public function httpsUrl(string $url, string $baseUrl = ''): string
    {
        $url = trim($url);
        if ($url === '') return '';
        if (str_starts_with($url, '//')) $url = 'https:' . $url;
        if (!preg_match('#^https?://#i', $url)) $url = rtrim($baseUrl, '/') . '/' . ltrim($url, '/');
        return preg_replace('#^http://#i', 'https://', $url);
    }

    public function formatPrice($price): string
    {
        return number_format((float) $price, 2, '.', '') . ' LKR';
    }

    public function hasValidPrice($price): bool
    {
        return $price !== null && is_numeric($price) && (float) $price > 0;
    }

    public function hasSalePrice(Product $product): bool
    {
        return $product->original_price !== null
            && $this->hasValidPrice($product->price)
            && is_numeric($product->original_price)
            && (float) $product->original_price > (float) $product->price;
    }

    public function productUrl(Product $product, string $baseUrl): string
    {
        return $baseUrl . '/product/' . rawurlencode((string) $product->id);
    }

    public function productType(Product $product): string
    {
        return collect([$product->category?->title, $product->subcategory?->name, $product->childCategory?->name])
            ->filter()->map(fn ($part) => $this->plainText($part))->implode(' > ');
    }

    public function googleProductCategory(Product $product): string
    {
        foreach ([$product->childCategory, $product->subcategory, $product->category] as $category) {
            if ($category && isset($category->google_product_category) && trim((string) $category->google_product_category) !== '') {
                return $this->plainText($category->google_product_category);
            }
        }
        return '';
    }

    public function brand(Product $product): string
    {
        return $this->plainText($product->brand?->name ?: 'Hello Homes');
    }

    public function description(Product $product): string
    {
        return $this->plainText($product->subtitle ?: $product->title);
    }

    public function plainText(?string $text, ?int $limit = null): string
    {
        $text = html_entity_decode(strip_tags((string) $text), ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $text = trim(preg_replace('/\s+/u', ' ', $text));
        $text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', mb_convert_encoding($text, 'UTF-8', 'UTF-8'));

        if ($limit !== null && mb_strlen($text) > $limit) {
            return rtrim(mb_substr($text, 0, $limit));
        }

        return $text;
    }
}
