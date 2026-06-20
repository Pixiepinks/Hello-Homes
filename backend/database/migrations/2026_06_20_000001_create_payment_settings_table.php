<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CreatePaymentSettingsTable extends Migration
{
    public function up()
    {
        Schema::create('payment_settings', function (Blueprint $table) {
            $table->id();
            $table->boolean('bank_transfer_enabled')->default(true);
            $table->boolean('card_payment_enabled')->default(false);
            $table->boolean('qr_payment_enabled')->default(false);
            $table->timestamps();
        });

        DB::table('payment_settings')->insert([
            'bank_transfer_enabled' => true,
            'card_payment_enabled' => false,
            'qr_payment_enabled' => false,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down()
    {
        Schema::dropIfExists('payment_settings');
    }
}
