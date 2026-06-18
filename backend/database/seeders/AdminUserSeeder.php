<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * Seed a test admin account using backend environment variables.
     *
     * @return void
     */
    public function run()
    {
        $email = strtolower(trim(config('admin.seed_email')));
        $password = config('admin.seed_password');

        if (!$email || !$password) {
            return;
        }

        $user = User::firstOrNew(['email' => $email]);

        $user->forceFill([
            'name' => config('admin.seed_name'),
            'password' => Hash::make($password),
            'email_verified_at' => now(),
            'otp' => null,
            'otp_expires_at' => null,
        ])->save();
    }
}
