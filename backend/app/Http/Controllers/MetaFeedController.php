<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;
use XMLWriter;

class MetaFeedController extends Controller
{
    private const CACHE_KEY = 'meta_catalog_feed_xml';
    private const META_KEY = 'meta_catalog_feed_meta';
    private const CACHE_SECONDS = 3600;
    private const PRODUCTION_APP_URL = 'https://hellohomes.lk';

    public function feed(Request $request)
    {
        $xml = Cache::get(self::CACHE_KEY);
        $baseUrl = $this->baseUrl($request);

        if (!is_string($xml) || $xml === '' || str_contains($xml, 'localhost') || !str_contains($xml, $baseUrl)) {
            $xml = $this->buildFeed($request);
            Cache::put(self::CACHE_KEY, $xml, self::CACHE_SECONDS);
        }

        return response($xml, 200, [
            'Content-Type' => 'application/xml; charset=UTF-8',
            'Cache-Control' => 'public, max-age=' . self::CACHE_SECONDS,
        ]);
    }

    public function status(Request $request)
    {
        return response()->json($this->metadata($request));
    }

    public function regenerate(Request $request)
    {
        Cache::forget(self::CACHE_KEY);
        Cache::put(self::CACHE_KEY, $this->buildFeed($request), self::CACHE_SECONDS);

        return response()->json($this->metadata($request));
    }

    private function buildFeed(Request $request): string
    {
        $products = $this->feedQuery()->get();
        $baseUrl = $this->baseUrl($request);

        $writer = new XMLWriter();
        $writer->openMemory();
        $writer->startDocument('1.0', 'UTF-8');
        $writer->startElement('rss');
        $writer->writeAttribute('version', '2.0');
        $writer->writeAttribute('xmlns:g', 'http://base.google.com/ns/1.0');
        $writer->startElement('channel');
        $writer->writeElement('title', 'Hello Homes Product Catalog');
        $writer->writeElement('link', $baseUrl);
        $writer->writeElement('description', 'Hello Homes Meta Commerce Manager catalog feed');

        foreach ($products as $product) {
            $images = $this->imageUrls($product, $baseUrl);
            if (empty($images) || !$this->hasValidPrice($product->price)) {
                continue;
            }

            $writer->startElement('item');
            $writer->writeElement('g:id', (string) $product->id);
            $writer->writeElement('title', $this->cleanText($product->title));
            $writer->writeElement('description', $this->cleanText($product->subtitle ?: $product->title));
            $writer->writeElement('link', $baseUrl . '/product/' . rawurlencode((string) $product->id));
            $writer->writeElement('g:image_link', $images[0]);
            foreach (array_slice($images, 1) as $image) {
                $writer->writeElement('g:additional_image_link', $image);
            }
            $writer->writeElement('g:availability', 'in stock');
            $writer->writeElement('g:condition', 'new');
            if ($this->hasSalePrice($product)) {
                $writer->writeElement('g:price', $this->formatPrice($product->original_price));
                $writer->writeElement('g:sale_price', $this->formatPrice($product->price));
            } else {
                $writer->writeElement('g:price', $this->formatPrice($product->price));
            }
            $writer->writeElement('g:brand', $this->cleanText($product->brand?->name ?: 'Hello Homes'));
            $writer->writeElement('g:product_type', $this->productType($product));
            $googleCategory = $this->googleProductCategory($product);
            if ($googleCategory !== '') {
                $writer->writeElement('g:google_product_category', $googleCategory);
            }
            $writer->endElement();
        }

        $writer->endElement();
        $writer->endElement();
        $writer->endDocument();
        $xml = $writer->outputMemory();

        Cache::put(self::META_KEY, [
            'feed_url' => $baseUrl . '/meta-feed.xml',
            'last_generation_time' => now()->toIso8601String(),
            'product_count' => $products->filter(fn ($product) => !empty($this->imageUrls($product, $baseUrl)) && $this->hasValidPrice($product->price))->count(),
        ], self::CACHE_SECONDS);

        return $xml;
    }

    private function metadata(Request $request): array
    {
        $baseUrl = $this->baseUrl($request);
        $metadata = Cache::get(self::META_KEY, []);

        return [
            'feed_url' => $baseUrl . '/meta-feed.xml',
            'last_generation_time' => $metadata['last_generation_time'] ?? null,
            'product_count' => $metadata['product_count'] ?? $this->feedQuery()->count(),
        ];
    }

    private function baseUrl(Request $request): string
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

    private function feedQuery()
    {
        $query = Product::with(['category', 'subcategory', 'childCategory', 'brand'])
            ->whereNotNull('image_url')
            ->where('image_url', '!=', '');

        if (Schema::hasColumn('products', 'is_active')) {
            $query->where('is_active', true);
        }
        if (Schema::hasColumn('products', 'status')) {
            $query->whereNotIn('status', ['draft', 'hidden', 'disabled', 'inactive']);
        }
        if (Schema::hasColumn('products', 'stock_quantity')) {
            $query->where('stock_quantity', '>', 0);
        }

        return $query->orderBy('id');
    }

    private function imageUrls(Product $product, string $baseUrl): array
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

    private function httpsUrl(string $url, string $baseUrl = ''): string
    {
        $url = trim($url);
        if ($url === '') return '';
        if (str_starts_with($url, '//')) $url = 'https:' . $url;
        if (!preg_match('#^https?://#i', $url)) $url = rtrim($baseUrl, '/') . '/' . ltrim($url, '/');
        return preg_replace('#^http://#i', 'https://', $url);
    }

    private function formatPrice($price): string
    {
        return number_format((float) $price, 2, '.', '') . ' LKR';
    }

    private function hasValidPrice($price): bool
    {
        return $price !== null && is_numeric($price) && (float) $price > 0;
    }

    private function hasSalePrice(Product $product): bool
    {
        return $product->original_price !== null
            && $this->hasValidPrice($product->price)
            && is_numeric($product->original_price)
            && (float) $product->original_price > (float) $product->price;
    }

    private function productType(Product $product): string
    {
        return collect([$product->category?->title, $product->subcategory?->name, $product->childCategory?->name])
            ->filter()->map(fn ($part) => $this->cleanText($part))->implode(' > ');
    }

    private function googleProductCategory(Product $product): string
    {
        foreach ([$product->childCategory, $product->subcategory, $product->category] as $category) {
            if ($category && isset($category->google_product_category) && trim((string) $category->google_product_category) !== '') {
                return $this->cleanText($category->google_product_category);
            }
        }
        return '';
    }

    private function cleanText(?string $text): string
    {
        return trim(preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', mb_convert_encoding((string) $text, 'UTF-8', 'UTF-8')));
    }
}
