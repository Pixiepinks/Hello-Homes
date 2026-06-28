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
        'is_active' => 'boolean',
        'stock_quantity' => 'integer',
        'price' => 'float',
        'original_price' => 'float',
        'weight' => 'float',
        'subcategory_id' => 'integer',
        'child_category_id' => 'integer',
        'brand_id' => 'integer',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function subcategory()
    {
        return $this->belongsTo(Subcategory::class);
    }

    public function childCategory()
    {
        return $this->belongsTo(ChildCategory::class);
    }

    public function brand()
    {
        return $this->belongsTo(Brand::class);
    }

    public function deliveryOption()
    {
        return $this->belongsTo(DeliveryOption::class);
    }
}
