<?php

namespace App\Http\Controllers;

use App\Services\Feeds\CatalogFeedService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use XMLWriter;

class MetaFeedController extends Controller
{
    private const CACHE_KEY = 'meta_catalog_feed_xml';
    private const META_KEY = 'meta_catalog_feed_meta';
    private const CACHE_SECONDS = 3600;

    public function __construct(private readonly CatalogFeedService $feeds) {}

    public function feed(Request $request)
    {
        $xml = Cache::get(self::CACHE_KEY);
        $baseUrl = $this->feeds->baseUrl($request);

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
        $baseUrl = $this->feeds->baseUrl($request);
        $products = $this->feeds->catalogProducts($baseUrl);

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
            $images = $this->feeds->imageUrls($product, $baseUrl);

            $writer->startElement('item');
            $writer->writeElement('g:id', (string) $product->id);
            $writer->writeElement('title', $this->feeds->plainText($product->title));
            $writer->writeElement('description', $this->feeds->description($product));
            $writer->writeElement('link', $this->feeds->productUrl($product, $baseUrl));
            $writer->writeElement('g:image_link', $images[0]);
            foreach (array_slice($images, 1) as $image) {
                $writer->writeElement('g:additional_image_link', $image);
            }
            $writer->writeElement('g:availability', 'in stock');
            $writer->writeElement('g:condition', 'new');
            if ($this->feeds->hasSalePrice($product)) {
                $writer->writeElement('g:price', $this->feeds->formatPrice($product->original_price));
                $writer->writeElement('g:sale_price', $this->feeds->formatPrice($product->price));
            } else {
                $writer->writeElement('g:price', $this->feeds->formatPrice($product->price));
            }
            $writer->writeElement('g:brand', $this->feeds->brand($product));
            $writer->writeElement('g:product_type', $this->feeds->productType($product));
            $googleCategory = $this->feeds->googleProductCategory($product);
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
            'product_count' => $products->count(),
        ], self::CACHE_SECONDS);

        return $xml;
    }

    private function metadata(Request $request): array
    {
        $baseUrl = $this->feeds->baseUrl($request);
        $metadata = Cache::get(self::META_KEY, []);

        return [
            'feed_url' => $baseUrl . '/meta-feed.xml',
            'last_generation_time' => $metadata['last_generation_time'] ?? null,
            'product_count' => $metadata['product_count'] ?? $this->feeds->catalogProducts($baseUrl)->count(),
        ];
    }
}
