<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DeliveryOptionController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\BankDetailController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public Routes
Route::get('/products', [ProductController::class, 'index']);
Route::get('/categories', [CategoryController::class, 'index']);
Route::post('/orders', [OrderController::class, 'store']);
Route::post('/orders/{id}/upload-slip', [OrderController::class, 'uploadSlip']);
Route::get('/bank-details/active', [BankDetailController::class, 'active']);
Route::get('/delivery-options', [DeliveryOptionController::class, 'index']);

// Public Auth Routes
Route::get('/auth/check-email', [AuthController::class, 'checkEmail']);
Route::post('/auth/send-otp', [AuthController::class, 'sendOtp']);
Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp']);
Route::post('/auth/admin-login', [AuthController::class, 'adminLogin']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'getUser']);
    Route::put('/user/details', [AuthController::class, 'updateDetails']);
    Route::get('/user/orders', [OrderController::class, 'userOrders']);
    
    Route::middleware('admin')->group(function () {
        // Product Management (Admin)
        Route::post('/products', [ProductController::class, 'store']);
        Route::put('/products/{id}', [ProductController::class, 'update']);
        Route::delete('/products/{id}', [ProductController::class, 'destroy']);

        // Admin Resources
        Route::apiResource('categories', CategoryController::class)->except(['index']);
        Route::apiResource('customers', CustomerController::class);

        // Admin Order Routes
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/dashboard/stats', [OrderController::class, 'stats']);
        Route::put('/orders/{id}/status', [OrderController::class, 'updateStatus']);
        Route::delete('/orders/{id}/slip', [OrderController::class, 'deleteSlip']);

        // Delivery Options
        Route::apiResource('delivery-options', DeliveryOptionController::class)->except(['index']);
        Route::post('/delivery-options/bulk-update-products', [DeliveryOptionController::class, 'bulkUpdateProducts']);
        Route::post('/delivery-options/update-all-products', [DeliveryOptionController::class, 'updateAllProducts']);

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::get('/notifications/unread-count', [NotificationController::class, 'getUnreadCount']);
        Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::put('/notifications/mark-all-read', [NotificationController::class, 'markAllAsRead']);

        // Bank Details (Admin)
        Route::apiResource('bank-details', BankDetailController::class)->except(['active']);
    });
});
