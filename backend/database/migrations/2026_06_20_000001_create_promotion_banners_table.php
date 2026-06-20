<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('promotion_banners', function (Blueprint $table) {
            $table->id();
            $table->boolean('is_active')->default(false)->index();
            $table->string('title')->nullable();
            $table->string('subtitle')->nullable();
            $table->string('banner_image_url', 2048);
            $table->foreignId('product_id')->nullable()->constrained()->nullOnDelete();
            $table->string('product_slug')->nullable();
            $table->string('product_url', 2048)->nullable();
            $table->unsignedTinyInteger('discount_percentage')->nullable();
            $table->decimal('original_price', 10, 2)->nullable();
            $table->decimal('discounted_price', 10, 2)->nullable();
            $table->dateTime('offer_start_at')->nullable();
            $table->dateTime('offer_end_at')->nullable()->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('promotion_banners');
    }
};
