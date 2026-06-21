<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;
    protected $guarded = [];

    public function childCategories()
    {
        return $this->hasMany(ChildCategory::class)->orderBy('sort_order')->orderBy('name');
    }

    public function subcategories()
    {
        return $this->hasMany(Subcategory::class)->orderBy('sort_order')->orderBy('name');
    }
}
