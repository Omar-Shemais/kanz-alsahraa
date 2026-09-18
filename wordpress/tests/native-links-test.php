<?php
define('ABSPATH', __DIR__);
function add_action(...$unused) {}
require __DIR__ . '/../snippets/kanz-native-links-snippet.php';
$certificate = implode(':', array_fill(0, 32, 'AB'));
$checks = array(
    kanz_native_association('/.well-known/assetlinks.json', array()) === null,
    kanz_native_association('/.well-known/assetlinks.json', array('invalid')) === null,
    kanz_native_association('/other', array($certificate)) === null,
    kanz_native_association('/.well-known/assetlinks.json', array($certificate))
        [0]['target']['package_name'] === 'com.khtwah.kanzalsahra',
    count(kanz_native_association('/.well-known/assetlinks.json', array($certificate, $certificate))
        [0]['target']['sha256_cert_fingerprints']) === 1,
    kanz_native_association('/.well-known/apple-app-site-association', array())
        ['applinks']['details'][0]['appID'] === 'T5T28K7SSZ.com.khtwah.kanzalsahra',
);
foreach ($checks as $index => $passed) {
    if (!$passed) throw new Exception('Association check failed: ' . $index);
}
echo count($checks) . " native association checks passed; not a live WordPress test.\n";
