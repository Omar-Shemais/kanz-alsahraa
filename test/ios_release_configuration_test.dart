import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

Map<String, XmlElement> plist(String path) {
  final document = XmlDocument.parse(File(path).readAsStringSync());
  final children =
      document.rootElement.getElement('dict')!.childElements.toList();
  return {
    for (var i = 0; i < children.length; i += 2)
      children[i].innerText: children[i + 1]
  };
}

void main() {
  test('Firebase iOS files match the production application', () {
    for (final path in [
      'configs/GoogleService-Info.plist',
      'ios/GoogleService-Info.plist'
    ]) {
      final config = plist(path);
      expect(config['PROJECT_ID']!.innerText, 'kanz-alsahra');
      expect(config['BUNDLE_ID']!.innerText, 'com.khtwah.kanzalsahra');
      expect(config['GCM_SENDER_ID']!.innerText, '132198990660');
    }
    expect(File('configs/GoogleService-Info.plist').readAsStringSync(),
        File('ios/GoogleService-Info.plist').readAsStringSync());
  });
  test('Arabic metadata, push and HTTPS are configured', () {
    final info = plist('ios/Runner/Info.plist');
    expect(info['CFBundleDevelopmentRegion']!.innerText, 'ar');
    expect(info['CFBundleLocalizations']!.childElements.map((e) => e.innerText),
        ['ar']);
    expect(info['FirebaseAppDelegateProxyEnabled']!.name.local, 'true');
    expect(info, isNot(contains('FacebookAutoInitEnabled')));
    expect(info, isNot(contains('FacebookAutoLogAppEventsEnabled')));
    expect(
        info['UIBackgroundModes']!.innerText, contains('remote-notification'));
    for (final key in [
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSFaceIDUsageDescription',
    ]) {
      expect(info[key]!.innerText, isNotEmpty);
    }
    for (final key in [
      'NSLocationWhenInUseUsageDescription',
      'NSLocationAlwaysAndWhenInUseUsageDescription',
      'NSUserTrackingUsageDescription',
    ]) {
      expect(info, isNot(contains(key)));
    }
    expect(info, isNot(contains('NSMicrophoneUsageDescription')));
    expect(info, isNot(contains('NSSpeechRecognitionUsageDescription')));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('speech_to_text:')),
      reason:
          'Unused speech APIs trigger unnecessary iOS privacy declarations.',
    );
    final dependencies = File('pubspec.yaml').readAsStringSync();
    expect(dependencies, isNot(contains('app_tracking_transparency:')));
    expect(dependencies, isNot(contains('\n  location:')));
    expect(dependencies, isNot(contains('google_mobile_ads:')));
    expect(dependencies, isNot(contains('google_maps_flutter:')));
    expect(dependencies, isNot(contains('flutter_facebook_auth:')));
    expect(dependencies, isNot(contains('facebook_app_events:')));
    for (final strings in Directory('ios/Runner')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('InfoPlist.strings'))) {
      final contents = strings.readAsStringSync();
      for (final key in [
        'NSLocationWhenInUseUsageDescription',
        'NSLocationAlwaysAndWhenInUseUsageDescription',
        'NSLocationAlwaysUsageDescription',
        'NSUserTrackingUsageDescription',
        'NSMicrophoneUsageDescription',
      ]) {
        expect(contents, isNot(contains(key)), reason: strings.path);
      }
    }
    expect(info['NSAppTransportSecurity']!.innerXml, isNot(contains('<true')));
    final entitlements = plist('ios/Runner/Runner.entitlements');
    expect(entitlements['aps-environment']!.innerText, r'${iosApsEnvironment}');
    expect(entitlements['com.apple.developer.associated-domains']!.innerText,
        contains('applinks:'));
  });
  test('deployment targets and Xcode configuration are portable and consistent',
      () {
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final targets =
        RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);').allMatches(project);
    expect(targets, isNotEmpty);
    expect(targets.map((m) => m.group(1)).toSet(), {'15.0'});
    expect(
        plist('ios/Flutter/AppFrameworkInfo.plist')['MinimumOSVersion']!
            .innerText,
        '15.0');
    final podfile = File('ios/Podfile').readAsStringSync();
    expect(podfile, contains("platform :ios, '15.0'"));
    expect(podfile, contains("['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'"));
    expect(File('ios/Config.xcconfig').readAsStringSync().trim(),
        '#include "../configs/env.props"');
    final sharedEnvironment = File('configs/env.props').readAsLinesSync();
    expect(
      sharedEnvironment.where((line) => line.trimLeft().startsWith('#')),
      isEmpty,
      reason:
          'env.props is parsed by Xcode as an xcconfig; # comments become invalid preprocessor directives.',
    );
    expect(File('ios/Flutter/Release.xcconfig').readAsStringSync(),
        isNot(contains('profile.xcconfig')));
    final scheme = XmlDocument.parse(
        File('ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme')
            .readAsStringSync());
    expect(
        scheme
            .findAllElements('ActionContent')
            .first
            .getAttribute('scriptText'),
        contains('/pre-actions.sh'));
    expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
    expect(project, contains('FirebaseCrashlytics/run'));
  });
}
