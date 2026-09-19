<?php
/**
 * Plugin Name: Kanz App Control
 * Description: Arabic admin editor and versioned public home configuration for Kanz.
 * Version: 0.2.0
 */
defined('ABSPATH') || exit;
require_once __DIR__ . '/notifications.php';

function kanz_config_validate($data) {
    if (!is_array($data) || !isset($data['Setting'], $data['TabBar'], $data['HorizonLayout']) ||
        !is_array($data['Setting']) || !is_array($data['TabBar']) || !$data['TabBar'] ||
        !is_array($data['HorizonLayout'])) {
        return new WP_Error('invalid_config', 'يلزم وجود Setting وTabBar وHorizonLayout صحيحة.');
    }
    foreach ($data['TabBar'] as $tab) {
        if (!is_array($tab) || empty($tab['layout']) || empty($tab['icon']) || !is_string($tab['layout']) || !is_string($tab['icon'])) {
            return new WP_Error('invalid_tabs', 'إعدادات شريط التنقل غير صحيحة.');
        }
        if (isset($tab['filterCategories'])) {
            if (!is_array($tab['filterCategories']) || !$tab['filterCategories']) {
                return new WP_Error('invalid_filter_categories', 'اختر تصنيفاً واحداً على الأقل لفلتر المنتجات.');
            }
            foreach ($tab['filterCategories'] as $category_id) {
                if (!preg_match('/^\d+$/', (string) $category_id)) {
                    return new WP_Error('invalid_filter_categories', 'قائمة تصنيفات الفلتر غير صحيحة.');
                }
            }
        }
    }
    foreach ($data['HorizonLayout'] as $section) {
        if (!is_array($section) || empty($section['layout']) || !is_string($section['layout'])) {
            return new WP_Error('invalid_sections', 'كل قسم يحتاج نوع عرض layout.');
        }
        if (isset($section['items']) && !is_array($section['items'])) {
            return new WP_Error('invalid_items', 'عناصر القسم يجب أن تكون قائمة.');
        }
    }
    if (isset($data['Setting']['DefaultTheme']) && !in_array($data['Setting']['DefaultTheme'], array('dark', 'light'), true)) {
        return new WP_Error('invalid_theme', 'المظهر الافتراضي يجب أن يكون داكناً أو فاتحاً.');
    }
    if (isset($data['KanzControl'])) {
        if (!is_array($data['KanzControl']) || !isset($data['KanzControl']['updates']) || !is_array($data['KanzControl']['updates'])) {
            return new WP_Error('invalid_updates', 'إعدادات التحديث غير صحيحة.');
        }
        foreach (array('android', 'ios') as $platform) {
            if (!isset($data['KanzControl']['updates'][$platform])) { continue; }
            $update = $data['KanzControl']['updates'][$platform];
            if (!is_array($update) || !isset($update['enabled']) || !is_bool($update['enabled']) ||
                !isset($update['minimumBuild']) || !is_int($update['minimumBuild']) || $update['minimumBuild'] < 0 ||
                $update['minimumBuild'] > 2147483647 || ($update['enabled'] && $update['minimumBuild'] < 1)) {
                return new WP_Error('invalid_updates', 'اختر حد إصدار صحيحاً؛ لا تفعّل الإجبار قبل نشر الإصدار فعلياً في المتجر.');
            }
        }
    }
    $walk = function ($value) use (&$walk) {
        if (is_array($value)) {
            foreach ($value as $key => $child) {
                if (preg_match('/^(consumer_?key|consumer_?secret|private_?key|service_account|password|authorization|cookie)$/i', (string) $key)) {
                    return false;
                }
                if (!$walk($child)) { return false; }
            }
        } elseif (is_string($value) && preg_match('/<\s*script\b|javascript\s*:|BEGIN (?:RSA )?PRIVATE KEY/i', $value)) {
            return false;
        }
        return true;
    };
    return $walk($data) ? true : new WP_Error('unsafe_config', 'لا تنشر أسراراً أو أكواداً تنفيذية في ملف التطبيق العام.');
}

add_action('admin_menu', function () {
    add_menu_page('إدارة تطبيق كنز', 'تطبيق كنز', 'manage_options', 'kanz-app-control', 'kanz_config_page', 'dashicons-smartphone');
});

add_action('admin_enqueue_scripts', function ($hook) {
    if ($hook !== 'toplevel_page_kanz-app-control') { return; }
    wp_enqueue_media();
    wp_enqueue_script('kanz-app-control', plugins_url('admin.js', __FILE__), array(), '0.2.0', true);
    $categories = array();
    if (taxonomy_exists('product_cat')) {
        $terms = get_terms(array('taxonomy' => 'product_cat', 'hide_empty' => false));
        if (!is_wp_error($terms)) {
            foreach ($terms as $term) {
                $categories[] = array(
                    'id' => (string) $term->term_id,
                    'name' => $term->name,
                    'parent' => (int) $term->parent,
                    'count' => (int) $term->count,
                    'isUncategorized' => (int) get_option('default_product_cat') === (int) $term->term_id,
                );
            }
        }
    }
    wp_localize_script('kanz-app-control', 'kanzAdmin', array('categories' => $categories, 'products' => kanz_destination_options('product')));
});

