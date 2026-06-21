<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class BrandController extends Controller
{
    public function index(Request $request)
    {
        $query = Brand::orderBy('name');
        if ($request->has('active')) $query->where('is_active', $request->boolean('active'));
        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $this->validated($request);
        $brand = Brand::create($validated);
        Notification::create(['user_id' => $request->user()->id, 'title' => 'Brand Created', 'message' => "Brand '{$brand->name}' has been created.", 'type' => 'activity']);
        return response()->json(['message' => 'Brand created successfully', 'brand' => $brand], 201);
    }

    public function show($id) { return response()->json(Brand::findOrFail($id)); }

    public function update(Request $request, $id)
    {
        $brand = Brand::findOrFail($id);
        $validated = $this->validated($request, $brand->id);
        $brand->update($validated);
        Notification::create(['user_id' => $request->user()->id, 'title' => 'Brand Updated', 'message' => "Brand '{$brand->name}' has been updated.", 'type' => 'activity']);
        return response()->json(['message' => 'Brand updated successfully', 'brand' => $brand]);
    }

    public function destroy($id)
    {
        $brand = Brand::findOrFail($id); $name = $brand->name; $brand->delete();
        Notification::create(['user_id' => \Auth::id(), 'title' => 'Brand Deleted', 'message' => "Brand '{$name}' has been removed.", 'type' => 'activity']);
        return response()->json(['message' => 'Brand deleted successfully']);
    }

    private function validated(Request $request, ?int $ignoreId = null): array
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => ['nullable','string','max:255', Rule::unique('brands','slug')->ignore($ignoreId)],
            'logo_url' => 'nullable|string',
            'is_active' => 'boolean',
        ]);
        $data['slug'] = $data['slug'] ?? Str::slug($data['name']);
        $data['is_active'] = $data['is_active'] ?? true;
        return $data;
    }
}
