<?php

namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MetaConversionsApiService
{
    public function sendPurchase(Order $order, string $eventId, array $customerData, ?string $eventSourceUrl = null): void
    {
        $pixelId = config('services.meta.pixel_id');
        $accessToken = config('services.meta.access_token');

        if (empty($pixelId) || empty($accessToken)) {
            Log::warning('Meta CAPI Purchase skipped: missing pixel id or access token.', [
                'order_id' => $order->id,
                'event_id' => $eventId,
                'has_pixel_id' => !empty($pixelId),
                'has_access_token' => !empty($accessToken),
            ]);
            return;
        }

        $order->loadMissing('items');

        $payload = [
            'access_token' => $accessToken,
            'data' => [[
                'event_name' => 'Purchase',
                'event_time' => now()->timestamp,
                'event_id' => $eventId,
                'action_source' => 'website',
                'event_source_url' => $eventSourceUrl ?: url('/checkout'),
                'user_data' => $this->userData($customerData),
                'custom_data' => [
                    'currency' => 'LKR',
                    'value' => (float) $order->total_amount,
                    'content_type' => 'product',
                    'content_ids' => $order->items->pluck('product_id')->map(fn ($id) => (string) $id)->values()->all(),
                    'contents' => $order->items->map(fn ($item) => [
                        'id' => (string) $item->product_id,
                        'quantity' => (int) $item->quantity,
                        'item_price' => (float) $item->price,
                    ])->values()->all(),
                ],
            ]],
        ];

        if ($testCode = config('services.meta.test_event_code')) {
            $payload['test_event_code'] = $testCode;
        }

        $url = "https://graph.facebook.com/v23.0/{$pixelId}/events";

        Log::info('Meta CAPI Purchase request payload.', [
            'order_id' => $order->id,
            'url' => $url,
            'payload' => $this->redactAccessToken($payload),
            'event_id' => $eventId,
        ]);

        try {
            $response = Http::timeout(5)->post($url, $payload);

            $responseJson = $response->json();

            Log::info('Meta CAPI Purchase response received.', [
                'order_id' => $order->id,
                'event_id' => $eventId,
                'status' => $response->status(),
                'response' => $responseJson,
                'body' => $response->body(),
            ]);

            if ($response->failed()) {
                Log::warning('Meta CAPI Purchase Graph API error.', [
                    'order_id' => $order->id,
                    'event_id' => $eventId,
                    'status' => $response->status(),
                    'error' => $responseJson['error'] ?? null,
                    'body' => $response->body(),
                ]);
                return;
            }
        } catch (\Throwable $e) {
            Log::warning('Meta CAPI Purchase exception.', [
                'order_id' => $order->id,
                'event_id' => $eventId,
                'message' => $e->getMessage(),
            ]);
        }
    }

    private function redactAccessToken(array $payload): array
    {
        if (isset($payload['access_token'])) {
            $token = (string) $payload['access_token'];
            $payload['access_token'] = strlen($token) <= 10
                ? str_repeat('*', strlen($token))
                : substr($token, 0, 6) . str_repeat('*', strlen($token) - 10) . substr($token, -4);
        }

        return $payload;
    }

    private function userData(array $data): array
    {
        return array_filter([
            'em' => $this->hash($data['email'] ?? null),
            'ph' => $this->hashPhone($data['phone'] ?? null),
            'fn' => $this->hash($data['first_name'] ?? null),
            'ln' => $this->hash($data['last_name'] ?? null),
            'client_ip_address' => $data['client_ip_address'] ?? null,
            'client_user_agent' => $data['client_user_agent'] ?? null,
        ]);
    }

    private function hash(?string $value): ?string
    {
        $normalized = strtolower(trim((string) $value));
        return $normalized === '' ? null : hash('sha256', $normalized);
    }

    private function hashPhone(?string $value): ?string
    {
        $normalized = preg_replace('/[^0-9]/', '', (string) $value);
        return $normalized === '' ? null : hash('sha256', $normalized);
    }
}
