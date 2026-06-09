# WooCommerce Development

**Purpose** — Build and extend WooCommerce stores: setup, payments, shipping, custom product
types, optimization, and WP 7.0 AI/Abilities features. Use [wp-cli.md](wp-cli.md) for
shell ops, [test-login.md](test-login.md) + [gutenberg.md](gutenberg.md) for UI/editor tests,
and [penetration-testing.md](penetration-testing.md) for security review.

## WP 7.0 + WooCommerce capabilities

- **AI Client** — product descriptions, customer Q&A, fraud signals, marketing copy.
- **DataViews** — modern order management (filtering, sorting, activity layout).
- **Real-time collaboration** — collaborative order editing, live inventory.
- **Abilities API** — expose store operations (inventory, order processing) to agents/MCP.

## Build phases

1. **Store setup** — install WooCommerce, run the wizard, configure store/tax/currency.
2. **Products** — categories, attributes, product types, variable products, images.
3. **Payments** — choose gateways (Stripe, PayPal, offline), then test each flow.
4. **Shipping** — zones, methods (flat rate, free, express), carrier integration.
5. **Customization** — product/cart/checkout templates and custom fields.
6. **Extensions** — subscriptions, bookings, memberships; register Abilities (below).
7. **Optimization** — image optimization, caching, DB tuning, CDN, lazy loading.
8. **Testing** — checkout, payments, emails, mobile, AI features, DataViews.

## AI Client pattern (guard, then prompt)

AI features are enabled by installing a provider connector (Settings > Connectors). Always
guard on availability and handle `WP_Error` — never block checkout on an AI failure.

```php
function my_ai_text($prompt, $temperature = 0.3) {
    if (!function_exists('wp_ai_client_prompt')) {
        return null; // AI unavailable -> caller falls back gracefully
    }
    $result = wp_ai_client_prompt($prompt);
    if (is_wp_error($result)) {
        return null;
    }
    $result->using_temperature($temperature); // low temp for classification, higher for prose
    $text = $result->generate_text();
    return is_wp_error($text) ? null : $text;
}

// Auto product description (skip if one exists)
add_action('woocommerce_new_product', function ($product_id, $product) {
    if ($product->get_description()) return;
    $text = my_ai_text(sprintf(
        'Write an SEO-friendly WooCommerce product description for "%s".',
        $product->get_name()
    ));
    if ($text) { $product->set_description($text); $product->save(); }
}, 10, 2);
```

Use the same guard for fraud scoring (`woocommerce_after_checkout_validation`, low temp,
`add` a soft notice on "suspicious" — never hard-block), shipping hints, and product Q&A
(AJAX with `check_ajax_referer` nonce + `sanitize_text_field`/`absint` on all input).

## Abilities API for WooCommerce (WP 7.0)

Register a category, then abilities with input/output schemas and a `permission_callback`.
Validate input with `absint`/`sanitize_*` and return `WP_Error` on bad data.

```php
add_action('wp_abilities_api_categories_init', function () {
    wp_register_ability_category('ecommerce', [
        'label'       => __('E-Commerce', 'woocommerce'),
        'description' => __('WooCommerce store management and operations', 'woocommerce'),
    ]);
});

add_action('wp_abilities_api_init', function () {
    wp_register_ability('woocommerce/update-inventory', [
        'label'        => __('Update Inventory', 'woocommerce'),
        'description'  => __('Update product stock quantity', 'woocommerce'),
        'category'     => 'ecommerce',
        'input_schema' => [
            'type'       => 'object',
            'properties' => [
                'product_id' => ['type' => 'integer'],
                'quantity'   => ['type' => 'integer'],
            ],
            'required' => ['product_id', 'quantity'],
        ],
        'output_schema' => [
            'type'       => 'object',
            'properties' => [
                'success'      => ['type' => 'boolean'],
                'new_quantity' => ['type' => 'integer'],
            ],
        ],
        'execute_callback' => function ($input) {
            $product = wc_get_product(absint($input['product_id'] ?? 0));
            if (!$product) return new WP_Error('invalid_product', 'Product not found');
            wc_update_product_stock($product, absint($input['quantity'] ?? 0));
            return ['success' => true, 'new_quantity' => $product->get_stock_quantity()];
        },
        'permission_callback' => fn () => current_user_can('manage_woocommerce'),
    ]);
});
```

The `/run` endpoint (`wp-json/wp-abilities/v1/abilities/<name>/run`) enforces
`permission_callback` — test that boundary (see [penetration-testing.md](penetration-testing.md)).

## Quality gates

- [ ] Products display; checkout completes; payments process; shipping calculates; emails send.
- [ ] Mobile responsive.
- [ ] WP 7.0: AI features guard-and-fallback correctly; DataViews and collaboration work.
