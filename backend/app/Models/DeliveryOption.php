<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryOption extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'type',
        'base_fee',
        'additional_fee_per_unit',
        'unit_weight',
        'is_active',
    ];

    public function products()
    {
        return $this->hasMany(Product::class);
    }
}
