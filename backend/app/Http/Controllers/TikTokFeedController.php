<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Services\Feeds\CatalogFeedService;
use Illuminate\Http\Request;

class TikTokFeedController extends Controller
{
    private const DESCRIPTION_LIMIT = 5000;

    public function __construct(private readonly CatalogFeedService $feeds) {}

    public function feed(Request $request)
    {
        $baseUrl = $this->feeds->baseUrl($request);
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, $this->headers());

        foreach ($this->feeds->catalogProducts($baseUrl) as $product) {
            fputcsv($handle, $this->row($product, $baseUrl));
        }

        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    private function headers(): array
    {
        return [
            'sku_id', 'title', 'description', 'availability', 'condition', 'price', 'sale_price',
            'link', 'image_link', 'brand', 'product_type', 'google_product_category', 'gtin', 'mpn',
            'color', 'size', 'material', 'pattern', 'additional_image_link',
        ];
    }

    private function row(Product $product, string $baseUrl): array
    {
        $images = $this->feeds->imageUrls($product, $baseUrl);
        $currentPrice = $this->feeds->formatPrice($product->price);

        return [
            $this->optionalAttribute($product, 'sku') ?: (string) $product->id,
            $this->feeds->plainText($product->title),
            $this->feeds->plainText($product->subtitle ?: $product->title, self::DESCRIPTION_LIMIT),
            'in stock',
            'new',
            $this->feeds->hasSalePrice($product) ? $this->feeds->formatPrice($product->original_price) : $currentPrice,
            $this->feeds->hasSalePrice($product) ? $currentPrice : '',
            $this->feeds->productUrl($product, $baseUrl),
            $images[0],
            $this->feeds->brand($product),
            $this->feeds->tiktokProductType($product),
            $this->feeds->tiktokGoogleProductCategory($product),
            $this->optionalAttribute($product, 'gtin'),
            $this->optionalAttribute($product, 'mpn'),
            $this->optionalAttribute($product, 'color'),
            $this->optionalAttribute($product, 'size'),
            $this->optionalAttribute($product, 'material'),
            $this->optionalAttribute($product, 'pattern'),
            implode(',', array_slice($images, 1)),
        ];
    }

    private function optionalAttribute(Product $product, string $key): string
    {
        $value = $product->getAttribute($key);
        return $value === null ? '' : $this->feeds->plainText((string) $value);
    }
}
