<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBrandsAndChildCategoriesAndUpdateProducts extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('brands')) {
            Schema::create('brands', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->string('slug')->unique();
                $table->string('logo_url')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                $table->index(['is_active', 'name']);
            });
        }

        if (!Schema::hasTable('child_categories')) {
            Schema::create('child_categories', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('category_id');
                $table->unsignedBigInteger('subcategory_id');
                $table->string('name');
                $table->string('slug');
                $table->string('image_url')->nullable();
                $table->integer('sort_order')->default(0);
                $table->boolean('is_active')->default(true);
                $table->timestamps();

                $table->foreign('category_id')->references('id')->on('categories')->onDelete('cascade');
                $table->foreign('subcategory_id')->references('id')->on('subcategories')->onDelete('cascade');
                $table->unique(['subcategory_id', 'slug']);
                $table->index(['category_id', 'subcategory_id', 'is_active', 'sort_order']);
            });
        }

        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'child_category_id')) {
                $table->unsignedBigInteger('child_category_id')->nullable()->after('subcategory_id');
                $table->foreign('child_category_id')->references('id')->on('child_categories')->onDelete('set null');
            }
            if (!Schema::hasColumn('products', 'brand_id')) {
                $table->unsignedBigInteger('brand_id')->nullable()->after('child_category_id');
                $table->foreign('brand_id')->references('id')->on('brands')->onDelete('set null');
            }
        });
    }

    public function down()
    {
        Schema::table('products', function (Blueprint $table) {
            if (Schema::hasColumn('products', 'brand_id')) {
                $table->dropForeign(['brand_id']);
                $table->dropColumn('brand_id');
            }
            if (Schema::hasColumn('products', 'child_category_id')) {
                $table->dropForeign(['child_category_id']);
                $table->dropColumn('child_category_id');
            }
        });
        Schema::dropIfExists('child_categories');
        Schema::dropIfExists('brands');
    }
}
