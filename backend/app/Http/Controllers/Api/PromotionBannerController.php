<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PromotionBanner;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PromotionBannerController extends Controller
{
    public function index(Request $request)
    {
        $query = PromotionBanner::with('product:id,title,price,original_price,image_url')->latest();

        if ($request->boolean('active')) {
            $now = Carbon::now();
            $query->where('is_active', true)
                ->where(function ($q) use ($now) {
                    $q->whereNull('offer_start_at')->orWhere('offer_start_at', '<=', $now);
                })
                ->where(function ($q) use ($now) {
                    $q->whereNull('offer_end_at')->orWhere('offer_end_at', '>', $now);
                })
                ->limit(1);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $this->validateBanner($request);

        return DB::transaction(function () use ($validated) {
            if (!empty($validated['is_active'])) {
                PromotionBanner::where('is_active', true)->update(['is_active' => false]);
            }
            $banner = PromotionBanner::create($validated);
            return response()->json($banner->load('product:id,title,price,original_price,image_url'), 201);
        });
    }

    public function update(Request $request, PromotionBanner $promotionBanner)
    {
        $validated = $this->validateBanner($request);

        return DB::transaction(function () use ($validated, $promotionBanner) {
            if (!empty($validated['is_active'])) {
                PromotionBanner::where('id', '!=', $promotionBanner->id)->where('is_active', true)->update(['is_active' => false]);
            }
            $promotionBanner->update($validated);
            return response()->json($promotionBanner->fresh()->load('product:id,title,price,original_price,image_url'));
        });
    }

    public function end(PromotionBanner $promotionBanner)
    {
        $promotionBanner->update(['is_active' => false, 'offer_end_at' => Carbon::now()]);
        return response()->json($promotionBanner->fresh()->load('product:id,title,price,original_price,image_url'));
    }

    public function destroy(PromotionBanner $promotionBanner)
    {
        $promotionBanner->delete();
        return response()->json(['message' => 'Promotion banner deleted successfully']);
    }

    private function validateBanner(Request $request): array
    {
        return $request->validate([
            'is_active' => 'boolean',
            'title' => 'nullable|string|max:255',
            'subtitle' => 'nullable|string|max:255',
            'banner_image_url' => 'required|string|max:2048',
            'product_id' => 'required|exists:products,id',
            'product_slug' => 'nullable|string|max:255',
            'product_url' => 'nullable|string|max:2048',
            'discount_percentage' => 'nullable|integer|min:0|max:100',
            'original_price' => 'nullable|numeric|min:0',
            'discounted_price' => 'nullable|numeric|min:0',
            'offer_start_at' => 'nullable|date',
            'offer_end_at' => 'required|date|after:offer_start_at',
        ]);
    }
}
