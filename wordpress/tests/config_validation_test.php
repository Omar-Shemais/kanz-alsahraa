<?php
// Standalone shape/security checks; not a substitute for a WordPress integration test.
define('ABSPATH', __DIR__ . '/fake-wordpress/');
class WP_Error { public $code; public function __construct($code, $message) { $this->code = $code; } }
function add_action($hook, $callback) {}
function is_wp_error($value) { return $value instanceof WP_Error; }
function get_option($key, $default = false) { return isset($GLOBALS['mock_options'][$key]) ? $GLOBALS['mock_options'][$key] : $default; }
require __DIR__ . '/../kanz-app-control/kanz-app-control.php';
$valid = array('Setting' => array(), 'TabBar' => array(array('layout' => 'home', 'icon' => 'home')), 'HorizonLayout' => array(array('layout' => 'bannerImage', 'items' => array())));
$cases = array();
$cases[] = array($valid, true);
$bad = $valid; unset($bad['Setting']); $cases[] = array($bad, false);
$bad = $valid; $bad['TabBar'] = array(); $cases[] = array($bad, false);
$bad = $valid; $bad['TabBar'][0]['icon'] = array('bad'); $cases[] = array($bad, false);
$bad = $valid; $bad['HorizonLayout'][0]['items'] = 'bad'; $cases[] = array($bad, false);
$bad = $valid; $bad['Setting']['consumerSecret'] = 'sensitive'; $cases[] = array($bad, false);
$bad = $valid; $bad['Setting']['nested'] = array('private_key' => 'sensitive'); $cases[] = array($bad, false);
$bad = $valid; $bad['HorizonLayout'][0]['image'] = 'javascript:alert(1)'; $cases[] = array($bad, false);
$bad = $valid; $bad['Setting']['title'] = '<script>alert(1)</script>'; $cases[] = array($bad, false);
$bad = $valid; $bad['Setting']['DefaultTheme'] = 'system'; $cases[] = array($bad, false);
$good = $valid; $good['Setting']['DefaultTheme'] = 'dark'; $cases[] = array($good, true);
$bad = $valid; $bad['Setting']['custom'] = 'بند إضافي'; $cases[] = array($bad, true);
foreach ($cases as $index => $case) {
    if ((kanz_config_validate($case[0]) === true) !== $case[1]) { fwrite(STDERR, 'Failed case ' . $index . PHP_EOL); exit(1); }
}
echo count($cases) . ' validation checks passed.' . PHP_EOL;
$update = $valid;
$update['KanzControl'] = array('updates' => array('android' => array('enabled' => true, 'minimumBuild' => 23)));
$extra = array(array($update, true));
foreach (array('23', 0, -1, 2147483648) as $minimum) {
    $bad = $update; $bad['KanzControl']['updates']['android']['minimumBuild'] = $minimum;
    $extra[] = array($bad, false);
}
foreach ($extra as $index => $case) {
    if ((kanz_config_validate($case[0]) === true) !== $case[1]) { fwrite(STDERR, 'Failed update case ' . $index . PHP_EOL); exit(1); }
}
if (kanz_notification_payload('عنوان العرض', 'نص عام') instanceof WP_Error ||
    !(kanz_notification_payload('', 'text') instanceof WP_Error) ||
    !(kanz_notification_payload('<script>bad</script>', 'text') instanceof WP_Error) ||
    !(kanz_notification_credentials() instanceof WP_Error)) { fwrite(STDERR, 'Notification safety check failed.' . PHP_EOL); exit(1); }
$payload = kanz_notification_payload('عرض', 'خبر عام');
if ($payload['message']['topic'] !== 'all-notifications' || isset($payload['message']['token'])) { exit(1); }
// Destination validation checks
if (kanz_destination_data('none') !== array()) { exit(1); }
if (kanz_destination_data('category', '124') !== array('kanz_target' => 'category', 'kanz_id' => '124')) { exit(1); }
if (kanz_destination_data('product', '555') !== array('kanz_target' => 'product', 'kanz_id' => '555')) { exit(1); }
if (kanz_destination_data('cart') !== array('kanz_target' => 'cart')) { exit(1); }
if (kanz_destination_data('url', 'https://kanzalsahra.com/sale') !== array('kanz_target' => 'url', 'kanz_url' => 'https://kanzalsahra.com/sale')) { exit(1); }
if (!(kanz_destination_data('url', 'http://insecure.com') instanceof WP_Error)) { exit(1); }
if (!(kanz_destination_data('url', 'https://user:pass@kanzalsahra.com') instanceof WP_Error)) { exit(1); }
if (!(kanz_destination_data('category', 'abc') instanceof WP_Error)) { exit(1); }
$destPayload = kanz_notification_payload('تخفيضات', 'شاهد القسم الجديد', array('kanz_target' => 'category', 'kanz_id' => '124'));
if (!isset($destPayload['message']['data']['kanz_target']) || $destPayload['message']['data']['kanz_target'] !== 'category' || $destPayload['message']['data']['kanz_id'] !== '124') { exit(1); }
echo '10 update/notification checks and 8 destination checks passed. No messages sent.' . PHP_EOL;
