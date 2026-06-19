<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HeroBanner;
use Illuminate\Http\Request;

class HeroBannerController extends Controller
{
    public function index(Request $request)
    {
        $query = HeroBanner::orderBy('sort_order')->orderBy('id');
        if ($request->boolean('active')) {
            $query->where('is_active', true);
        }
        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'image_url' => 'required|string|max:2048',
            'link_url' => 'nullable|string|max:2048',
            'is_active' => 'boolean',
        ]);
        $validated['sort_order'] = (HeroBanner::max('sort_order') ?? 0) + 1;
        return response()->json(HeroBanner::create($validated), 201);
    }

    public function update(Request $request, HeroBanner $heroBanner)
    {
        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'image_url' => 'required|string|max:2048',
            'link_url' => 'nullable|string|max:2048',
            'is_active' => 'boolean',
        ]);
        $heroBanner->update($validated);
        return response()->json($heroBanner);
    }

    public function destroy(HeroBanner $heroBanner)
    {
        $heroBanner->delete();
        return response()->json(['message' => 'Hero banner deleted successfully']);
    }

    public function updateOrder(Request $request)
    {
        $validated = $request->validate([
            'banner_ids' => 'required|array',
            'banner_ids.*' => 'integer|exists:hero_banners,id',
        ]);
        foreach ($validated['banner_ids'] as $index => $id) {
            HeroBanner::whereKey($id)->update(['sort_order' => $index + 1]);
        }
        return response()->json(HeroBanner::orderBy('sort_order')->get());
    }
}
