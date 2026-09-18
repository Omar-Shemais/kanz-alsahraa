<?php
// Mechanical build: synchronize the Code Snippets export with its PHP source.
$directory = __DIR__ . '/snippets/';
$path = $directory . 'kanz-app-control.code-snippets.json';
$export = json_decode(file_get_contents($path), true);
$code = file_get_contents($directory . 'kanz-app-control-snippet.php');
if (!is_array($export) || !isset($export['snippets'][0]) || strpos($code, '<?php') !== 0) { throw new Exception('Invalid source/export.'); }
$export['snippets'][0]['code'] = preg_replace('/^<\?php\s*/', '', $code);
$export['snippets'][0]['active'] = false;
$export['snippets'][0]['scope'] = 'global';
$export['snippets'][0]['desc'] = 'لوحة عربية تقرأ وتحفظ config_ar.json في MStore، مع وجهات البانرات وترتيب التصنيفات واختبار إشعار لحساب واحد. مفتاح Firebase مشفر في قاعدة البيانات. اختبارات محلية فقط؛ يلزم اختبار آمن قبل اعتماد الإنتاج.';
if (file_put_contents($path, json_encode($export, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n") === false) { throw new Exception('Export build failed.'); }
echo "Code Snippets export synchronized; inactive by default.\n";
