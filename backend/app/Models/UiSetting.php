<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UiSetting extends Model
{
    protected $guarded = [];
    public $timestamps = true;

    public static function defaults(): array
    {
        return [
            'product_name_one_line' => true,
            'products_per_row_desktop' => 6,
            'currency_symbol' => 'Rs.',
            'show_carousel_arrows' => true,
        ];
    }

    public static function allAsArray(): array
    {
        $settings = self::defaults();
        foreach (self::all() as $setting) {
            $settings[$setting->key] = self::castValue($setting->value, $settings[$setting->key] ?? null);
        }
        return $settings;
    }

    private static function castValue(?string $value, $default)
    {
        if (is_bool($default)) {
            return filter_var($value, FILTER_VALIDATE_BOOLEAN);
        }
        if (is_int($default)) {
            return (int) $value;
        }
        return $value;
    }
}
