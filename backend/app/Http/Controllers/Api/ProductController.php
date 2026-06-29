<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\Category;
use App\Models\Notification;
use App\Models\Subcategory;
use App\Models\ChildCategory;
use Illuminate\Validation\ValidationException;
use App\Http\Controllers\Api\HomepageProductRowController;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['deliveryOption', 'category', 'subcategory', 'childCategory', 'brand']);

        // Search by title
        if ($request->has('search')) {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        // Filter by category. A category-level filter intentionally returns
        // products assigned to that category, including products normalized from
        // its subcategories and child categories.
        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('category_slug')) {
            $category = Category::where('slug', $request->category_slug)->first();
            $query->where('category_id', $category?->id ?? 0);
        }

        if ($request->filled('category_name')) {
            $category = Category::where('title', $request->category_name)->first();
            $query->where('category_id', $category?->id ?? 0);
        }

        if ($request->filled('subcategory_id')) {
            $query->where('subcategory_id', $request->subcategory_id);
        }

        if ($request->filled('child_category_id')) {
            $query->where('child_category_id', $request->child_category_id);
        }

        if ($request->filled('brand_id')) {
            $query->where('brand_id', $request->brand_id);
        }

        // Filter by sale status
        if ($request->has('on_sale')) {
            $query->where('is_on_sale', $request->boolean('on_sale'));
        }

        // Filter by new arrival
        if ($request->has('is_new')) {
            $query->where('is_new', $request->boolean('is_new'));
        }

        if ($request->has('active')) {
            $query->where('is_active', $request->boolean('active'));

            if ($request->boolean('active')) {
                $query->whereNotIn('status', ['draft', 'hidden', 'disabled', 'inactive', 'deleted']);
            }
        }

        if ($request->filled('homepage_row_key')) {
            if ($request->homepage_row_key === 'best_offers') {
                $query->where(function ($q) {
                    $q->where('is_on_sale', true)->orWhereColumn('price', '<', 'original_price');
                });
            } elseif ($request->homepage_row_key === 'new_arrivals') {
                $query->where('is_new', true);
            } elseif (preg_match('/^category_(\d+)$/', $request->homepage_row_key, $matches) && !$request->has('category_id') && !$request->filled('category_slug') && !$request->filled('category_name')) {
                $query->where('category_id', (int) $matches[1]);
            }

            if (!HomepageProductRowController::hasManualOrder($request->homepage_row_key) && $request->homepage_row_key === 'best_offers') {
                $query->orderByRaw('CASE WHEN original_price > 0 THEN (original_price - price) / original_price ELSE 0 END DESC');
            }

            $query = HomepageProductRowController::applyManualOrder($query, $request->homepage_row_key);
        }

        $perPage = $request->get('per_page', 10);
        
        if ($request->has('all')) {
            return response()->json($query->get());
        }

        if (!$request->filled('homepage_row_key')) {
            $query->orderBy('created_at', 'desc');
        }

        return response()->json($query->paginate($perPage));
    }

    public function show($id)
    {
        $product = Product::with(['deliveryOption', 'category', 'subcategory', 'childCategory', 'brand'])->find($id);

        if (!$product) {
            return response()->json(['message' => 'Product not found'], 404);
        }

        return response()->json($product);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'subtitle' => 'nullable|string|max:255',
            'price' => 'required|numeric',
            'original_price' => 'required|numeric',
            'image_url' => 'nullable|string',
            'is_new' => 'boolean',
            'is_on_sale' => 'boolean',
            'images' => 'nullable|array',
            'specifications' => 'nullable|array',
            'easy_payment' => 'nullable|string',
            'enquiry' => 'nullable|string',
            'delivery_option_id' => 'nullable|exists:delivery_options,id',
            'weight' => 'nullable|numeric',
            'category_id' => 'nullable|exists:categories,id',
            'subcategory_id' => ['nullable', 'exists:subcategories,id'],
            'child_category_id' => ['nullable', 'exists:child_categories,id'],
            'brand_id' => ['nullable', 'exists:brands,id'],
        ]);

        $this->normalizeCategoryHierarchy($validated);

        $product = Product::create($validated);

        // Notify Admin Activity
        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Product Created',
            'message' => "Product '{$product->title}' has been added.",
            'type' => 'activity',
        ]);

        return response()->json($product, 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);
        
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'subtitle' => 'nullable|string|max:255',
            'price' => 'required|numeric',
            'original_price' => 'required|numeric',
            'image_url' => 'nullable|string',
            'is_new' => 'boolean',
            'is_on_sale' => 'boolean',
            'images' => 'nullable|array',
            'specifications' => 'nullable|array',
            'easy_payment' => 'nullable|string',
            'enquiry' => 'nullable|string',
            'delivery_option_id' => 'nullable|exists:delivery_options,id',
            'weight' => 'nullable|numeric',
            'category_id' => 'nullable|exists:categories,id',
            'subcategory_id' => ['nullable', 'exists:subcategories,id'],
            'child_category_id' => ['nullable', 'exists:child_categories,id'],
            'brand_id' => ['nullable', 'exists:brands,id'],
        ]);

        $this->normalizeCategoryHierarchy($validated);

        $product->update($validated);

        // Notify Admin Activity
        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Product Updated',
            'message' => "Product '{$product->title}' has been updated.",
            'type' => 'activity',
        ]);

        return response()->json($product);
    }

    public function destroy($id)
    {
        $product = Product::findOrFail($id);
        $title = $product->title;
        $product->delete();

        // Notify Admin Activity
        Notification::create([
            'user_id' => \Auth::id(),
            'title' => 'Product Deleted',
            'message' => "Product '{$title}' has been removed.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Product deleted successfully']);
    }

    private function normalizeCategoryHierarchy(array &$validated): void
    {
        if (empty($validated['subcategory_id'])) {
            $validated['subcategory_id'] = null;
            $validated['child_category_id'] = null;
            return;
        }

        $subcategory = Subcategory::find($validated['subcategory_id']);
        if (!$subcategory || (isset($validated['category_id']) && $validated['category_id'] && (int) $subcategory->category_id !== (int) $validated['category_id'])) {
            throw ValidationException::withMessages(['subcategory_id' => 'Selected subcategory does not belong to the selected category.']);
        }

        $validated['category_id'] = $subcategory->category_id;

        if (empty($validated['child_category_id'])) {
            $validated['child_category_id'] = null;
            return;
        }

        $childCategory = ChildCategory::find($validated['child_category_id']);
        if (!$childCategory || (int) $childCategory->subcategory_id !== (int) $validated['subcategory_id']) {
            throw ValidationException::withMessages(['child_category_id' => 'Selected child category does not belong to the selected subcategory.']);
        }
        $validated['category_id'] = $childCategory->category_id;
        $validated['subcategory_id'] = $childCategory->subcategory_id;
    }

    public function categories()
    {
        return response()->json(Category::all());
    }
}
