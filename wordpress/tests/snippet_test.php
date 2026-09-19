<?php
define('ABSPATH', __DIR__ . '/fake-wordpress/');
class WP_Error { public function __construct($code, $message) {} }
$hooks = array();
function add_action($hook, $callback) { $GLOBALS['hooks'][] = $hook; }
function is_wp_error($value) { return $value instanceof WP_Error; }
function get_option($key, $default = false) { return isset($GLOBALS['mock_options'][$key]) ? $GLOBALS['mock_options'][$key] : $default; }
// Simulate an older active revision loaded before Code Snippets validates the replacement.
function kanz_snippet_admin_js() { return 'old revision'; }
function kanz_config_validate($value) { return true; }
require __DIR__ . '/../snippets/kanz-app-control-snippet.php';
$first_hooks = $hooks;
require __DIR__ . '/../snippets/kanz-app-control-snippet.php';
if ($first_hooks !== $hooks || count($hooks) !== 6) { throw new Exception('Duplicate snippet registration.'); }
foreach (array('admin_menu', 'admin_enqueue_scripts', 'admin_post_kanz_save_config', 'admin_post_kanz_send_notification', 'admin_post_kanz_save_fcm_key', 'rest_api_init') as $hook) {
    if (!in_array($hook, $hooks, true)) { throw new Exception('Missing hook.'); }
}
$valid = array('Setting' => array(), 'TabBar' => array(array('layout' => 'home', 'icon' => 'home')), 'HorizonLayout' => array());
if (kanz_v5_config_validate($valid) !== true || !is_wp_error(kanz_v5_notification_credentials())) { throw new Exception('Snippet safety check failed.'); }
$script = kanz_v5_snippet_admin_js();
if (strpos($script, 'DOMContentLoaded') === false || strpos($script, 'kanz-sections') === false) { throw new Exception('Missing inline editor.'); }
echo 'Standalone snippet checks passed: hooks, duplicate-load guard, config validation, disabled sender and inline editor.' . PHP_EOL;
