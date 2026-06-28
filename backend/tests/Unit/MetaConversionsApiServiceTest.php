<?php

namespace Tests\Unit;

use App\Models\Order;
use App\Models\OrderItem;
use App\Services\MetaConversionsApiService;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MetaConversionsApiServiceTest extends TestCase
{
    public function test_send_purchase_posts_expected_payload_to_meta_graph_api(): void
    {
        config([
            'services.meta.pixel_id' => 'pixel-123',
            'services.meta.access_token' => 'token-abc',
            'services.meta.test_event_code' => null,
        ]);

        Http::fake([
            'https://graph.facebook.com/v23.0/pixel-123/events' => Http::response([
                'events_received' => 1,
                'messages' => [],
                'fbtrace_id' => 'trace-123',
            ], 200),
        ]);

        $order = new Order([
            'total_amount' => 1250.50,
            'full_name' => 'Jane Buyer',
            'email' => 'jane@example.com',
            'phone' => '+94 77 123 4567',
        ]);
        $order->id = 42;
        $order->setRelation('items', collect([
            new OrderItem(['product_id' => 11, 'quantity' => 2, 'price' => 500]),
            new OrderItem(['product_id' => 12, 'quantity' => 1, 'price' => 250.50]),
        ]));

        app(MetaConversionsApiService::class)->sendPurchase($order, 'frontend-event-123', [
            'email' => 'jane@example.com',
            'phone' => '+94 77 123 4567',
            'first_name' => 'Jane',
            'last_name' => 'Buyer',
            'client_ip_address' => '203.0.113.10',
            'client_user_agent' => 'Unit Test Browser',
        ], 'https://hellohomes.test/order-success');

        Http::assertSent(function ($request) {
            $payload = $request->data();
            $event = $payload['data'][0] ?? [];

            return $request->url() === 'https://graph.facebook.com/v23.0/pixel-123/events'
                && $payload['access_token'] === 'token-abc'
                && $event['event_name'] === 'Purchase'
                && is_int($event['event_time'])
                && $event['event_id'] === 'frontend-event-123'
                && $event['action_source'] === 'website'
                && $event['event_source_url'] === 'https://hellohomes.test/order-success'
                && $event['custom_data']['value'] === 1250.50
                && $event['custom_data']['currency'] === 'LKR'
                && $event['custom_data']['content_ids'] === ['11', '12']
                && $event['custom_data']['content_type'] === 'product'
                && isset($event['user_data']['em'], $event['user_data']['ph'])
                && $event['user_data']['client_ip_address'] === '203.0.113.10'
                && $event['user_data']['client_user_agent'] === 'Unit Test Browser';
        });
    }
}
