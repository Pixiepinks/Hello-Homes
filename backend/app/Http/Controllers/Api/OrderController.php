<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use App\Mail\OrderReceipt;
use App\Models\Notification;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'full_name' => 'required|string',
            'phone' => 'required|string',
            'street_address' => 'required|string',
            'district' => 'required|string',
            'postal_code' => 'required|string',
            'payment_method' => 'required|string',
            'total_amount' => 'required|numeric',
            'delivery_fee' => 'required|numeric',
            'items' => 'required|array',
            'nic_number' => 'nullable|string',
            'password' => 'nullable|string|min:6', // Optional password for new account
        ]);

        // Check if user exists, if not create one
        $user = User::where('email', $validated['email'])->first();
        $generatedPassword = null;
        
        if (!$user) {
            $generatedPassword = $request->password ?? \Illuminate\Support\Str::random(8);
            $user = User::create([
                'name' => $validated['full_name'],
                'email' => $validated['email'],
                'password' => Hash::make($generatedPassword),
                'phone' => $validated['phone'],
                'nic_number' => $validated['nic_number'] ?? null,
                'street_address' => $validated['street_address'],
                'district' => $validated['district'],
                'postal_code' => $validated['postal_code'],
            ]);
        } else {
            // Update existing user details if they changed during checkout
            $user->update([
                'name' => $validated['full_name'],
                'phone' => $validated['phone'],
                'nic_number' => $validated['nic_number'] ?? $user->nic_number,
                'street_address' => $validated['street_address'],
                'district' => $validated['district'],
                'postal_code' => $validated['postal_code'],
            ]);
        }

        $orderData = $validated;
        unset($orderData['items']);
        unset($orderData['password']);
        $orderData['user_id'] = $user->id;

        $order = Order::create($orderData);

        foreach ($validated['items'] as $item) {
            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $item['id'],
                'product_title' => $item['title'],
                'quantity' => $item['quantity'],
                'price' => $item['price'],
            ]);
        }

        try {
            $subject = 'Order Confirmation - Hello Homes';
            $body = view('emails.order_receipt', ['order' => $order, 'password' => $generatedPassword])->render();

            \App\Helpers\MailHelper::send($order->email, $order->full_name, $subject, $body);
        } catch (\Exception $e) {
            \Log::error('Failed to send order receipt email: ' . $e->getMessage());
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        // Notify Admins
        $adminEmails = array_map('trim', explode(',', env('ADMIN_EMAILS', '')));
        $admins = User::whereIn('email', $adminEmails)->get();
        foreach ($admins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'title' => 'New Order Placed',
                'message' => "Order #{$order->id} has been placed by {$order->full_name}.",
                'type' => 'order',
                'reference_id' => $order->id,
            ]);
        }

        return response()->json([
            'message' => 'Order created successfully', 
            'order' => $order,
            'token' => $token,
            'user' => $user
        ]);
    }

    public function stats()
    {
        $totalSales = Order::sum('total_amount');
        $activeOrders = Order::where('status', 'pending')->count();
        $totalProducts = Product::count();

        return response()->json([
            'totalSales' => $totalSales,
            'activeOrders' => $activeOrders,
            'totalProducts' => $totalProducts,
        ]);
    }

    public function userOrders(Request $request)
    {
        $orders = Order::with('items')->where('user_id', $request->user()->id)->orderBy('created_at', 'desc')->get();
        return response()->json($orders);
    }

    public function index(Request $request)
    {
        $query = Order::with('items')->orderBy('created_at', 'desc');

        // Search by name, email, or order ID
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('id', 'like', "%{$search}%");
            });
        }

        // Filter by status
        if ($request->has('status') && $request->status != 'all') {
            $query->where('status', $request->status);
        }

        // Filter by payment method
        if ($request->has('payment_method') && $request->payment_method != 'all') {
            $query->where('payment_method', $request->payment_method);
        }

        return response()->json($query->paginate(10));
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,confirmed,refunded,delivered',
        ]);

        $order = Order::findOrFail($id);
        $oldStatus = $order->status;
        $order->status = $request->status;
        $order->save();

        // Notify user via email if status changed
        if ($oldStatus !== $order->status) {
            try {
                $subject = "Order #{$order->id} Status Updated - Hello Homes";
                $body    = "<h3>Order Status Update</h3>
                                 <p>Hello {$order->full_name},</p>
                                 <p>Your order <b>#{$order->id}</b> has been updated to: <b>" . strtoupper($order->status) . "</b>.</p>
                                 <p>Thank you for shopping with Hello Homes!</p>";

                \App\Helpers\MailHelper::send($order->email, $order->full_name, $subject, $body);
            } catch (\Exception $e) {
                \Log::error('Failed to send status update email: ' . $e->getMessage());
            }
            
            // Notify User
            Notification::create([
                'user_id' => $order->user_id,
                'title' => 'Order Status Updated',
                'message' => "Your order #{$order->id} status has been updated to " . strtoupper($order->status) . ".",
                'type' => 'order',
            ]);
        }

        return response()->json(['message' => 'Order status updated successfully', 'order' => $order]);
    }

    public function uploadSlip(Request $request, $id)
    {
        $request->validate([
            'slip' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        $order = Order::findOrFail($id);

        if ($request->hasFile('slip')) {
            $file = $request->file('slip');
            $originalName = pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);
            $extension = $file->getClientOriginalExtension();
            $safeName = \Illuminate\Support\Str::slug($originalName) . '.' . $extension;
            $filename = time() . '_' . $safeName;
            $path = $file->storeAs('public/slips', $filename);
            
            $order->payment_slip_path = '/storage/slips/' . $filename;
            $order->save();

            // Notify Admins
            $adminEmails = array_map('trim', explode(',', env('ADMIN_EMAILS', '')));
            $admins = User::whereIn('email', $adminEmails)->get();
            foreach ($admins as $admin) {
                Notification::create([
                    'user_id' => $admin->id,
                    'title' => 'Payment Slip Uploaded',
                    'message' => "A payment slip has been uploaded for order #{$order->id}.",
                    'type' => 'order',
                    'reference_id' => $order->id,
                ]);
            }

            return response()->json(['message' => 'Slip uploaded successfully', 'path' => $order->payment_slip_path]);
        }

        return response()->json(['message' => 'No file uploaded'], 400);
    }

    public function deleteSlip(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        
        if ($order->payment_slip_path) {
            $filePath = str_replace('/storage/', 'public/', $order->payment_slip_path);
            \Illuminate\Support\Facades\Storage::delete($filePath);
            $order->payment_slip_path = null;
            $order->save();
        }

        return response()->json(['message' => 'Payment slip deleted successfully']);
    }
}
