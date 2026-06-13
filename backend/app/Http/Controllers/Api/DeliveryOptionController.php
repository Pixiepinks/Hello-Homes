<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliveryOption;
use App\Models\Product;
use Illuminate\Http\Request;

class DeliveryOptionController extends Controller
{
    public function index()
    {
        return DeliveryOption::all();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'type' => 'required|in:weight_based,flat_rate,free',
            'base_fee' => 'required|numeric',
            'additional_fee_per_unit' => 'nullable|numeric',
            'unit_weight' => 'nullable|numeric',
        ]);

        return DeliveryOption::create($validated);
    }

    public function show(DeliveryOption $deliveryOption)
    {
        return $deliveryOption;
    }

    public function update(Request $request, DeliveryOption $deliveryOption)
    {
        $validated = $request->validate([
            'name' => 'string',
            'type' => 'in:weight_based,flat_rate,free',
            'base_fee' => 'numeric',
            'additional_fee_per_unit' => 'numeric',
            'unit_weight' => 'numeric',
            'is_active' => 'boolean',
        ]);

        $deliveryOption->update($validated);
        return $deliveryOption;
    }

    public function destroy(DeliveryOption $deliveryOption)
    {
        $deliveryOption->delete();
        return response()->json(['message' => 'Deleted successfully']);
    }

    /**
     * Bulk update products delivery option
     */
    public function bulkUpdateProducts(Request $request)
    {
        $validated = $request->validate([
            'product_ids' => 'required|array',
            'delivery_option_id' => 'required|exists:delivery_options,id',
            'weight' => 'nullable|numeric'
        ]);

        $updateData = ['delivery_option_id' => $validated['delivery_option_id']];
        if (isset($validated['weight'])) {
            $updateData['weight'] = $validated['weight'];
        }

        Product::whereIn('id', $validated['product_ids'])->update($updateData);

        return response()->json(['message' => 'Products updated successfully']);
    }

    /**
     * Update all products delivery option
     */
    public function updateAllProducts(Request $request)
    {
        $validated = $request->validate([
            'delivery_option_id' => 'required|exists:delivery_options,id',
            'weight' => 'nullable|numeric'
        ]);

        $updateData = ['delivery_option_id' => $validated['delivery_option_id']];
        if (isset($validated['weight'])) {
            $updateData['weight'] = $validated['weight'];
        }

        Product::query()->update($updateData);

        return response()->json(['message' => 'All products updated successfully']);
    }
}
