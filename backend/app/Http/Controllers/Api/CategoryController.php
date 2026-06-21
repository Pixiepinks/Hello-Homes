<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Category;
use App\Models\Notification;

class CategoryController extends Controller
{
    public function index()
    {
        return response()->json(Category::with('subcategories')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'image_url' => 'nullable|string',
        ]);

        $category = Category::create($validated);

        // Notify Admin Activity
        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Category Created',
            'message' => "Category '{$category->title}' has been created.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Category created successfully', 'category' => $category]);
    }

    public function update(Request $request, $id)
    {
        $category = Category::findOrFail($id);
        
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'image_url' => 'nullable|string',
        ]);

        $category->update($validated);

        // Notify Admin Activity
        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Category Updated',
            'message' => "Category '{$category->title}' has been updated.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Category updated successfully', 'category' => $category]);
    }

    public function destroy($id)
    {
        $category = Category::findOrFail($id);
        $title = $category->title;
        $category->delete();

        // Notify Admin Activity
        Notification::create([
            'user_id' => \Auth::id(),
            'title' => 'Category Deleted',
            'message' => "Category '{$title}' has been removed.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Category deleted successfully']);
    }
}
