<?php

final class Mail
{
    /**
     * Send the OTP code through the Resend API.
     */
    public static function sendOtpCode(array $config, string $toEmail, string $code): bool
    {
        $apiKey = $config['resend']['api_key'];
        if ($apiKey === '') {
            // Development mode: log the code instead of sending it.
            error_log("[shabdiz][dev] OTP for $toEmail: $code");
            return true;
        }

        $html = self::template($code);

        $ch = curl_init('https://api.resend.com/emails');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: Bearer ' . $apiKey,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS     => json_encode([
                'from'    => $config['resend']['from'],
                'to'      => [$toEmail],
                'subject' => "کد ورود شما: $code",
                'html'    => $html,
            ]),
        ]);
        $body   = curl_exec($ch);
        $status = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        curl_close($ch);

        if ($status < 200 || $status >= 300) {
            error_log('[shabdiz] resend error ' . $status . ': ' . substr((string) $body, 0, 300));
            return false;
        }
        return true;
    }

    private static function template(string $code): string
    {
        $digits = '';
        foreach (str_split($code) as $d) {
            $digits .= "<td style='padding:0 6px;'><div style='width:52px;height:64px;line-height:64px;text-align:center;font-size:30px;font-weight:700;color:#fff;background:#1c1c22;border-radius:12px;direction:ltr;'>$d</div></td>";
        }
        return <<<HTML
<!doctype html>
<html dir="rtl" lang="fa"><body style="margin:0;background:#0b0b0f;font-family:Tahoma,Vazirmatn,sans-serif;padding:40px 16px;">
  <div style="max-width:480px;margin:0 auto;background:#12121a;border-radius:24px;padding:40px 32px;text-align:center;border:1px solid #23232e;">
    <div style="font-size:26px;font-weight:800;color:#fff;letter-spacing:1px;margin-bottom:6px;">شبدیز</div>
    <div style="color:#8e8ea0;font-size:13px;margin-bottom:28px;">سینمای بی‌مرز، با یک کلیک</div>
    <div style="color:#fff;font-size:16px;margin-bottom:18px;">کد ورود شما:</div>
    <table dir="ltr" style="margin:0 auto;border-spacing:0;"><tr>$digits</tr></table>
    <div style="color:#8e8ea0;font-size:12px;margin-top:26px;">این کد ۵ دقیقه اعتبار دارد و هرگز با شما تماس نمی‌گیریم؛ آن را با کسی به اشتراک نگذارید.</div>
  </div>
</body></html>
HTML;
    }
}
