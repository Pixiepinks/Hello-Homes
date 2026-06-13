<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        \DB::table('categories')->insert([
            ['title' => 'Electronics', 'subtitle' => 'High Performance', 'image_url' => 'https://images.unsplash.com/photo-1498049794561-7780e7231661?q=80&w=800&auto=format&fit=crop'],
            ['title' => 'Large Appliances', 'subtitle' => 'Smart living solutions', 'image_url' => 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=800&auto=format&fit=crop'],
        ]);

        \DB::table('products')->insert([
            ['title' => 'Hyperion Z-Fold Ultra', 'subtitle' => 'SMARTPHONE', 'price' => 1299.00, 'original_price' => 1499.00, 'image_url' => 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=800&auto=format&fit=crop', 'is_new' => true, 'is_on_sale' => false],
            ['title' => 'TitanBook Pro 16"', 'subtitle' => 'LAPTOP', 'price' => 2499.00, 'original_price' => 2499.00, 'image_url' => 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?q=80&w=800&auto=format&fit=crop', 'is_new' => false, 'is_on_sale' => false],
            ['title' => 'OLED Cinema Pro Max', 'subtitle' => 'SMART TV', 'price' => 3199.00, 'original_price' => 3500.00, 'image_url' => 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?q=80&w=800&auto=format&fit=crop', 'is_new' => false, 'is_on_sale' => true],
        ]);
    }
}
