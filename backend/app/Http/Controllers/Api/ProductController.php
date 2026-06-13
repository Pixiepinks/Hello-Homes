<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\Category;
use App\Models\Notification;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['deliveryOption', 'category']);

        // Search by title
        if ($request->has('search')) {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        // Filter by category
        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        // Filter by sale status
        if ($request->has('on_sale')) {
            $query->where('is_on_sale', $request->boolean('on_sale'));
        }

        // Filter by new arrival
        if ($request->has('is_new')) {
            $query->where('is_new', $request->boolean('is_new'));
        }

        $perPage = $request->get('per_page', 10);
        
        if ($request->has('all')) {
            return response()->json($query->get());
        }

        return response()->json($query->orderBy('created_at', 'desc')->paginate($perPage));
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
        ]);

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
        ]);

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

    public function categories()
    {
        return response()->json(Category::all());
    }
}
