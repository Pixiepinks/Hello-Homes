<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\Subcategory;
use Illuminate\Http\Request;

class SubcategoryController extends Controller
{
    public function index(Request $request)
    {
        $query = Subcategory::with('category')->orderBy('sort_order')->orderBy('name');

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'image_url' => 'nullable|string',
            'is_active' => 'boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $subcategory = Subcategory::create($validated);

        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Subcategory Created',
            'message' => "Subcategory '{$subcategory->name}' has been created.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Subcategory created successfully', 'subcategory' => $subcategory->load('category')], 201);
    }

    public function show($id)
    {
        return response()->json(Subcategory::with('category')->findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $subcategory = Subcategory::findOrFail($id);

        $validated = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required|string|max:255',
            'image_url' => 'nullable|string',
            'is_active' => 'boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $subcategory->update($validated);

        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Subcategory Updated',
            'message' => "Subcategory '{$subcategory->name}' has been updated.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Subcategory updated successfully', 'subcategory' => $subcategory->load('category')]);
    }

    public function destroy($id)
    {
        $subcategory = Subcategory::findOrFail($id);
        $name = $subcategory->name;
        $subcategory->delete();

        Notification::create([
            'user_id' => \Auth::id(),
            'title' => 'Subcategory Deleted',
            'message' => "Subcategory '{$name}' has been removed.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Subcategory deleted successfully']);
    }
}
