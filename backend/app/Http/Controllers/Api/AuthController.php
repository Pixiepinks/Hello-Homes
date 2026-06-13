<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
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
            $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
            
            $mail->isSMTP();
            $mail->Host       = env('PHPMAILER_HOST', 'smtp.gmail.com');
            $mail->SMTPAuth   = true;
            $mail->Username   = env('PHPMAILER_USERNAME');
            $mail->Password   = env('PHPMAILER_PASSWORD');
            
            $encryption = env('PHPMAILER_ENCRYPTION', 'smtps');
            if (strtolower($encryption) === 'tls') {
                $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            } else {
                $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS;
            }
            
            $mail->Port       = env('PHPMAILER_PORT', 465);

            if (env('APP_ENV') === 'local') {
                $mail->SMTPOptions = array(
                    'ssl' => array(
                        'verify_peer' => false,
                        'verify_peer_name' => false,
                        'allow_self_signed' => true
                    )
                );
            }

            $mail->setFrom(env('PHPMAILER_FROM_ADDRESS'), env('PHPMAILER_FROM_NAME'));
            $mail->addAddress($user->email, $user->name);

            $mail->isHTML(true);
            $mail->Subject = 'Your Login OTP - Hello Homes';
            $mail->Body    = "<h3>Hello Homes OTP</h3><p>Your One-Time Password is: <b>{$otp}</b></p><p>This OTP will expire in 10 minutes.</p>";

            $mail->send();

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
            return response()->json([
                'message' => 'Failed to send OTP email. Please check your email address or try again later.',
                'error' => $e->getMessage()
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

        $adminEmails = array_map('trim', explode(',', env('ADMIN_EMAILS', '')));
        $isAdmin = in_array($user->email, $adminEmails);

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
