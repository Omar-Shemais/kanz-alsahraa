<?php
// Isolated filesystem/crypto checks. No WordPress, customer data or FCM traffic.
define('ABSPATH', __DIR__ . '/fake-wordpress/');
class WP_Error { public $code; public function __construct($code, $message, $extra = array()) { $this->code = $code; } }
function add_action($hook, $callback) {}
function is_wp_error($value) { return $value instanceof WP_Error; }
function get_option($key, $default = false) { return $default; }
function wp_upload_dir() { return array('basedir' => $GLOBALS['test_root'], 'baseurl' => 'https://example.invalid/uploads'); }
function wp_json_encode($value, $flags = 0) { return json_encode($value, $flags); }
function wp_salt($scheme) { return 'TEST-ONLY-' . $scheme; }
function get_userdata($id) { return $id === 7 ? (object) array('ID' => 7) : false; }
function get_user_meta($id, $key, $single) { return $GLOBALS['test_token']; }
require __DIR__ . '/../snippets/kanz-app-control-snippet.php';
function check($condition, $label) { if (!$condition) { throw new Exception($label); } }
$root = sys_get_temp_dir() . '/kanz-control-test-' . bin2hex(random_bytes(8));
$GLOBALS['test_root'] = $root;
mkdir($root); mkdir($root . '/flutter_config_files');
$path = $root . '/flutter_config_files/config_ar.json';
$valid = (object) array('Setting' => (object) array(), 'TabBar' => array(array('layout' => 'home', 'icon' => 'home')), 'HorizonLayout' => array());
try {
    file_put_contents($path, json_encode($valid));
    $record = kanz_v5_mstore_record(); check(!is_wp_error($record), 'automatic MStore read');
    $valid->Setting->MainColor = '#abcdef';
    check(kanz_v5_mstore_publish($valid, $record['revision']) === true, 'atomic publication');
    check(json_decode(file_get_contents($path))->Setting->MainColor === '#abcdef', 'same file updated');
    check(is_wp_error(kanz_v5_mstore_publish($valid, $record['revision'])), 'stale editor rejected');
    check(kanz_v5_mstore_record()['revision'] !== $record['revision'], 'new revision loaded without import');
    $sealed = kanz_v5_fcm_seal('TEST PRIVATE MATERIAL');
    check(is_string($sealed) && strpos($sealed, 'TEST PRIVATE MATERIAL') === false, 'no plaintext secret');
    check(kanz_v5_fcm_unseal($sealed) === 'TEST PRIVATE MATERIAL', 'encrypted round trip');
    $bytes = base64_decode($sealed); $bytes[28] = chr(ord($bytes[28]) ^ 1);
    check(is_wp_error(kanz_v5_fcm_unseal(base64_encode($bytes))), 'ciphertext tampering rejected');
    $GLOBALS['test_token'] = str_repeat('A', 120);
    $payload = kanz_v5_notification_payload('Test', 'Test');
    $test = kanz_v5_notification_audience($payload, 'test_user', '7');
    check(isset($test['message']['token']) && !isset($test['message']['topic']), 'single device only');
    $GLOBALS['test_token'] = '';
    check(is_wp_error(kanz_v5_notification_audience($payload, 'test_user', '7')), 'missing token never broadcasts');
    check(is_wp_error(kanz_v5_notification_audience($payload, 'test_user', '999')), 'unknown account rejected');
    check(is_wp_error(kanz_v5_notification_audience($payload, 'other', '7')), 'unknown audience rejected');
    check(isset(kanz_v5_notification_audience($payload, 'broadcast')['message']['topic']), 'explicit marketing broadcast');
    echo "13 isolated MStore/credential/audience checks passed. No notifications sent.\n";
} finally {
    if (is_file($path)) { unlink($path); }
    rmdir($root . '/flutter_config_files'); rmdir($root);
}
