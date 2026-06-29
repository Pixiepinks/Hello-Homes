<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Http\Controllers\TikTokFeedController;
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
        $this->assertSame('Classic Kettle', $rows[1][$this->column('title')]);
        $this->assertSame('2350.00 LKR', $rows[1][$this->column('price')]);
        $this->assertSame('', $rows[1][$this->column('sale_price')]);
        $this->assertSame('Hello Homes', $rows[1][$this->column('brand')]);
    }

    public function test_discounted_product_outputs_price_and_sale_price_with_currency_formatting(): void
    {
        Product::create($this->product(['title' => 'Discount Chair', 'price' => 2350, 'original_price' => 2990]));

        $row = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent())[1];

        $this->assertSame('2990.00 LKR', $row[$this->column('price')]);
        $this->assertSame('2350.00 LKR', $row[$this->column('sale_price')]);
    }

    public function test_null_original_price_and_equal_original_price_leave_sale_price_empty(): void
    {
        Product::create($this->product(['title' => 'Null Original', 'price' => 1000, 'original_price' => null]));
        Product::create($this->product(['title' => 'Equal Original', 'price' => 1000, 'original_price' => 1000]));

        $rows = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent());

        $this->assertSame('', $rows[1][$this->column('sale_price')]);
        $this->assertSame('', $rows[2][$this->column('sale_price')]);
        $this->assertSame('1000.00 LKR', $rows[1][$this->column('price')]);
        $this->assertSame('1000.00 LKR', $rows[2][$this->column('price')]);
    }

    public function test_invalid_price_missing_image_and_inactive_products_are_skipped(): void
    {
        Product::create($this->product(['title' => 'Valid Product']));
        Product::create($this->product(['title' => 'Invalid Price', 'price' => 0]));
        Product::create($this->product(['title' => 'Missing Image', 'image_url' => '']));
        Product::create($this->product(['title' => 'Inactive Product', 'is_active' => false]));

        $rows = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent());

        $this->assertCount(2, $rows);
        $this->assertSame('Valid Product', $rows[1][$this->column('title')]);
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

        $this->assertSame('Kitchen Appliances > Rice Cookers', $row[$this->column('product_type')]);
        $this->assertSame('Home & Garden > Kitchen & Dining > Rice Cookers', $row[$this->column('google_product_category')]);
        $this->assertNotSame('', $row[$this->column('product_type')]);
        $this->assertNotSame('', $row[$this->column('google_product_category')]);
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

        $this->assertSame('Kitchen Appliances > Unmapped Specialty Cookers', $row[$this->column('product_type')]);
        $this->assertSame('Home & Garden > Kitchen & Dining > Kitchen Appliances', $row[$this->column('google_product_category')]);
        $this->assertNotSame('', $row[$this->column('product_type')]);
        $this->assertNotSame('', $row[$this->column('google_product_category')]);
    }

    public function test_tiktok_category_columns_never_empty_when_product_has_no_category(): void
    {
        Product::create($this->product(['title' => 'Uncategorized Product']));

        $row = $this->csvRows($this->get('/feeds/tiktok.csv')->getContent())[1];

        $this->assertSame('Hello Homes', $row[$this->column('product_type')]);
        $this->assertSame('Home & Garden', $row[$this->column('google_product_category')]);
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
        $this->assertSame('12.50 LKR', $row[$this->column('price')]);
        $this->assertSame('Best, "fast" kettle', $row[$this->column('description')]);
    }


    public function test_tiktok_csv_matches_official_template_structure_and_required_field_rules(): void
    {
        Product::create($this->product([
            'sku' => 'SKU-123',
            'title' => 'Template Product',
            'price' => 1500,
            'original_price' => 2000,
            'gtin' => '1234567890123',
            'mpn' => 'MPN-456',
            'color' => 'Blue',
            'material' => 'Steel',
            'pattern' => 'Solid',
        ]));

        $csv = $this->get('/feeds/tiktok.csv')->getContent();
        $rows = $this->csvRows($csv);
        $header = $rows[0];
        $row = $rows[1];

        $this->assertSame(44, count($header));
        $this->assertSame(TikTokFeedController::OFFICIAL_HEADERS, $header);
        $this->assertSame(TikTokFeedController::OFFICIAL_HEADERS, array_values($header));
        $this->assertSame(count(TikTokFeedController::OFFICIAL_HEADERS), count($row));
        $this->assertSame('SKU-123', $row[$this->column('sku_id')]);
        $this->assertNotSame('', $row[$this->column('title')]);
        $this->assertNotSame('', $row[$this->column('description')]);
        $this->assertContains($row[$this->column('availability')], ['in stock', 'out of stock']);
        $this->assertSame('new', $row[$this->column('condition')]);
        $this->assertMatchesRegularExpression('/^\d+\.\d{2} LKR$/', $row[$this->column('price')]);
        $this->assertSame('1500.00 LKR', $row[$this->column('sale_price')]);
        $this->assertNotSame('', $row[$this->column('link')]);
        $this->assertNotSame('', $row[$this->column('image_link')]);
        $this->assertNotSame('', $row[$this->column('brand')]);
        $this->assertNotSame('', $row[$this->column('product_type')]);
        $this->assertNotSame('', $row[$this->column('google_product_category')]);
        $this->assertSame('1', $row[$this->column('item_group_id')]);
        $this->assertSame('unisex', $row[$this->column('gender')]);
        $this->assertSame('adult', $row[$this->column('age_group')]);
        $this->assertSame('', $row[$this->column('video_link')]);
        $this->assertSame('', $row[$this->column('shipping')]);
        $this->assertSame('', $row[$this->column('shipping_weight')]);
        $this->assertSame('1234567890123', $row[$this->column('gtin')]);
        $this->assertSame('MPN-456', $row[$this->column('mpn')]);
        $this->assertSame('Blue', $row[$this->column('color')]);
        $this->assertSame('Steel', $row[$this->column('material')]);
        $this->assertSame('Solid', $row[$this->column('pattern')]);
        $this->assertSame(mb_convert_encoding($csv, 'UTF-8', 'UTF-8'), $csv);
    }


    public function test_tiktok_header_validation_throws_when_generated_header_differs_from_template(): void
    {
        $controller = app(TikTokFeedController::class);
        $method = new \ReflectionMethod($controller, 'assertOfficialHeader');
        $method->setAccessible(true);

        $this->expectException(\RuntimeException::class);
        $method->invoke($controller, array_merge(['unexpected_column'], TikTokFeedController::OFFICIAL_HEADERS));
    }

    public function test_tiktok_template_summary_reports_no_missing_extra_or_order_differences(): void
    {
        $summary = TikTokFeedController::templateSummary();

        $this->assertSame(44, $summary['total_template_columns']);
        $this->assertSame(44, $summary['generated_columns']);
        $this->assertSame([], $summary['missing_columns']);
        $this->assertSame([], $summary['extra_columns']);
        $this->assertTrue($summary['header_order_verified']);
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
        return TikTokFeedController::OFFICIAL_HEADERS;
    }

    private function column(string $name): int
    {
        return array_search($name, $this->headers(), true);
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
