<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PromotionBanner extends Model
{
    protected $guarded = [];

    protected $appends = ['enabled'];

    protected $casts = [
        'is_active' => 'boolean',
        'discount_percentage' => 'integer',
        'original_price' => 'float',
        'discounted_price' => 'float',
        'offer_start_at' => 'datetime',
        'offer_end_at' => 'datetime',
    ];

    public function getEnabledAttribute(): bool
    {
        return (bool) $this->is_active;
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
