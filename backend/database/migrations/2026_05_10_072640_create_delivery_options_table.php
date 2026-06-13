<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDeliveryOptionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('delivery_options', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('type'); // 'weight_based', 'flat_rate', 'free'
            $table->decimal('base_fee', 10, 2)->default(0);
            $table->decimal('additional_fee_per_unit', 10, 2)->default(0); // For weight based
            $table->decimal('unit_weight', 10, 2)->default(1); // Default 1KG
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Add delivery fields to products
        Schema::table('products', function (Blueprint $table) {
            $table->unsignedBigInteger('delivery_option_id')->nullable();
            $table->decimal('weight', 10, 2)->default(1.00); // in KG
            
            $table->foreign('delivery_option_id')->references('id')->on('delivery_options')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['delivery_option_id']);
            $table->dropColumn(['delivery_option_id', 'weight']);
        });
        Schema::dropIfExists('delivery_options');
    }
}
