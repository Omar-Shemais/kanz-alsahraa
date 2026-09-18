<?php
defined('ABSPATH') || exit;

function kanz_destination_data($type, $value = '') {
    if ($type === 'none') { return array(); }
    if (in_array($type, array('category', 'product'), true) && is_string($value) && preg_match('/^[1-9][0-9]{0,9}$/', $value)) {
        return array('kanz_target' => $type, 'kanz_id' => $value);
    }
    if (in_array($type, array('home', 'category_page', 'cart', 'profile'), true)) { return array('kanz_target' => $type); }
    if ($type === 'url' && is_string($value) && strlen($value) <= 2048 && filter_var($value, FILTER_VALIDATE_URL)) {
        $uri = parse_url($value);
        if (!empty($uri['host']) && isset($uri['scheme']) && $uri['scheme'] === 'https' && !isset($uri['user']) && !isset($uri['pass'])) {
            return array('kanz_target' => 'url', 'kanz_url' => $value);
        }
    }
    return new WP_Error('invalid_destination', 'اختر وجهة صحيحة ورقم منتج أو تصنيف صالح، أو رابط HTTPS دون بيانات دخول.');
}

function kanz_destination_options($kind) {
    if ($kind === 'category') {
        if (!taxonomy_exists('product_cat')) { return array(); }
        $terms = get_terms(array('taxonomy' => 'product_cat', 'hide_empty' => false));
        if (is_wp_error($terms)) { return array(); }
        return array_map(function ($term) {
            return array(
                'id' => (string) $term->term_id,
                'name' => $term->name,
                'parent' => (int) $term->parent,
            );
        }, $terms);
    }
    $posts = get_posts(array('post_type' => 'product', 'post_status' => 'publish', 'numberposts' => 500, 'orderby' => 'title', 'order' => 'ASC'));
    return array_map(function ($post) { return array('id' => (string) $post->ID, 'name' => $post->post_title); }, $posts);
}

function kanz_notification_payload($title, $body, $destination = array()) {
    if (!is_string($title) || !is_string($body) || trim($title) === '' || trim($body) === '' ||
        strlen($title) > 240 || strlen($body) > 2400 || strip_tags($title) !== $title || strip_tags($body) !== $body) {
        return new WP_Error('invalid_message', 'أدخل عنواناً ونصاً قصيرين دون HTML.');
    }
    // Marketing only. Never use customer_ID topics for private order data.
    $payload = array('message' => array('topic' => 'all-notifications',
        'notification' => array('title' => trim($title), 'body' => trim($body))));
    if ($destination) {
        $checked = kanz_destination_data(isset($destination['kanz_target']) ? $destination['kanz_target'] : '', isset($destination['kanz_id']) ? $destination['kanz_id'] : (isset($destination['kanz_url']) ? $destination['kanz_url'] : ''));
        if (is_wp_error($checked)) { return $checked; }
        $payload['message']['data'] = $checked;
    }
    return $payload;
}

function kanz_notification_credentials() {
    if (!function_exists('openssl_sign')) {
        return new WP_Error('not_configured', 'الإشعارات غير مربوطة بخدمة Firebase على الخادم.');
    }
    $account = null;
    if (defined('KANZ_FCM_SERVICE_ACCOUNT_FILE')) {
        $path = realpath(KANZ_FCM_SERVICE_ACCOUNT_FILE);
        $root = realpath(isset($_SERVER['DOCUMENT_ROOT']) ? $_SERVER['DOCUMENT_ROOT'] : dirname(ABSPATH));
        // File must be outside the publicly served tree, not a Media upload.
        if ($path && $root && strpos(str_replace('\\', '/', $path), rtrim(str_replace('\\', '/', $root), '/') . '/') !== 0 &&
            is_file($path) && is_readable($path) && filesize($path) <= 65536) {
            $account = json_decode(file_get_contents($path), true);
        }
    }
    if (!$account) {
        $stored = get_option('kanz_fcm_service_account', '');
        if (is_string($stored) && trim($stored) !== '') {
            $account = json_decode($stored, true);
        }
    }
    if (!$account) {
        return new WP_Error('not_configured', 'الإشعارات غير مربوطة بخدمة Firebase. أدخل بيانات مفتاح Firebase في اللوحة أدناه.');
    }
    if (!is_array($account) || empty($account['project_id']) || empty($account['client_email']) || empty($account['private_key']) ||
        !is_string($account['project_id']) || !is_string($account['client_email']) ||
        !preg_match('/^[a-z][a-z0-9-]{4,62}$/', $account['project_id']) ||
        !filter_var($account['client_email'], FILTER_VALIDATE_EMAIL) || !is_string($account['private_key'])) {
        return new WP_Error('invalid_credentials', 'تعذر قراءة إعداد Firebase الخاص. تأكد من صحة ملف JSON.');
    }
    return $account;
}

