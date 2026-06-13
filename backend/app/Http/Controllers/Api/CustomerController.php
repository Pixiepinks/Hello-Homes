<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use App\Models\Notification;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->has('search')) {
            $query->where(function($q) use ($request) {
                $q->where('name', 'like', '%' . $request->search . '%')
                  ->orWhere('email', 'like', '%' . $request->search . '%');
            });
        }

        return response()->json($query->orderBy('created_at', 'desc')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
        ]);

        $validated['password'] = Hash::make($validated['password']);

        $user = User::create($validated);

        // Notify Admin Activity
        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Customer Account Created',
            'message' => "New customer account for '{$user->name}' has been created.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Customer created successfully', 'customer' => $user]);
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,'.$id,
            'password' => 'nullable|string|min:6',
        ]);

        if (!empty($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $user->update($validated);

        // Notify Admin Activity
        Notification::create([
            'user_id' => $request->user()->id,
            'title' => 'Customer Updated',
            'message' => "Customer details for '{$user->name}' have been updated.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Customer updated successfully', 'customer' => $user]);
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);
        $name = $user->name;
        $user->delete();

        // Notify Admin Activity
        Notification::create([
            'user_id' => \Auth::id(),
            'title' => 'Customer Account Deleted',
            'message' => "Customer account '{$name}' has been removed.",
            'type' => 'activity',
        ]);

        return response()->json(['message' => 'Customer deleted successfully']);
    }
}
