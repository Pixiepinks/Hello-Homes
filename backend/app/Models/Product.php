<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;
    protected $guarded = [];

    protected $casts = [
        'images' => 'array',
        'specifications' => 'array',
        'is_new' => 'boolean',
        'is_on_sale' => 'boolean',
        'price' => 'float',
        'original_price' => 'float',
        'weight' => 'float',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function deliveryOption()
    {
        return $this->belongsTo(DeliveryOption::class);
    }
}
