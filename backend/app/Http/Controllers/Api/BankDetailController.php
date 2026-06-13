<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankDetail;
use App\Models\Notification;
use Illuminate\Http\Request;

class BankDetailController extends Controller
{
    public function index()
    {
        return response()->json(BankDetail::all());
    }

    public function active()
    {
        return response()->json(BankDetail::where('is_active', true)->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'account_name' => 'required|string',
            'account_number' => 'required|string',
            'bank_name' => 'required|string',
            'branch_name' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $bankDetail = BankDetail::create($validated);

        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Bank Detail Added',
            'message' => "New bank account '{$bankDetail->bank_name}' has been added.",
            'type' => 'activity',
        ]);

        return response()->json($bankDetail, 201);
    }

    public function update(Request $request, $id)
    {
        $bankDetail = BankDetail::findOrFail($id);
        
        $validated = $request->validate([
            'account_name' => 'required|string',
            'account_number' => 'required|string',
            'bank_name' => 'required|string',
            'branch_name' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $bankDetail->update($validated);

        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Bank Detail Updated',
            'message' => "Bank account '{$bankDetail->bank_name}' has been updated.",
            'type' => 'activity',
        ]);

        return response()->json($bankDetail);
    }

    public function destroy($id)
    {
        $bankDetail = BankDetail::findOrFail($id);
        $name = $bankDetail->bank_name;
        $bankDetail->delete();

        Notification::create([
            'user_id' => \Auth::id(),
            'title' => 'Bank Detail Deleted',
            'message' => "Bank account '{$name}' has been removed.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Bank detail deleted successfully']);
    }
}
