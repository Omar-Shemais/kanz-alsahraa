<?php
define('ABSPATH', __DIR__ . '/fake-wordpress/');
define('MINUTE_IN_SECONDS', 60);
define('DAY_IN_SECONDS', 86400);
class WP_Error {
    public $code;
    public $message;
    public $data;
    public function __construct($code, $message, $data = array()) { $this->code = $code; $this->message = $message; $this->data = $data; }
}
class WP_REST_Response {
    public $data;
    public $status;
    public $headers = array();
    public function __construct($data, $status = 200) { $this->data = $data; $this->status = $status; }
    public function header($name, $value) { $this->headers[$name] = $value; }
}
class Kanz_Test_Request {
    private $cookie;
    private $params;
    public function __construct($cookie, $params = array()) { $this->cookie = $cookie; $this->params = $params; }
    public function get_header($name) { return strtolower($name) === 'user-cookie' ? $this->cookie : ''; }
    public function get_param($name) { return isset($this->params[$name]) ? $this->params[$name] : null; }
}
$hooks = array();
function add_action($hook, $callback) { $GLOBALS['hooks'][] = $hook; }
function is_wp_error($value) { return $value instanceof WP_Error; }
function get_option($key, $default = false) { return isset($GLOBALS['mock_options'][$key]) ? $GLOBALS['mock_options'][$key] : $default; }
function wp_validate_auth_cookie($cookie, $scheme) { return $cookie === 'valid-cookie' && $scheme === 'logged_in' ? 42 : false; }
function wp_set_current_user($user_id) { $GLOBALS['current_user_id'] = $user_id; }
function get_transient($key) { return isset($GLOBALS['transients'][$key]) ? $GLOBALS['transients'][$key] : false; }
function set_transient($key, $value, $expiration) { $GLOBALS['transients'][$key] = $value; return true; }
function delete_transient($key) { unset($GLOBALS['transients'][$key]); return true; }
function get_userdata($user_id) { return $user_id === 42 ? (object) array('ID' => 42) : false; }
function wp_set_password($password, $user_id) { $GLOBALS['updated_password'] = array($user_id, $password); }
function wp_generate_auth_cookie($user_id, $expiration, $scheme) { return $user_id === 42 && $scheme === 'logged_in' ? 'rotated-cookie' : ''; }
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
if (kanz_v6_config_validate($valid) !== true || !is_wp_error(kanz_v6_notification_credentials())) { throw new Exception('Snippet safety check failed.'); }
$with_drawer = $valid;
$with_drawer['KanzDrawerV2'] = array('enabled' => true, 'showTracking' => true, 'rootCategoryIds' => array('124', '130'));
if (kanz_v6_config_validate($with_drawer) !== true) { throw new Exception('Valid drawer configuration was rejected.'); }
$with_drawer['KanzDrawerV2']['rootCategoryIds'] = array('javascript:alert(1)');
if (!is_wp_error(kanz_v6_config_validate($with_drawer))) { throw new Exception('Invalid drawer category was accepted.'); }
$script = kanz_v6_snippet_admin_js();
if (strpos($script, 'DOMContentLoaded') === false || strpos($script, 'kanz-sections') === false) { throw new Exception('Missing inline editor.'); }
$source = file_get_contents(__DIR__ . '/../snippets/kanz-app-control-snippet.php');
foreach (array("'/account/password'", "get_header('User-Cookie')", 'wp_validate_auth_cookie', 'wp_set_password', 'wp_generate_auth_cookie', "'Cache-Control', 'no-store'") as $required) {
    if (strpos($source, $required) === false) { throw new Exception('Missing password endpoint protection: ' . $required); }
}
if (strpos($source, "get_param('email')") !== false || strpos($source, "get_param('user_id')") !== false) {
    throw new Exception('Password endpoint must not select accounts using public identity fields.');
}
$invalid = kanz_v6_password_permission(new Kanz_Test_Request('invalid-cookie'));
if (!is_wp_error($invalid) || $invalid->code !== 'kanz_password_unauthorized') { throw new Exception('Invalid cookie was accepted.'); }
$mismatch = kanz_v6_set_account_password(new Kanz_Test_Request('valid-cookie', array('password' => 'password-one', 'password_confirmation' => 'password-two')));
if (!is_wp_error($mismatch) || isset($GLOBALS['updated_password'])) { throw new Exception('Mismatched password was accepted.'); }
$updated = kanz_v6_set_account_password(new Kanz_Test_Request('valid-cookie', array('password' => 'secure-password', 'password_confirmation' => 'secure-password')));
if (!($updated instanceof WP_REST_Response) || $updated->data['cookie'] !== 'rotated-cookie' || $GLOBALS['updated_password'] !== array(42, 'secure-password')) {
    throw new Exception('Authenticated password rotation failed.');
}
echo 'Standalone snippet checks passed: hooks, duplicate-load guard, config validation, password endpoint protection, disabled sender and inline editor.' . PHP_EOL;
