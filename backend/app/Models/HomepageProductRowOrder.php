<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HomepageProductRowOrder extends Model
{
    use HasFactory;

    protected $guarded = [];

    protected $casts = [
        'sort_order' => 'integer',
        'product_id' => 'integer',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
