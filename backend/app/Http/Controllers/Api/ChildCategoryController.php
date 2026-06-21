<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChildCategory;
use App\Models\Notification;
use App\Models\Subcategory;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ChildCategoryController extends Controller
{
    public function index(Request $request)
    {
        $query = ChildCategory::with(['category','subcategory'])->orderBy('sort_order')->orderBy('name');
        if ($request->filled('category_id')) $query->where('category_id', $request->category_id);
        if ($request->filled('subcategory_id')) $query->where('subcategory_id', $request->subcategory_id);
        if ($request->has('active')) $query->where('is_active', $request->boolean('active'));
        return response()->json($query->get());
    }
    public function store(Request $request)
    {
        $validated = $this->validated($request);
        $child = ChildCategory::create($validated);
        Notification::create(['user_id'=>$request->user()->id,'title'=>'Child Category Created','message'=>"Child category '{$child->name}' has been created.",'type'=>'activity']);
        return response()->json(['message'=>'Child category created successfully','child_category'=>$child->load(['category','subcategory'])], 201);
    }
    public function show($id) { return response()->json(ChildCategory::with(['category','subcategory'])->findOrFail($id)); }
    public function update(Request $request, $id)
    {
        $child = ChildCategory::findOrFail($id);
        $validated = $this->validated($request, $child->id);
        $child->update($validated);
        Notification::create(['user_id'=>$request->user()->id,'title'=>'Child Category Updated','message'=>"Child category '{$child->name}' has been updated.",'type'=>'activity']);
        return response()->json(['message'=>'Child category updated successfully','child_category'=>$child->load(['category','subcategory'])]);
    }
    public function destroy($id)
    {
        $child = ChildCategory::findOrFail($id); $name = $child->name; $child->delete();
        Notification::create(['user_id'=>\Auth::id(),'title'=>'Child Category Deleted','message'=>"Child category '{$name}' has been removed.",'type'=>'activity']);
        return response()->json(['message'=>'Child category deleted successfully']);
    }
    private function validated(Request $request, ?int $ignoreId = null): array
    {
        $data = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'subcategory_id' => 'required|exists:subcategories,id',
            'name' => 'required|string|max:255',
            'slug' => ['nullable','string','max:255', Rule::unique('child_categories','slug')->where(fn($q) => $q->where('subcategory_id', $request->input('subcategory_id')))->ignore($ignoreId)],
            'image_url' => 'nullable|string',
            'sort_order' => 'nullable|integer',
            'is_active' => 'boolean',
        ]);
        $subcategory = Subcategory::find($data['subcategory_id']);
        if (!$subcategory || (int)$subcategory->category_id !== (int)$data['category_id']) throw ValidationException::withMessages(['subcategory_id'=>'Selected subcategory does not belong to the selected category.']);
        $data['slug'] = $data['slug'] ?? Str::slug($data['name']);
        $data['sort_order'] = $data['sort_order'] ?? 0;
        $data['is_active'] = $data['is_active'] ?? true;
        return $data;
    }
}
