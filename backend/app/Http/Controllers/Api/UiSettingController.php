<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UiSetting;
use Illuminate\Http\Request;

class UiSettingController extends Controller
{
    public function index()
    {
        return response()->json(UiSetting::allAsArray());
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'product_name_one_line' => 'required|boolean',
            'products_per_row_desktop' => 'required|integer|min:2|max:6',
            'currency_symbol' => 'required|string|max:10',
            'show_carousel_arrows' => 'required|boolean',
        ]);

        foreach ($validated as $key => $value) {
            UiSetting::updateOrCreate(
                ['key' => $key],
                ['value' => is_bool($value) ? ($value ? '1' : '0') : (string) $value]
            );
        }

        return response()->json(UiSetting::allAsArray());
    }
}
