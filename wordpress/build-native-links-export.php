<?php
// Mechanical export builder for the separately reviewed native-link snippet.
$code = file_get_contents(__DIR__ . '/snippets/kanz-native-links-snippet.php');
if (strpos($code, '<?php') !== 0) throw new Exception('Invalid PHP source.');
$export = array('generator' => 'Code Snippets', 'date_created' => '2026-09-18 00:00',
    'snippets' => array(array('name' => 'روابط تطبيق كنز — Android وiOS',
        'desc' => 'ملفات ربط روابط المتجر بالتطبيق. راجع شهادة Play App Signing قبل التفعيل، ثم تحقق من الرابطين العامين. لا يصلح روابط Firebase القديمة المتوقفة.',
        'code' => preg_replace('/^<\?php\s*/', '', $code), 'tags' => array('kanz', 'app-links'),
        'scope' => 'global', 'active' => false, 'priority' => 10)));
if (file_put_contents(__DIR__ . '/snippets/kanz-native-links.code-snippets.json',
    json_encode($export, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n") === false) throw new Exception('Export failed.');
echo "Native links export built; inactive by default.\n";
