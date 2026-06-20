<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\PaymentSetting;
use Illuminate\Http\Request;

class PaymentSettingController extends Controller
{
    public function show()
    {
        return response()->json(PaymentSetting::current());
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'bank_transfer_enabled' => 'required|boolean',
            'card_payment_enabled' => 'required|boolean',
            'qr_payment_enabled' => 'required|boolean',
        ]);

        $settings = PaymentSetting::current();
        $settings->update($validated);

        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Payment Settings Updated',
            'message' => 'Payment method availability has been updated.',
            'type' => 'activity',
        ]);

        return response()->json($settings);
    }
}
