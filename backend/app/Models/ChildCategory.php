<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChildCategory extends Model
{
    use HasFactory;
    protected $guarded = [];
    protected $casts = ['is_active' => 'boolean', 'sort_order' => 'integer'];
    public function category() { return $this->belongsTo(Category::class); }
    public function subcategory() { return $this->belongsTo(Subcategory::class); }
    public function products() { return $this->hasMany(Product::class); }
}
