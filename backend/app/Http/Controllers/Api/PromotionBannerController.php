<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PromotionBanner;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PromotionBannerController extends Controller
{
    public function index(Request $request)
    {
        $query = PromotionBanner::with('product:id,title,price,original_price,image_url')->latest();

        if ($request->boolean('active')) {
            $now = Carbon::now('UTC');
            Log::debug('Promotion banner active query', [
                'current_time_utc' => $now->toIso8601String(),
            ]);

            PromotionBanner::latest()
                ->limit(5)
                ->get()
                ->each(fn (PromotionBanner $banner) => $this->logBannerStatus($banner));

            $query->where('is_active', true)
                ->where(function ($q) use ($now) {
                    $q->whereNull('offer_start_at')->orWhere('offer_start_at', '<=', $now);
                })
                ->where(function ($q) use ($now) {
                    $q->whereNull('offer_end_at')->orWhere('offer_end_at', '>', $now);
                })
                ->limit(1);
        }

        $banners = $query->get();

        $banners->each(fn (PromotionBanner $banner) => $this->logBannerStatus($banner));

        return response()->json($banners);
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
        $promotionBanner->update(['is_active' => false, 'offer_end_at' => Carbon::now('UTC')]);
        return response()->json($promotionBanner->fresh()->load('product:id,title,price,original_price,image_url'));
    }

    public function destroy(PromotionBanner $promotionBanner)
    {
        $promotionBanner->delete();
        return response()->json(['message' => 'Promotion banner deleted successfully']);
    }

    private function logBannerStatus(PromotionBanner $banner): void
    {
        $now = Carbon::now('UTC');
        $startAt = $banner->offer_start_at?->copy()->utc();
        $endAt = $banner->offer_end_at?->copy()->utc();
        $computedIsActive = $banner->is_active
            && ($startAt === null || $now->greaterThanOrEqualTo($startAt))
            && ($endAt === null || $now->lessThan($endAt));

        Log::debug('Promotion banner active status', [
            'banner_id' => $banner->id,
            'current_time_utc' => $now->toIso8601String(),
            'offer_start_at_utc' => $startAt?->toIso8601String(),
            'offer_end_at_utc' => $endAt?->toIso8601String(),
            'enabled' => $banner->is_active,
            'computed_isActive' => $computedIsActive,
        ]);
    }

    private function validateBanner(Request $request): array
    {
        $validated = $request->validate([
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

        foreach (['offer_start_at', 'offer_end_at'] as $field) {
            if (!empty($validated[$field])) {
                $validated[$field] = Carbon::parse($validated[$field])->utc();
            }
        }

        return $validated;
    }
}
