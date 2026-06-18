<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use App\Models\Notification;

class AuthController extends Controller
{
    public function checkEmail(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);
        
        $exists = User::where('email', $request->email)->exists();
        
        return response()->json(['exists' => $exists]);
    }
    public function sendOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        // If user doesn't exist, create an empty one just to store the OTP
        if (!$user) {
            $user = User::create([
                'name' => 'Guest User',
                'email' => $request->email,
                'password' => Hash::make(\Illuminate\Support\Str::random(16)),
            ]);
        }

        // Generate a 6-digit OTP
        $otp = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
        
        $user->update([
            'otp' => Hash::make($otp),
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        // Send OTP via email synchronously
        try {
            $subject = 'Your Login OTP - Hello Homes';
            $body = "<h3>Hello Homes OTP</h3><p>Your One-Time Password is: <b>{$otp}</b></p><p>This OTP will expire in 10 minutes.</p>";

            \App\Helpers\MailHelper::send($user->email, $user->name, $subject, $body);

            // Notify User
            Notification::create([
                'user_id' => $user->id,
                'title' => 'OTP Sent',
                'message' => "A login OTP has been sent to your email.",
                'type' => 'activity',
            ]);
            
            // Return success only if mail was actually sent
            return response()->json(['message' => 'OTP sent successfully']);
        } catch (\Exception $e) {
            \Log::error('Failed to send OTP email: ' . $e->getMessage());
            $errorMessage = $e->getMessage();
            if (empty($errorMessage)) {
                $errorMessage = 'Failed to send OTP email. Please check your email address or try again later.';
            }
            return response()->json([
                'message' => $errorMessage,
                'error' => $errorMessage
            ], 500);
        }
    }

    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !$user->otp || !$user->otp_expires_at) {
            return response()->json(['message' => 'Invalid OTP.'], 400);
        }

        if (now()->greaterThan($user->otp_expires_at)) {
            return response()->json(['message' => 'OTP has expired.'], 400);
        }

        if (!Hash::check($request->otp, $user->otp)) {
            // Notify Failed Login
            Notification::create([
                'user_id' => $user->id,
                'title' => 'Failed Login Attempt',
                'message' => "An unsuccessful login attempt was made at " . now()->format('h:i A') . ".",
                'type' => 'activity',
            ]);
            return response()->json(['message' => 'Invalid OTP.'], 400);
        }

        // Clear OTP after successful verification
        $user->update([
            'otp' => null,
            'otp_expires_at' => null,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        $adminEmails = $this->adminEmails();
        $isAdmin = in_array(strtolower($user->email), $adminEmails, true);

        // Notify Successful Login
        Notification::create([
            'user_id' => $user->id,
            'title' => 'Successful Login',
            'message' => ($isAdmin ? "Admin" : "User") . " login successful at " . now()->format('h:i A') . ".",
            'type' => 'activity',
        ]);

        return response()->json([
            'message' => 'Login successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
            'is_admin' => $isAdmin,
        ]);
    }

    public function adminLogin(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $email = strtolower(trim($request->email));
        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();
        $adminEmails = $this->adminEmails();
        $passwordMatches = $user ? Hash::check($request->password, $user->password) : false;
        $isAdminEmail = $user ? in_array(strtolower($user->email), $adminEmails, true) : false;

        Log::info('ADMIN LOGIN', [
            'email' => $email,
            'user_exists' => $user ? true : false,
            'is_admin_email' => $isAdminEmail,
            'password_matches' => $passwordMatches,
        ]);

        if (!$user || !$passwordMatches || !$isAdminEmail) {
            Log::warning('Admin login failed', [
                'email' => $email,
                'user_exists' => (bool) $user,
                'is_admin_email' => (bool) $isAdminEmail,
                'password_matches' => (bool) $passwordMatches,
            ]);

            return response()->json(['message' => 'Invalid admin credentials.'], 401);
        }

        try {
            $token = $user->createToken('auth_token')->plainTextToken;
        } catch (\Throwable $e) {
            Log::error('Admin token creation failed', [
                'email' => $email,
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }

        Notification::create([
            'user_id' => $user->id,
            'title' => 'Successful Login',
            'message' => "Admin password login successful at " . now()->format('h:i A') . ".",
            'type' => 'activity',
        ]);

        return response()->json([
            'message' => 'Login successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user,
            'is_admin' => true,
        ]);
    }

    private function adminEmails(): array
    {
        return array_values(array_filter(array_unique(array_map(
            function ($email) {
                return strtolower(trim($email));
            },
            config('admin.emails', [])
        ))));
    }

    public function getUser(Request $request)
    {
        return response()->json($request->user());
    }

    public function updateDetails(Request $request)
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'name' => 'required|string',
            'phone' => 'nullable|string',
            'nic_number' => 'nullable|string',
            'street_address' => 'nullable|string',
            'district' => 'nullable|string',
            'postal_code' => 'nullable|string',
        ]);

        $user->update($validated);

        return response()->json(['message' => 'Details updated successfully', 'user' => $user]);
    }
}
