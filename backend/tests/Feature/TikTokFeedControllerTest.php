<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Models\Product;
use Tests\TestCase;

class TikTokFeedControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Config::set('database.default', 'sqlite');
        Config::set('database.connections.sqlite.database', ':memory:');
        DB::purge('sqlite');
        DB::reconnect('sqlite');
        Config::set('app.url', 'https://hellohomes.lk');

        foreach (['products', 'brands', 'child_categories', 'subcategories', 'categories'] as $table) {
            Schema::dropIfExists($table);
        }

        $this->createTables();
        Cache::flush();
    }

    public function test_tiktok_csv_downloads_with_content_type_header_and_normal_product(): void
    {
        Product::create($this->product(['title' => 'Classic Kettle', 'price' => 2350]));

        $response = $this->get('/feeds/tiktok.csv');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
        $rows = $this->csvRows($response->getContent());
        $this->assertSame($this->headers(), $rows[0]);
        $this->assertSame('Classic Kettle', $rows[1][1]);
        $this->assertSame('2350.00 LKR', $rows[1][5]);
        $this->assertSame('', $rows[1][6]);
        $this->assertSame('Hello Homes', $rows[1][9]);
    }

    public function test_discounted_product_outputs_price_and_sale_price_with_currency_formatting(): void
    {
        Product::create($this->product(['title' => 'Discount Chair', 'price' => 2350, 'original_price' => 2990]));

        $row = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent())[1];

        $this->assertSame('2990.00 LKR', $row[5]);
        $this->assertSame('2350.00 LKR', $row[6]);
    }

    public function test_null_original_price_and_equal_original_price_leave_sale_price_empty(): void
    {
        Product::create($this->product(['title' => 'Null Original', 'price' => 1000, 'original_price' => null]));
        Product::create($this->product(['title' => 'Equal Original', 'price' => 1000, 'original_price' => 1000]));

        $rows = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent());

        $this->assertSame('', $rows[1][6]);
        $this->assertSame('', $rows[2][6]);
        $this->assertSame('1000.00 LKR', $rows[1][5]);
        $this->assertSame('1000.00 LKR', $rows[2][5]);
    }

    public function test_invalid_price_missing_image_and_inactive_products_are_skipped(): void
    {
        Product::create($this->product(['title' => 'Valid Product']));
        Product::create($this->product(['title' => 'Invalid Price', 'price' => 0]));
        Product::create($this->product(['title' => 'Missing Image', 'image_url' => '']));
        Product::create($this->product(['title' => 'Inactive Product', 'is_active' => false]));

        $rows = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent());

        $this->assertCount(2, $rows);
        $this->assertSame('Valid Product', $rows[1][1]);
    }


    public function test_tiktok_category_columns_are_populated_from_hierarchy_and_mapping(): void
    {
        $ids = $this->createHierarchy('Kitchen Appliances', 'Rice Cookers');
        Product::create($this->product([
            'title' => 'Rice Cooker',
            'category_id' => $ids['category_id'],
            'subcategory_id' => $ids['subcategory_id'],
        ]));

        $row = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent())[1];

        $this->assertSame('Kitchen Appliances > Rice Cookers', $row[10]);
        $this->assertSame('Home & Garden > Kitchen & Dining > Rice Cookers', $row[11]);
        $this->assertNotSame('', $row[10]);
        $this->assertNotSame('', $row[11]);
    }

    public function test_tiktok_google_product_category_uses_parent_mapping_when_child_has_no_mapping(): void
    {
        $ids = $this->createHierarchy('Kitchen Appliances', 'Unmapped Specialty Cookers');
        Product::create($this->product([
            'title' => 'Specialty Cooker',
            'category_id' => $ids['category_id'],
            'subcategory_id' => $ids['subcategory_id'],
        ]));

        $row = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent())[1];

        $this->assertSame('Kitchen Appliances > Unmapped Specialty Cookers', $row[10]);
        $this->assertSame('Home & Garden > Kitchen & Dining > Kitchen Appliances', $row[11]);
        $this->assertNotSame('', $row[10]);
        $this->assertNotSame('', $row[11]);
    }

    public function test_tiktok_category_columns_never_empty_when_product_has_no_category(): void
    {
        Product::create($this->product(['title' => 'Uncategorized Product']));

        $row = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent())[1];

        $this->assertSame('Hello Homes', $row[10]);
        $this->assertSame('Home & Garden', $row[11]);
    }

    public function test_csv_escaping_for_commas_quotes_and_html_stripping(): void
    {
        Product::create($this->product([
            'title' => 'Large "Chef", Kettle',
            'subtitle' => '<p>Best, "fast" kettle</p>',
            'price' => 12.5,
        ]));

        $csv = $this->get('/feeds/tiktok.csv')->getContent();
        $this->assertStringContainsString('"Large ""Chef"", Kettle"', $csv);
        $this->assertStringContainsString('"Best, ""fast"" kettle"', $csv);
        $row = $this->csvRows($csv)[1];
        $this->assertSame('12.50 LKR', $row[5]);
        $this->assertSame('Best, "fast" kettle', $row[2]);
    }


    private function createHierarchy(string $category, ?string $subcategory = null, ?string $childCategory = null): array
    {
        $categoryId = DB::table('categories')->insertGetId(['title' => $category]);
        $subcategoryId = $subcategory === null ? null : DB::table('subcategories')->insertGetId([
            'name' => $subcategory,
            'category_id' => $categoryId,
        ]);
        $childCategoryId = $childCategory === null ? null : DB::table('child_categories')->insertGetId([
            'name' => $childCategory,
            'category_id' => $categoryId,
            'subcategory_id' => $subcategoryId,
        ]);

        return [
            'category_id' => $categoryId,
            'subcategory_id' => $subcategoryId,
            'child_category_id' => $childCategoryId,
        ];
    }

    private function product(array $overrides = []): array
    {
        return array_merge([
            'title' => 'Product',
            'subtitle' => 'Plain description',
            'image_url' => '/storage/products/product.jpg',
            'images' => ['/storage/products/extra.jpg'],
            'price' => 1000,
            'original_price' => null,
            'is_active' => true,
            'stock_quantity' => 5,
            'status' => 'published',
        ], $overrides);
    }

    private function csvRows(string $csv): array
    {
        $handle = fopen('php://temp', 'r+');
        fwrite($handle, $csv);
        rewind($handle);
        $rows = [];
        while (($row = fgetcsv($handle)) !== false) {
            $rows[] = $row;
        }
        fclose($handle);
        return $rows;
    }

    private function headers(): array
    {
        return ['sku_id', 'title', 'description', 'availability', 'condition', 'price', 'sale_price', 'link', 'image_link', 'brand', 'product_type', 'google_product_category', 'gtin', 'mpn', 'color', 'size', 'material', 'pattern', 'additional_image_link'];
    }

    private function createTables(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('title')->nullable();
            $table->string('google_product_category')->nullable();
        });
        Schema::create('subcategories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->foreignId('category_id')->nullable();
            $table->string('google_product_category')->nullable();
        });
        Schema::create('child_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->foreignId('category_id')->nullable();
            $table->foreignId('subcategory_id')->nullable();
            $table->string('google_product_category')->nullable();
        });
        Schema::create('brands', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
        });
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('sku')->nullable();
            $table->string('title');
            $table->text('subtitle')->nullable();
            $table->string('image_url')->nullable();
            $table->json('images')->nullable();
            $table->decimal('price', 10, 2)->default(0);
            $table->decimal('original_price', 10, 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('stock_quantity')->default(0);
            $table->string('status')->nullable();
            $table->string('gtin')->nullable();
            $table->string('mpn')->nullable();
            $table->string('color')->nullable();
            $table->string('size')->nullable();
            $table->string('material')->nullable();
            $table->string('pattern')->nullable();
            $table->foreignId('category_id')->nullable();
            $table->foreignId('subcategory_id')->nullable();
            $table->foreignId('child_category_id')->nullable();
            $table->foreignId('brand_id')->nullable();
            $table->timestamps();
        });
    }
}
