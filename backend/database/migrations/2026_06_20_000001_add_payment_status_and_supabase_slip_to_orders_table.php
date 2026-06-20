<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPaymentStatusAndSupabaseSlipToOrdersTable extends Migration
{
    public function up()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('payment_status')->default('PENDING_PAYMENT')->after('payment_method');
            $table->text('payment_slip_url')->nullable()->after('payment_slip_path');
            $table->timestamp('payment_slip_uploaded_at')->nullable()->after('payment_slip_url');
        });
    }

    public function down()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['payment_status', 'payment_slip_url', 'payment_slip_uploaded_at']);
        });
    }
}
