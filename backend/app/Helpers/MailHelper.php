<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MailHelper
{
    /**
     * Send an email using either Resend or PHPMailer based on MAILER_OPTION.
     *
     * @param string $toEmail
     * @param string $toName
     * @param string $subject
     * @param string $htmlBody
     * @throws \Exception
     */
    public static function send($toEmail, $toName, $subject, $htmlBody)
    {
        $mailerOption = env('MAILER_OPTION', 'phpmailer');

        if ($mailerOption === 'resend') {
            self::sendViaResend($toEmail, $toName, $subject, $htmlBody);
        } else {
            self::sendViaPHPMailer($toEmail, $toName, $subject, $htmlBody);
        }
    }

    /**
     * Send email using Resend API.
     *
     * @throws \Exception
     */
    private static function sendViaResend($toEmail, $toName, $subject, $htmlBody)
    {
        $apiKey = env('RESEND_API_KEY');
        $fromAddress = env('RESEND_FROM_ADDRESS', env('PHPMAILER_FROM_ADDRESS', 'onboarding@resend.dev'));
        $fromName = env('RESEND_FROM_NAME', env('PHPMAILER_FROM_NAME', 'HelloHomes'));

        if (empty($apiKey)) {
            throw new \Exception('Resend API key is not configured in .env file.');
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type' => 'application/json',
            ])->timeout(15)->post('https://api.resend.com/emails', [
                'from' => "{$fromName} <{$fromAddress}>",
                'to' => [$toEmail],
                'subject' => $subject,
                'html' => $htmlBody,
            ]);

            if (!$response->successful()) {
                $status = $response->status();
                $body = $response->json();
                $message = isset($body['message']) ? $body['message'] : 'Unknown error';
                $name = isset($body['name']) ? $body['name'] : '';

                Log::error('Resend API call failed: ' . json_encode($body));

                // Check for rate limit or usage quota exceeded
                if ($status === 422 || $status === 429 || stripos($message, 'limit') !== false || stripos($name, 'limit') !== false) {
                    throw new \Exception('Email sending limit exceeded. Please update the API key or try again later.');
                }

                throw new \Exception($message);
            }
        } catch (\Exception $e) {
            if (stripos($e->getMessage(), 'limit exceeded') !== false) {
                throw $e;
            }
            throw new \Exception($e->getMessage());
        }
    }

    /**
     * Send email using PHPMailer.
     *
     * @throws \Exception
     */
    private static function sendViaPHPMailer($toEmail, $toName, $subject, $htmlBody)
    {
        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

        $mail->isSMTP();
        $mail->Host       = env('PHPMAILER_HOST', 'smtp.gmail.com');
        $mail->SMTPAuth   = true;
        $mail->Username   = env('PHPMAILER_USERNAME');
        $mail->Password   = env('PHPMAILER_PASSWORD');

        $encryption = env('PHPMAILER_ENCRYPTION', 'smtps');
        if (strtolower($encryption) === 'tls') {
            $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
        } elseif (strtolower($encryption) === 'ssl' || strtolower($encryption) === 'smtps') {
            $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS;
        } else {
            $mail->SMTPSecure = '';
            $mail->SMTPAutoTLS = false;
        }

        $mail->Port       = env('PHPMAILER_PORT', 465);
        $mail->Timeout    = 10;

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
        $mail->addAddress($toEmail, $toName);

        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body    = $htmlBody;

        $mail->send();
    }
}