add_action('admin_post_kanz_save_config', function () {
    if (!current_user_can('manage_options')) { wp_die('غير مصرح', '', array('response' => 403)); }
    check_admin_referer('kanz_save_config');
    $raw = isset($_POST['config_json']) ? wp_unslash($_POST['config_json']) : '';
    if (!is_string($raw) || strlen($raw) > 1048576) { wp_die('الملف كبير أو غير صالح.'); }
    $data = json_decode($raw, true, 64);
    if (json_last_error() !== JSON_ERROR_NONE || !is_array($data)) { wp_die('JSON غير صالح. لم تتغير النسخة المنشورة.'); }
    $object = json_decode($raw, false, 64);
    if (!is_object($object) || !isset($object->Setting) || !is_object($object->Setting) ||
        !isset($object->TabBar, $object->HorizonLayout) || !is_array($object->TabBar) || !is_array($object->HorizonLayout)) {
        wp_die('نوع حقول JSON غير صحيح. Setting يجب أن يكون كائناً والأقسام والتنقل قوائم.');
    }
    $valid = kanz_config_validate($data);
    if (is_wp_error($valid)) { wp_die(esc_html($valid->get_error_message())); }
    foreach (array('android', 'ios') as $platform) {
        if (!empty($data['KanzControl']['updates'][$platform]['enabled']) && empty($_POST['confirm_updates'])) {
            wp_die('أكد توفر الإصدار المطلوب في المتجر قبل نشر إعدادات التحديث الإجباري.');
        }
    }
    // Unique option insertion provides a database-level publication lock.
    // A stale lock is intentionally NOT stolen during a running publication.
    if (!add_option('kanz_app_config_publish_lock', gmdate('c'), '', false)) {
        wp_die('هناك عملية نشر أخرى. انتظر ثم أعد المحاولة؛ إذا استمر التنبيه اطلب مراجعة قفل النشر من المسؤول.');
    }
    // Optimistic locking prevents silently overwriting another administrator.
    $current = get_option('kanz_app_config_record', array());
    $revision = isset($current['revision']) ? $current['revision'] : '';
    if (!isset($_POST['base_revision']) || !hash_equals((string) $revision, (string) wp_unslash($_POST['base_revision']))) {
        delete_option('kanz_app_config_publish_lock');
        wp_die('تغيرت النسخة منذ فتح الصفحة. انسخ تعديلك ثم أعد تحميل الصفحة.');
    }
    // Preserve {} versus [] exactly, including empty map-valued components.
    $record = array('revision' => wp_generate_uuid4(), 'saved_at' => gmdate('c'), 'user_id' => get_current_user_id(), 'config' => $object);
    $history = get_option('kanz_app_config_history', array());
    if (!empty($current)) { array_unshift($history, $current); }
    // Snapshot is written before replacing the publication.
    $next_history = array_slice($history, 0, 20);
    if ($history && !update_option('kanz_app_config_history', $next_history, false)) {
        delete_option('kanz_app_config_publish_lock');
        wp_die('تعذر حفظ النسخة السابقة. لم يتم النشر.');
    }
    $saved = update_option('kanz_app_config_record', $record, false);
    if ($saved) {
        $uploads = wp_upload_dir();
        if (empty($uploads['error']) && !empty($uploads['basedir'])) {
            $static_file = rtrim($uploads['basedir'], '/\\') . '/flutter_config_files/config_ar.json';
            if (file_exists($static_file) && is_writable($static_file)) {
                @file_put_contents($static_file, wp_json_encode($object, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
            }
        }
    }
    delete_option('kanz_app_config_publish_lock');
    if (!$saved) { wp_die('تعذر حفظ الإعدادات. راجع قاعدة البيانات.'); }
    wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&saved=1'));
    exit;
});

add_action('rest_api_init', function () {
    register_rest_route('kanz/v1', '/config/(?P<locale>[a-zA-Z_-]+)', array(
        'methods' => 'GET', 'permission_callback' => '__return_true',
        'callback' => function () {
            $record = get_option('kanz_app_config_record', array());
            if (empty($record['config'])) { return new WP_Error('not_published', 'Configuration is not published.', array('status' => 404)); }
            // Never expose administrator identity, history or notification secrets.
            $response = new WP_REST_Response($record['config']);
            $response->header('Cache-Control', 'no-store');
            return $response;
        },
    ));
});

function kanz_config_page() {
    if (!current_user_can('manage_options')) { return; }
    $record = get_option('kanz_app_config_record', array());
    $json = empty($record['config']) ? '' : wp_json_encode($record['config'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    ?>
    <div class="wrap" dir="rtl">
      <h1>إدارة تطبيق كنز الصحراء</h1>
      <?php if (isset($_GET['saved'])) { ?><div class="notice notice-success"><p>تم حفظ النسخة المنشورة.</p></div><?php } ?>
      <p>استورد config_ar.json أولاً. لن يتغير الملف القديم المرفوع في الوسائط؛ هذه الإضافة تنشر نسخة مستقلة يمكن الرجوع عنها.</p>
      <p>رابط إعدادات التطبيق الجديد: <code dir="ltr"><?php echo esc_html(rest_url('kanz/v1/config/ar')); ?></code></p>
      <p><strong>لن تظهر تعديلات هذه اللوحة حتى ربط التطبيق برابطها بعد الاختبار وبناء نسخة تدعم لوحة التحكم.</strong></p>
      <input id="kanz-import" type="file" accept=".json,application/json">
      <p id="kanz-error" role="alert" style="color:#b32d2e"></p>
      <form id="kanz-form" action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post">
        <input type="hidden" name="action" value="kanz_save_config">
        <input type="hidden" name="base_revision" value="<?php echo esc_attr(isset($record['revision']) ? $record['revision'] : ''); ?>">
        <?php wp_nonce_field('kanz_save_config'); ?>
        <h2>أقسام الصفحة الرئيسية</h2>
        <p>رتّب الأقسام، وعدّل أسماء الأقسام وتصنيفاتها، وأضف صور البانرات من مكتبة الوسائط.</p>
        <div id="kanz-sections"></div>
        <button type="button" id="kanz-add-banner" class="button">إضافة بانر</button>
        <button type="button" id="kanz-add-category" class="button">إضافة قسم منتجات</button>
        <h2>المظهر الافتراضي للتطبيق</h2>
        <div id="kanz-appearance"></div>
        <h2>ترتيب التصنيفات في صفحة التصنيفات</h2>
        <p>الأسهم تغيّر ترتيب التصنيفات. تُحفظ القائمة كاملة عند تغيير الترتيب، دون حذف التصنيفات الأخرى. التصنيفات الجديدة لاحقاً تحتاج إعادة حفظ الترتيب.</p>
        <div id="kanz-category-order"></div>
        <h2>تصنيفات فلتر المنتجات</h2>
        <div id="kanz-filter-category-order"></div>
        <h2>التحديث الإجباري</h2>
        <p>الحد هو رقم البناء، وليس الاسم مثل 1.10.2. لا تفعّله قبل توفر إصدار يمكن للعملاء تنزيله. يطبّق التطبيق سياسة الإعدادات المحفوظة عند فتحه من جديد؛ لا يقطع عملية دفع جارية إذا تغيرت الإعدادات أثناء الاستخدام.</p>
        <div id="kanz-updates"></div>
        <p><label><input id="kanz-confirm-updates" type="checkbox" name="confirm_updates" value="1">إذا كان التحديث الإجباري مفعلاً، أؤكد أن الإصدار المطلوب متاح للتنزيل فعلياً في المتجر.</label></p>
        <button type="button" id="kanz-export" class="button">تحميل JSON للنسخة الحالية</button>
        <details><summary>تعديل جميع حقول الإعدادات من اللوحة</summary>
          <p>يشمل الألوان والخطوط وبقية حقول الملف، مع الحفاظ على نوع كل قيمة. الحقول الجديدة لا تضيف وظائف غير مدعومة في التطبيق.</p>
          <div id="kanz-all-fields"></div>
        </details>
        <details style="margin-top:20px"><summary>الإعدادات الكاملة — تحرير JSON</summary>
          <p>يحافظ المحرر على الحقول الإضافية. اضغط «تطبيق النص على المحرر» قبل تعديل الأقسام بصرياً.</p>
          <textarea id="kanz-json" name="config_json" dir="ltr" spellcheck="false" style="width:100%;min-height:400px"><?php echo esc_textarea($json); ?></textarea>
          <button id="kanz-apply" type="button" class="button">تطبيق النص على المحرر</button>
        </details>
        <?php submit_button('نشر إعدادات التطبيق'); ?>
      </form>
      <h2>النسخ السابقة</h2>
      <p>يمكن تحميل نسخة سابقة واستيرادها للمراجعة، ثم نشرها. لا يوجد استرجاع تلقائي دون مراجعة.</p>
      <?php foreach (get_option('kanz_app_config_history', array()) as $past) { ?>
        <details><summary><?php echo esc_html($past['saved_at']); ?></summary><textarea readonly dir="ltr" style="width:100%;height:150px"><?php echo esc_textarea(wp_json_encode($past['config'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)); ?></textarea></details>
      <?php } ?>
      <?php kanz_notification_page_section(); ?>
    </div>
    <?php
}
