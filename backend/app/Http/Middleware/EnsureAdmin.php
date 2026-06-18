<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAdmin
{
    /**
     * Ensure the authenticated user is configured as an admin.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user || !in_array($user->email, config('admin.emails', []), true)) {
            return response()->json(['message' => 'Forbidden. Admin access is required.'], 403);
        }

        return $next($request);
    }
}
