<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class OrderReceipt extends Mailable
{
    use Queueable, SerializesModels;

    public $order;
    public $password;

    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct($order, $password = null)
    {
        $this->order = $order;
        $this->password = $password;
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        return $this->subject('Order Confirmation - Hello Homes')
                    ->view('emails.order_receipt');
    }
}
