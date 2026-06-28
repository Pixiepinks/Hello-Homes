<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\HomepageProductRowOrder;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class HomepageProductRowController extends Controller
{
    public function index()
    {
        $rows = [
            ['key' => 'best_offers', 'title' => 'Best Offers', 'type' => 'system'],
            ['key' => 'new_arrivals', 'title' => 'New Arrivals', 'type' => 'system'],
            ['key' => 'featured_products', 'title' => 'Featured Products', 'type' => 'system'],
        ];

        foreach (Category::orderBy('title')->get() as $category) {
            $rows[] = [
                'key' => 'category_' . $category->id,
                'title' => $category->title,
                'type' => 'category',
                'category_id' => $category->id,
                'category_slug' => $category->slug,
            ];
        }

        return response()->json($rows);
    }

    public function products(string $rowKey)
    {
        return response()->json($this->orderedProductsForRow($rowKey)->get());
    }

    public function updateOrder(Request $request, string $rowKey)
    {
        $validated = $request->validate([
            'product_ids' => 'required|array|min:1',
            'product_ids.*' => 'required|integer|distinct|exists:products,id',
        ]);

        $rowProductIds = $this->baseQueryForRow($rowKey)->pluck('products.id')->map(fn ($id) => (int) $id)->all();
        $valid = array_flip($rowProductIds);
        foreach ($validated['product_ids'] as $productId) {
            if (!isset($valid[(int) $productId])) {
                throw ValidationException::withMessages([
                    'product_ids' => 'One or more products do not belong to the selected homepage row.',
                ]);
            }
        }

        DB::transaction(function () use ($rowKey, $validated) {
            HomepageProductRowOrder::where('row_key', $rowKey)->delete();
            foreach (array_values($validated['product_ids']) as $index => $productId) {
                HomepageProductRowOrder::create([
                    'row_key' => $rowKey,
                    'product_id' => $productId,
                    'sort_order' => $index + 1,
                ]);
            }
        });

        return response()->json([
            'message' => 'Product row order saved successfully.',
            'products' => $this->orderedProductsForRow($rowKey)->get(),
        ]);
    }

    public function resetOrder(string $rowKey)
    {
        HomepageProductRowOrder::where('row_key', $rowKey)->delete();

        return response()->json([
            'message' => 'Product row order reset successfully.',
            'products' => $this->orderedProductsForRow($rowKey)->get(),
        ]);
    }

    public static function hasManualOrder(string $rowKey): bool
    {
        return HomepageProductRowOrder::where('row_key', $rowKey)->exists();
    }

    public static function applyManualOrder($query, string $rowKey)
    {
        if (!self::hasManualOrder($rowKey)) {
            return $query;
        }

        return $query
            ->leftJoin('homepage_product_row_orders as hpro', function ($join) use ($rowKey) {
                $join->on('products.id', '=', 'hpro.product_id')
                    ->where('hpro.row_key', '=', $rowKey);
            })
            ->select('products.*')
            ->orderByRaw('CASE WHEN hpro.sort_order IS NULL THEN 1 ELSE 0 END')
            ->orderBy('hpro.sort_order')
            ->orderBy('products.created_at', 'desc');
    }

    private function orderedProductsForRow(string $rowKey)
    {
        return self::applyManualOrder($this->baseQueryForRow($rowKey), $rowKey);
    }

    private function baseQueryForRow(string $rowKey)
    {
        $query = Product::with(['deliveryOption', 'category', 'subcategory', 'childCategory', 'brand']);

        if ($rowKey === 'best_offers') {
            return $query->where(function ($q) {
                $q->where('is_on_sale', true)->orWhereColumn('price', '<', 'original_price');
            });
        }

        if ($rowKey === 'new_arrivals') {
            return $query->where('is_new', true);
        }

        if ($rowKey === 'featured_products') {
            return $query;
        }

        if (preg_match('/^category_(\d+)$/', $rowKey, $matches)) {
            return $query->where('category_id', (int) $matches[1]);
        }

        abort(404, 'Homepage row not found.');
    }
}
