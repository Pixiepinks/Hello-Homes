<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\DeliveryOption;
use App\Models\Product;

class DeliveryOptionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // 1) Weight based (Default)
        $weightBased = DeliveryOption::create([
            'name' => 'Standard Weight Based (Default)',
            'type' => 'weight_based',
            'base_fee' => 400.00,
            'additional_fee_per_unit' => 100.00,
            'unit_weight' => 1.00,
            'is_active' => true,
        ]);

        // 2) Bicycle delivery
        $bicycle = DeliveryOption::create([
            'name' => 'Bicycle Delivery',
            'type' => 'flat_rate',
            'base_fee' => 1000.00,
            'is_active' => true,
        ]);

        // 3) Free Delivery
        $free = DeliveryOption::create([
            'name' => 'Free Delivery',
            'type' => 'free',
            'base_fee' => 0.00,
            'is_active' => true,
        ]);

        // Set default for all existing products
        Product::query()->update([
            'delivery_option_id' => $weightBased->id,
            'weight' => 1.00
        ]);
    }
}
