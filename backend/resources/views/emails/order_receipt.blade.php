<!DOCTYPE html>
<html>
<head>
    <title>Order Receipt</title>
</head>
<body>
    <h1>Thank you for your order, {{ $order->full_name }}!</h1>
    <p>Your order (ID: {{ $order->id }}) has been received and is currently being processed.</p>
    
    <h3>Order Details:</h3>
    <ul>
        <li><strong>Status:</strong> {{ $order->status }}</li>
        <li><strong>Total Amount:</strong> ${{ number_format($order->total_amount, 2) }}</li>
        <li><strong>Payment Method:</strong> {{ $order->payment_method }}</li>
        <li><strong>Shipping Address:</strong> {{ $order->street_address }}, {{ $order->district }} {{ $order->postal_code }}</li>
    </ul>

    @if($password)
        <hr>
        <h3>Your Account Details:</h3>
        <p>We have automatically created an account for you so you can track your order.</p>
        <p><strong>Email:</strong> {{ $order->email }}</p>
        <p><strong>Password:</strong> {{ $password }}</p>
        <p>You can log in to our website using these credentials.</p>
    @endif

    <p>Thank you for shopping with Hello Homes!</p>
</body>
</html>
