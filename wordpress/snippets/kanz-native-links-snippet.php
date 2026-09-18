<?php
/** Optional standalone Code Snippet: run everywhere, without opening PHP tag.
 * Do not activate until Android Play App Signing fingerprints are confirmed.
 * Configure the fingerprint option through the admin form; defaults publish
 * Apple association only, never unverified Android certificates.
 */
if (!defined('ABSPATH')) return;
if (!function_exists('kanz_native_association')) {
    function kanz_native_association($path, $fingerprints) {
        if ($path === '/.well-known/apple-app-site-association') {
            return array('applinks' => array('apps' => array(), 'details' => array(
                array('appID' => 'T5T28K7SSZ.com.khtwah.kanzalsahra',
                    'paths' => array('/product/*', '/product-category/*',
                        '/product-tag/*', '/app-notification')),
            )));
        }
        if ($path !== '/.well-known/assetlinks.json' || !is_array($fingerprints)) return null;
        $validated = array();
        foreach ($fingerprints as $fingerprint) {
            if (!is_string($fingerprint) || !preg_match('/^(?:[A-Fa-f0-9]{2}:){31}[A-Fa-f0-9]{2}$/D', $fingerprint)) return null;
            $validated[] = strtoupper($fingerprint);
        }
        if (!$validated) return null;
        return array(array('relation' => array('delegate_permission/common.handle_all_urls'),
            'target' => array('namespace' => 'android_app',
                'package_name' => 'com.khtwah.kanzalsahra',
                'sha256_cert_fingerprints' => array_values(array_unique($validated)))));
    }
    add_action('template_redirect', function () {
        $path = parse_url(isset($_SERVER['REQUEST_URI']) ? $_SERVER['REQUEST_URI'] : '', PHP_URL_PATH);
        if (!in_array($path, array('/.well-known/assetlinks.json', '/.well-known/apple-app-site-association'), true)) return;
        $payload = kanz_native_association($path, get_option('kanz_native_link_fingerprints', array()));
        status_header($payload === null ? 503 : 200);
        header('Content-Type: application/json; charset=utf-8');
        header($payload === null ? 'Cache-Control: no-store' : 'Cache-Control: public, max-age=300');
        header('X-Content-Type-Options: nosniff');
        echo wp_json_encode($payload === null ? array('error' => 'Android signing fingerprints not configured') : $payload, JSON_UNESCAPED_SLASHES);
        exit;
    }, 0);
    add_action('admin_menu', function () {
        add_management_page('روابط تطبيق كنز', 'روابط تطبيق كنز', 'manage_options', 'kanz-native-links', function () {
            if (!current_user_can('manage_options')) return;
            echo '<div class="wrap" dir="rtl"><h1>ربط روابط المتجر بالتطبيق</h1><p>انسخ SHA-256 لشهادة App Signing من Google Play Console، وليس Upload key فقط. ضع كل شهادة في سطر. لا تنشر شهادة جديدة غير مؤكدة.</p><form method="post" action="' . esc_url(admin_url('admin-post.php')) . '">';
            wp_nonce_field('kanz_save_native_links');
            echo '<input type="hidden" name="action" value="kanz_save_native_links"><textarea name="fingerprints" dir="ltr" rows="5" cols="100">' . esc_textarea(implode("\n", get_option('kanz_native_link_fingerprints', array()))) . '</textarea>';
            submit_button('حفظ شهادات الربط');
            echo '</form><p>راجع /.well-known/assetlinks.json و/.well-known/apple-app-site-association بعد النشر. إذا منع خادم الموقع وصول الطلب إلى WordPress، يلزم إعداد الخادم.</p></div>';
        });
    });
    add_action('admin_post_kanz_save_native_links', function () {
        if (!current_user_can('manage_options')) wp_die('Not allowed', 403);
        check_admin_referer('kanz_save_native_links');
        $input = isset($_POST['fingerprints']) ? wp_unslash($_POST['fingerprints']) : '';
        if (!is_string($input) || strlen($input) > 4096) wp_die('Invalid fingerprints');
        $fingerprints = preg_split('/\s+/', trim($input), -1, PREG_SPLIT_NO_EMPTY);
        if (count($fingerprints) > 10 || kanz_native_association('/.well-known/assetlinks.json', $fingerprints) === null) wp_die('Valid SHA-256 fingerprints required');
        update_option('kanz_native_link_fingerprints', $fingerprints, false);
        wp_safe_redirect(admin_url('tools.php?page=kanz-native-links'));
        exit;
    });
}