function kanz_notification_send($payload) {
    $account = kanz_notification_credentials();
    if (is_wp_error($account)) { return $account; }
    $encode = function ($value) { return rtrim(strtr(base64_encode($value), '+/', '-_'), '='); };
    $now = time();
    $jwt = $encode(wp_json_encode(array('alg' => 'RS256', 'typ' => 'JWT'))) . '.' .
        $encode(wp_json_encode(array('iss' => $account['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600)));
    $signature = '';
    if (!openssl_sign($jwt, $signature, $account['private_key'], OPENSSL_ALGO_SHA256)) {
        return new WP_Error('signing_failed', 'تعذر اعتماد اتصال Firebase.');
    }
    // Fixed Google endpoints; never trust token_uri or URLs from an upload.
    $auth = wp_remote_post('https://oauth2.googleapis.com/token', array('timeout' => 20, 'redirection' => 0, 'sslverify' => true,
        'body' => array('grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt . '.' . $encode($signature))));
    if (is_wp_error($auth) || wp_remote_retrieve_response_code($auth) !== 200) {
        return new WP_Error('auth_failed', 'تعذر الاتصال بـFirebase. لم يُرسل الإشعار.');
    }
    $token = json_decode(wp_remote_retrieve_body($auth), true);
    if (!is_array($token) || empty($token['access_token']) || !is_string($token['access_token']) || preg_match('/[\r\n]/', $token['access_token'])) {
        return new WP_Error('auth_invalid', 'استجابة Firebase غير صالحة. لم يُرسل الإشعار.');
    }
    $result = wp_remote_post('https://fcm.googleapis.com/v1/projects/' . $account['project_id'] . '/messages:send', array(
        'timeout' => 20, 'redirection' => 0, 'sslverify' => true,
        'headers' => array('Authorization' => 'Bearer ' . $token['access_token'], 'Content-Type' => 'application/json'),
        'body' => wp_json_encode($payload)));
    if (is_wp_error($result)) {
        // A timeout may occur AFTER FCM accepts a message. Never retry silently.
        return new WP_Error('send_uncertain', 'نتيجة الإرسال غير مؤكدة. لا تعاود الإرسال قبل مراجعتها لتجنب التكرار.');
    }
    $accepted = json_decode(wp_remote_retrieve_body($result), true);
    if (wp_remote_retrieve_response_code($result) !== 200 || !is_array($accepted) || empty($accepted['name'])) {
        return new WP_Error('send_rejected', 'لم يؤكد Firebase قبول الرسالة. راجع إعداد المشروع.');
    }
    return true; // Accepted by FCM, not proof of delivery to every device.
}

add_action('admin_post_kanz_send_notification', function () {
    if (!current_user_can('manage_options')) { wp_die('غير مصرح', '', array('response' => 403)); }
    check_admin_referer('kanz_send_notification');
    if (empty($_POST['confirm_broadcast'])) { wp_die('راجع الجمهور وأكد الإرسال أولاً.'); }
    $title = isset($_POST['notification_title']) ? wp_unslash($_POST['notification_title']) : '';
    $body = isset($_POST['notification_body']) ? wp_unslash($_POST['notification_body']) : '';
    $type = isset($_POST['destination_type']) ? wp_unslash($_POST['destination_type']) : 'none';
    $field = $type === 'category' ? 'destination_category' : ($type === 'product' ? 'destination_product' : 'destination_url');
    $value = isset($_POST[$field]) ? wp_unslash($_POST[$field]) : '';
    $destination = kanz_destination_data($type, $value);
    if (is_wp_error($destination)) { wp_die(esc_html($destination->get_error_message())); }
    $payload = kanz_notification_payload($title, $body, $destination);
    if (is_wp_error($payload)) { wp_die(esc_html($payload->get_error_message())); }
    $credentials = kanz_notification_credentials();
    if (is_wp_error($credentials)) { wp_die(esc_html($credentials->get_error_message())); }
    $request_id = isset($_POST['request_id']) ? wp_unslash($_POST['request_id']) : '';
    if (!is_string($request_id) || !preg_match('/^[a-f0-9-]{36}$/i', $request_id)) { wp_die('معرف الإرسال غير صالح.'); }
    if (!add_option('kanz_notification_lock', time(), '', false)) { wp_die('هناك إرسال جارٍ. لا تكرر الرسالة.'); }
    $history = get_option('kanz_notification_history', array());
    foreach ($history as $entry) {
        if ($entry['id'] === $request_id || $entry['time'] > time() - 60) {
            delete_option('kanz_notification_lock'); wp_die('تمت معالجة الطلب أو جرت محاولة إرسال خلال الدقيقة الماضية. لا تكرر الرسالة.');
        }
    }
    // Record BEFORE sending. Killed processes do not silently resend on reload.
    $entry = array('id' => $request_id, 'time' => time(), 'status' => 'pending', 'title' => $title);
    array_unshift($history, $entry);
    $history = array_slice($history, 0, 50);
    if (!update_option('kanz_notification_history', $history, false)) {
        delete_option('kanz_notification_lock'); wp_die('تعذر تسجيل الإرسال. لم تُرسل الرسالة.');
    }
    $result = kanz_notification_send($payload);
    $history[0]['status'] = is_wp_error($result) ? $result->get_error_code() : 'accepted';
    update_option('kanz_notification_history', $history, false);
    delete_option('kanz_notification_lock');
    if (is_wp_error($result)) { wp_die(esc_html($result->get_error_message())); }
    wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&notification=accepted'));
    exit;
});

add_action('admin_post_kanz_save_fcm_key', function () {
    if (!current_user_can('manage_options')) { wp_die('غير مصرح', '', array('response' => 403)); }
    check_admin_referer('kanz_save_fcm_key');
    if (!empty($_POST['delete_fcm_key'])) {
        delete_option('kanz_fcm_service_account');
        wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&fcm_deleted=1'));
        exit;
    }
    $raw = isset($_POST['fcm_service_account_json']) ? wp_unslash($_POST['fcm_service_account_json']) : '';
    if (!is_string($raw) || strlen($raw) > 65536) { wp_die('الملف كبير جداً أو غير صالح.'); }
    $data = json_decode(trim($raw), true);
    if (!is_array($data) || empty($data['project_id']) || empty($data['client_email']) || empty($data['private_key']) ||
        !is_string($data['project_id']) || !is_string($data['client_email']) ||
        !preg_match('/^[a-z][a-z0-9-]{4,62}$/', $data['project_id']) ||
        !filter_var($data['client_email'], FILTER_VALIDATE_EMAIL) || !is_string($data['private_key'])) {
        wp_die('محتوى JSON غير صالح؛ تأكد من نسخ ملف مفتاح الخدمة الخاص بمشروع Firebase كاملاً.');
    }
    update_option('kanz_fcm_service_account', wp_json_encode($data), false);
    wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&fcm_saved=1'));
    exit;
});

function kanz_notification_page_section() {
    $credentials = kanz_notification_credentials();
    $ready = !is_wp_error($credentials);
    ?>
    <h2>إشعارات عامة</h2>
    <p>للعروض والأخبار العامة فقط. لا تكتب بيانات طلب أو هاتف أو أي بيانات عميل؛ الجمهور هو المشترك في all-notifications.</p>
    <?php if (isset($_GET['fcm_saved'])) { ?><div class="notice notice-success" style="padding:10px;margin:10px 0"><p style="margin:0;font-weight:bold">✔ تم حفظ وربط مفتاح Firebase بنجاح! الإشعارات مفعلة الآن.</p></div><?php } ?>
    <?php if (isset($_GET['fcm_deleted'])) { ?><div class="notice notice-warning" style="padding:10px;margin:10px 0"><p style="margin:0">تم حذف مفتاح Firebase المربوط.</p></div><?php } ?>
    <?php if ($ready) { ?>
      <div style="background:#e7f5ea;border:1px solid #46b450;border-radius:6px;padding:10px 14px;margin:12px 0">
        <p style="margin:0;font-weight:bold;color:#1d6f2b">✔ خدمة Firebase مربوطة بنجاح بمشروع: <code><?php echo esc_html($credentials['project_id']); ?></code> (<?php echo esc_html($credentials['client_email']); ?>)</p>
      </div>
      <form action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post" style="margin-bottom:14px">
        <input type="hidden" name="action" value="kanz_save_fcm_key">
        <input type="hidden" name="delete_fcm_key" value="1">
        <?php wp_nonce_field('kanz_save_fcm_key'); ?>
        <button type="submit" class="button" onclick="return confirm('هل أنت متأكد من حذف مفتاح Firebase المربوط؟');">إلغاء ربط / حذف مفتاح Firebase</button>
      </form>
    <?php } else { ?>
      <div style="background:#fff8e5;border:1px solid #f0b849;border-radius:6px;padding:12px 16px;margin:14px 0">
        <h3 style="margin-top:0">ربط خدمة إشعارات Firebase من اللوحة مباشرة (دون الحاجة لـ cPanel أو FTP)</h3>
        <p>1. من Firebase Console افتح مشروع <code>kanz-alsahra</code> ثم توجه إلى <strong>Project settings &gt; Service accounts</strong> واضغط <strong>Generate new private key</strong>.</p>
        <p>2. افتح ملف JSON الذي تم تنزيله في المفكرة، وانسخ محتواه والصقه في الحقل التالي (أو اختر الملف مباشرة):</p>
        <form action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post">
          <input type="hidden" name="action" value="kanz_save_fcm_key">
          <?php wp_nonce_field('kanz_save_fcm_key'); ?>
          <p><input type="file" accept=".json,application/json" onchange="var r=new FileReader();r.onload=function(e){document.getElementById('kanz-fcm-json-input').value=e.target.result;};r.readAsText(this.files[0]);"> <small>(اختيار ملف JSON تلقائياً)</small></p>
          <p><textarea id="kanz-fcm-json-input" name="fcm_service_account_json" required rows="5" style="width:100%;font-family:monospace" placeholder='{"type": "service_account", "project_id": "kanz-alsahra", ...}'></textarea></p>
          <button type="submit" class="button button-primary">حفظ وربط مفتاح Firebase</button>
        </form>
      </div>
    <?php } ?>
    <?php if (isset($_GET['notification']) && $_GET['notification'] === 'accepted') { ?><p>قبل Firebase الرسالة. هذا لا يضمن وصولها لكل جهاز.</p><?php } ?>
    <form action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post">
      <input type="hidden" name="action" value="kanz_send_notification">
      <input type="hidden" name="request_id" value="<?php echo esc_attr(wp_generate_uuid4()); ?>">
      <?php wp_nonce_field('kanz_send_notification'); ?>
      <p><label>العنوان <input required name="notification_title" maxlength="80" style="width:100%;max-width:400px"></label></p>
      <p><label>النص<br><textarea required name="notification_body" maxlength="800" rows="4" style="width:100%;max-width:550px"></textarea></label></p>
      <p><label>وجهة الإشعار <select name="destination_type" id="kanz-notif-dest-type">
        <?php foreach (array('none' => 'فتح التطبيق فقط', 'category' => 'تصنيف', 'product' => 'منتج', 'home' => 'الرئيسية', 'category_page' => 'صفحة التصنيفات', 'cart' => 'السلة', 'profile' => 'الحساب', 'url' => 'رابط HTTPS خارجي') as $key => $label) { ?><option value="<?php echo esc_attr($key); ?>"><?php echo esc_html($label); ?></option><?php } ?>
      </select></label></p>
      <p id="kanz-notif-row-category" style="display:none"><label>التصنيف
        <input type="search" placeholder="🔍 تصفية التصنيفات بالاسم..." oninput="kanzFilterSelect(this, 'kanz-notif-select-category')" style="display:block;margin:4px 0;width:100%;max-width:320px;padding:4px 8px;border:1px solid #ccc;border-radius:4px">
        <select name="destination_category" id="kanz-notif-select-category"><option value="">اختر التصنيف</option>
        <?php foreach (kanz_destination_options('category') as $option) {
          $prefix = empty($option['parent']) ? '🟢 ' : '↳ ';
        ?><option value="<?php echo esc_attr($option['id']); ?>"><?php echo esc_html($prefix . $option['name'] . ' — #' . $option['id']); ?></option><?php } ?>
        </select></label></p>
      <p id="kanz-notif-row-product" style="display:none"><label>المنتج
        <input type="search" placeholder="🔍 تصفية المنتجات بالاسم..." oninput="kanzFilterSelect(this, 'kanz-notif-select-product')" style="display:block;margin:4px 0;width:100%;max-width:320px;padding:4px 8px;border:1px solid #ccc;border-radius:4px">
        <select name="destination_product" id="kanz-notif-select-product"><option value="">اختر المنتج</option>
        <?php foreach (kanz_destination_options('product') as $option) { ?><option value="<?php echo esc_attr($option['id']); ?>"><?php echo esc_html($option['name'] . ' — #' . $option['id']); ?></option><?php } ?>
        </select></label></p>
      <p id="kanz-notif-row-url" style="display:none"><label>رابط خارجي <input name="destination_url" type="url" maxlength="2048" placeholder="https://..." style="width:100%;max-width:400px"></label></p>
      <script>
      function kanzFilterSelect(input, selectId) {
        var sel = document.getElementById(selectId);
        if (!sel) return;
        var term = input.value.trim().toLowerCase();
        for (var i = 0; i < sel.options.length; i++) {
          var opt = sel.options[i];
          if (!opt.value || !term) {
            opt.style.display = '';
          } else {
            opt.style.display = opt.text.toLowerCase().indexOf(term) !== -1 ? '' : 'none';
          }
        }
      }
      (function(){
        function updateNotifDest(){
          var sel = document.getElementById('kanz-notif-dest-type');
          if(!sel) return;
          var cat = document.getElementById('kanz-notif-row-category');
          var prod = document.getElementById('kanz-notif-row-product');
          var url = document.getElementById('kanz-notif-row-url');
          if(cat) cat.style.display = sel.value === 'category' ? 'block' : 'none';
          if(prod) prod.style.display = sel.value === 'product' ? 'block' : 'none';
          if(url) url.style.display = sel.value === 'url' ? 'block' : 'none';
        }
        var s = document.getElementById('kanz-notif-dest-type');
        if(s){ s.addEventListener('change', updateNotifDest); updateNotifDest(); }
      })();
      </script>
      <p>اختيار الوجهة لا يفعّل الإرسال. يلزم تحديث التطبيق لدعم الوجهات الجديدة. لا تستخدم الروابط لإجراءات حذف أو شراء أو بيانات خاصة.</p>
      <p><label><input required type="checkbox" name="confirm_broadcast" value="1">راجعت النص وأوافق على إرساله كإشعار عام، دون بيانات خاصة.</label></p>
      <button type="submit" class="button button-primary" <?php disabled(!$ready); ?>>إرسال إشعار عام</button>
    </form>
    <h3>سجل محاولات الإرسال</h3>
    <?php foreach (get_option('kanz_notification_history', array()) as $entry) { ?>
      <p><?php echo esc_html(gmdate('c', $entry['time']) . ' — ' . $entry['title'] . ' — ' . $entry['status']); ?></p>
    <?php } ?>
    <?php
}
