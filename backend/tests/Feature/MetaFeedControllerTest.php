<?php

namespace Tests\Feature;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use App\Http\Controllers\MetaFeedController;
use App\Models\Product;
use Tests\TestCase;

class MetaFeedControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Config::set('database.default', 'sqlite');
        Config::set('database.connections.sqlite.database', ':memory:');
        DB::purge('sqlite');
        DB::reconnect('sqlite');

        foreach (['products', 'brands', 'child_categories', 'subcategories', 'categories'] as $table) {
            Schema::dropIfExists($table);
        }

        $this->createMetaFeedTables();
        Cache::flush();
    }

    public function test_public_feed_uses_production_url_and_application_xml(): void
    {
        Config::set('app.url', 'http://localhost');
        Product::create([
            'title' => 'Sofa',
            'subtitle' => 'Living room sofa',
            'image_url' => '/storage/products/sofa.jpg',
            'price' => 1200,
            'original_price' => 1500,
            'is_on_sale' => true,
            'is_active' => true,
            'stock_quantity' => 5,
        ]);

        $response = $this->get('/meta-feed.xml');

        $response->assertOk();
        $this->assertStringContainsString('application/xml', $response->headers->get('Content-Type'));
        $response->assertSee('https://hellohomes.lk/meta-feed.xml', false);
        $response->assertSee('https://hellohomes.lk/storage/products/sofa.jpg', false);
        $response->assertDontSee('localhost', false);
    }

    public function test_meta_feed_admin_preflight_requests_succeed(): void
    {
        $response = $this->options('/api/admin/meta-feed/regenerate', [], [
            'HTTP_ORIGIN' => 'https://hellohomes.lk',
            'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
            'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'authorization,accept,content-type',
        ]);

        $response->assertNoContent();
        $this->assertStringContainsString('POST', $response->headers->get('Access-Control-Allow-Methods', ''));
        $this->assertSame('*', $response->headers->get('Access-Control-Allow-Origin'));
    }

    public function test_regenerate_generates_cache_and_status_metadata_with_timestamp(): void
    {
        Config::set('app.url', 'http://localhost');
        Product::create([
            'title' => 'Table',
            'subtitle' => 'Dining table',
            'image_url' => 'https://hellohomes.lk/storage/products/table.jpg',
            'price' => 1000,
            'is_on_sale' => false,
            'is_active' => true,
            'stock_quantity' => 3,
        ]);

        $controller = app(MetaFeedController::class);
        $request = Request::create('/api/admin/meta-feed/regenerate', 'POST');

        $response = $controller->regenerate($request);
        $payload = $response->getData(true);

        $this->assertSame('https://hellohomes.lk/meta-feed.xml', $payload['feed_url']);
        $this->assertNotEmpty($payload['last_generation_time']);
        $this->assertSame(1, $payload['product_count']);
        $this->assertStringContainsString('https://hellohomes.lk/storage/products/table.jpg', Cache::get('meta_catalog_feed_xml'));
        $this->assertStringNotContainsString('localhost', Cache::get('meta_catalog_feed_xml'));
    }

    public function test_feed_outputs_sale_price_only_when_original_price_is_greater_than_price(): void
    {
        Config::set('app.url', 'https://hellohomes.lk');

        Product::create([
            'title' => 'Discounted Chair',
            'subtitle' => 'Chair with sale price',
            'image_url' => '/storage/products/discounted-chair.jpg',
            'price' => 2350,
            'original_price' => 2850,
            'is_on_sale' => false,
            'is_active' => true,
            'stock_quantity' => 5,
        ]);

        Product::create([
            'title' => 'Regular Lamp',
            'subtitle' => 'Lamp without original price',
            'image_url' => '/storage/products/regular-lamp.jpg',
            'price' => 2350,
            'original_price' => null,
            'is_on_sale' => true,
            'is_active' => true,
            'stock_quantity' => 5,
        ]);

        Product::create([
            'title' => 'Equal Price Table',
            'subtitle' => 'Table with matching prices',
            'image_url' => '/storage/products/equal-price-table.jpg',
            'price' => 2350,
            'original_price' => 2350,
            'is_on_sale' => true,
            'is_active' => true,
            'stock_quantity' => 5,
        ]);

        $response = $this->get('/meta-feed.xml');

        $response->assertOk();
        $xml = $response->getContent();

        $this->assertStringContainsString('<title>Discounted Chair</title>', $xml);
        $this->assertStringContainsString('<g:price>2850.00 LKR</g:price>', $xml);
        $this->assertStringContainsString('<g:sale_price>2350.00 LKR</g:sale_price>', $xml);

        $this->assertStringContainsString('<title>Regular Lamp</title>', $xml);
        $this->assertStringContainsString('<title>Equal Price Table</title>', $xml);
        $this->assertSame(2, substr_count($xml, '<g:price>2350.00 LKR</g:price>'));
        $this->assertSame(1, substr_count($xml, '<g:sale_price>'));
    }

    private function createMetaFeedTables(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('title')->nullable();
            $table->string('google_product_category')->nullable();
        });
        Schema::create('subcategories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('google_product_category')->nullable();
        });
        Schema::create('child_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('google_product_category')->nullable();
        });
        Schema::create('brands', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
        });
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('subtitle')->nullable();
            $table->string('image_url')->nullable();
            $table->json('images')->nullable();
            $table->decimal('price', 10, 2)->default(0);
            $table->decimal('original_price', 10, 2)->nullable();
            $table->boolean('is_on_sale')->default(false);
            $table->boolean('is_active')->default(true);
            $table->integer('stock_quantity')->default(0);
            $table->string('status')->nullable();
            $table->foreignId('category_id')->nullable();
            $table->foreignId('subcategory_id')->nullable();
            $table->foreignId('child_category_id')->nullable();
            $table->foreignId('brand_id')->nullable();
            $table->timestamps();
        });
    }
}
