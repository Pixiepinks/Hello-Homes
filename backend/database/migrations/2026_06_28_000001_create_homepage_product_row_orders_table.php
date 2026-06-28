<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('homepage_product_row_orders', function (Blueprint $table) {
            $table->id();
            $table->string('row_key');
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();

            $table->unique(['row_key', 'product_id']);
            $table->index(['row_key', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('homepage_product_row_orders');
    }
};
