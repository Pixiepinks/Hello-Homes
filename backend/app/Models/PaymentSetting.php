<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'bank_transfer_enabled',
        'card_payment_enabled',
        'qr_payment_enabled',
    ];

    protected $casts = [
        'bank_transfer_enabled' => 'boolean',
        'card_payment_enabled' => 'boolean',
        'qr_payment_enabled' => 'boolean',
    ];

    public static function current(): self
    {
        return self::firstOrCreate([], [
            'bank_transfer_enabled' => true,
            'card_payment_enabled' => false,
            'qr_payment_enabled' => false,
        ]);
    }
}
