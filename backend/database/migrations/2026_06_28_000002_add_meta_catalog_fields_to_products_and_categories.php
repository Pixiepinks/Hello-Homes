<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddMetaCatalogFieldsToProductsAndCategories extends Migration
{
    public function up()
    {
        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'is_active')) {
                $table->boolean('is_active')->default(true)->index()->after('is_on_sale');
            }
            if (!Schema::hasColumn('products', 'status')) {
                $table->string('status')->default('active')->index()->after('is_active');
            }
            if (!Schema::hasColumn('products', 'stock_quantity')) {
                $table->unsignedInteger('stock_quantity')->default(1)->index()->after('status');
            }
        });

        foreach (['categories', 'subcategories', 'child_categories'] as $tableName) {
            if (Schema::hasTable($tableName) && !Schema::hasColumn($tableName, 'google_product_category')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->string('google_product_category')->nullable()->after('image_url');
                });
            }
        }
    }

    public function down()
    {
        Schema::table('products', function (Blueprint $table) {
            foreach (['stock_quantity', 'status', 'is_active'] as $column) {
                if (Schema::hasColumn('products', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        foreach (['categories', 'subcategories', 'child_categories'] as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'google_product_category')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropColumn('google_product_category');
                });
            }
        }
    }
}
