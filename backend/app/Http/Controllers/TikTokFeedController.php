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

    public const OFFICIAL_HEADERS = [
        'sku_id',
        'title',
        'description',
        'availability',
        'condition',
        'price',
        'link',
        'image_link',
        'video_link',
        'brand',
        'additional_image_link',
        'age_group',
        'color',
        'gender',
        'item_group_id',
        'google_product_category',
        'material',
        'pattern',
        'product_type',
        'sale_price',
        'sale_price_effective_date',
        'shipping',
        'shipping_weight',
        'gtin',
        'mpn',
        'size',
        'tax',
        'ios_url',
        'ios_app_store_id',
        'ios_app_name',
        'iPhone_url',
        'iPhone_app_store_id',
        'iPhone_app_name',
        'iPad_url',
        'iPad_app_store_id',
        'iPad_app_name',
        'android_url',
        'android_package',
        'android_app_name',
        'custom_label_0',
        'custom_label_1',
        'custom_label_2',
        'custom_label_3',
        'Custom_label_4',
    ];

    private function headers(): array
    {
        $headers = self::OFFICIAL_HEADERS;
        $this->assertOfficialHeader($headers);

        return $headers;
    }

    private function row(Product $product, string $baseUrl): array
    {
        $images = $this->feeds->imageUrls($product, $baseUrl);
        $currentPrice = $this->feeds->formatPrice($product->price);
        $hasSalePrice = $this->feeds->hasSalePrice($product);
        $row = array_fill_keys(self::OFFICIAL_HEADERS, '');

        $row['sku_id'] = $this->optionalAttribute($product, 'sku') ?: (string) $product->id;
        $row['title'] = $this->feeds->plainText($product->title);
        $row['description'] = $this->feeds->plainText($product->subtitle ?: $product->title, self::DESCRIPTION_LIMIT);
        $row['availability'] = 'in stock';
        $row['condition'] = 'new';
        $row['price'] = $hasSalePrice ? $this->feeds->formatPrice($product->original_price) : $currentPrice;
        $row['link'] = $this->feeds->productUrl($product, $baseUrl);
        $row['image_link'] = $images[0];
        $row['video_link'] = '';
        $row['brand'] = $this->feeds->brand($product);
        $row['additional_image_link'] = implode(',', array_slice($images, 1));
        $row['age_group'] = 'adult';
        $row['color'] = $this->optionalAttribute($product, 'color');
        $row['gender'] = 'unisex';
        $row['item_group_id'] = (string) $product->id;
        $row['google_product_category'] = $this->feeds->tiktokGoogleProductCategory($product);
        $row['material'] = $this->optionalAttribute($product, 'material');
        $row['pattern'] = $this->optionalAttribute($product, 'pattern');
        $row['product_type'] = $this->feeds->tiktokProductType($product);
        $row['sale_price'] = $hasSalePrice ? $currentPrice : '';
        $row['shipping'] = '';
        $row['shipping_weight'] = '';
        $row['gtin'] = $this->optionalAttribute($product, 'gtin');
        $row['mpn'] = $this->optionalAttribute($product, 'mpn');
        $row['size'] = $this->optionalAttribute($product, 'size');

        $values = array_values($row);
        $this->assertRowColumnCount($values);

        return $values;
    }

    public static function templateSummary(array $generatedHeaders = self::OFFICIAL_HEADERS): array
    {
        return [
            'total_template_columns' => count(self::OFFICIAL_HEADERS),
            'generated_columns' => count($generatedHeaders),
            'missing_columns' => array_values(array_diff(self::OFFICIAL_HEADERS, $generatedHeaders)),
            'extra_columns' => array_values(array_diff($generatedHeaders, self::OFFICIAL_HEADERS)),
            'header_order_verified' => $generatedHeaders === self::OFFICIAL_HEADERS,
        ];
    }

    private function assertOfficialHeader(array $headers): void
    {
        if ($headers !== self::OFFICIAL_HEADERS) {
            throw new \RuntimeException('Generated TikTok CSV header does not match the official TikTok catalog template header.');
        }
    }

    private function assertRowColumnCount(array $row): void
    {
        if (count($row) !== count(self::OFFICIAL_HEADERS)) {
            throw new \RuntimeException(sprintf(
                'Generated TikTok CSV row has %d columns; expected %d official template columns.',
                count($row),
                count(self::OFFICIAL_HEADERS)
            ));
        }
    }

    private function optionalAttribute(Product $product, string $key): string
    {
        $value = $product->getAttribute($key);
        return $value === null ? '' : $this->feeds->plainText((string) $value);
    }
}
