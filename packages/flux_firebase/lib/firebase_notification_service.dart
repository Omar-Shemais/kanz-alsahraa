import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:fstore/common/constants.dart';
import 'package:fstore/models/entities/index.dart';
import 'package:fstore/services/notification/notification_service.dart';

const _topicAll = 'all-notifications';

class FirebaseNotificationService extends NotificationService {
  final _instance = FirebaseMessaging.instance;

  StreamSubscription? _notificationSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  // @override
  // Future<bool> requestPermission() async {
  //   try {
  //     final result = await _instance.requestPermission();
  //     return result.alert == AppleNotificationSetting.enabled;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  @override
  Future<void> init({
    String? externalUserId,
    required NotificationDelegate notificationDelegate,
  }) async {
    if (isInitialized) {
      return;
    }
    setIsInitialized();
    delegate = notificationDelegate;
    unawaited(_initializeRegistration());
    _tokenRefreshSubscription ??= _instance.onTokenRefresh.listen(
      (_) => printLog('[FirebaseCloudMessaging] registration token refreshed'),
      onError: (_) =>
          printLog('[FirebaseCloudMessaging] token refresh unavailable'),
    );

    unawaited(_instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    ));

    unawaited(_instance.getInitialMessage().then((initMessage) {
      if (initMessage != null) {
        delegate.onMessageOpenedApp(FStoreNotificationItem(
          id: initMessage.messageId ?? '',
          title: initMessage.notification?.title ?? '',
          body: initMessage.notification?.body ?? '',
          additionalData: initMessage.data,
          date: DateTime.now(),
        ));
      }
    }).catchError((e) {
      printLog('[FirebaseCloudMessaging] getInitialMessage error: $e');
    }));

    _notificationSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        final notification = message.notification;
        // final android = message.notification?.android;
        // if (notification != null && android != null && isAndroid) {
        //   flutterLocalNotificationsPlugin.show(
        //     notification.hashCode,
        //     notification.title,
        //     notification.body,
        //     NotificationDetails(
        //       android: AndroidNotificationDetails(
        //         channel.id,
        //         channel.name,
        //         channelDescription: channel.description,
        //         icon: android.smallIcon,
        //         // other properties...
        //       ),
        //     ),
        //     // payload: 'Notification'
        //   );
        // }

        if (notification != null) {
          delegate.onMessage(FStoreNotificationItem(
            id: message.messageId ?? '',
            title: notification.title ?? '',
            body: notification.body ?? '',
            additionalData: message.data,
            date: DateTime.now(),
          ));
        }
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // printLog('Notification OpenedApp triggered');
      delegate.onMessageOpenedApp(FStoreNotificationItem(
        id: message.messageId ?? '',
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        additionalData: message.data,
        date: DateTime.now(),
      ));
    });
  }

  Future<void> _initializeRegistration() async {
    try {
      // On Apple platforms FCM registration is not valid until APNs has issued
      // its token. Retry briefly without delaying application startup.
      if (isIos) {
        String? apnsToken;
        for (var attempt = 0; attempt < 10 && apnsToken == null; attempt++) {
          apnsToken = await _instance.getAPNSToken();
          if (apnsToken == null) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
        if (apnsToken == null) {
          printLog('[FirebaseCloudMessaging] APNs token is not ready');
          return;
        }
      }

      final token =
          await _instance.getToken().timeout(const Duration(seconds: 8));
      if (token == null || token.isEmpty) return;
      await _instance
          .subscribeToTopic(_topicAll)
          .timeout(const Duration(seconds: 8));
      printLog('[FirebaseCloudMessaging] registration ready');
    } catch (_) {
      // Never log FCM/APNs tokens or raw provider responses.
      printLog('[FirebaseCloudMessaging] registration unavailable');
    }
  }

  @override
  void disableNotification() {
    _instance.unsubscribeFromTopic(_topicAll);
    _instance.setForegroundNotificationPresentationOptions(
      alert: false, // Required to display a heads up notification
      badge: false,
      sound: false,
    );
    if (_notificationSubscription != null) {
      _notificationSubscription!.pause();
    }
  }

  @override
  void enableNotification() {
    _instance.subscribeToTopic(_topicAll);
    _instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
    if (_notificationSubscription != null) {
      _notificationSubscription!.resume();
    }
  }

  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  static String formatCustomerTopic(String userId) =>
      'customer_${userId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')}';

  @override
  void setExternalId(String? userId) {
    if (_currentUserId != null && _currentUserId != userId) {
      _instance.unsubscribeFromTopic(formatCustomerTopic(_currentUserId!));
      _currentUserId = null;
    }
    if (userId != null && userId.trim().isNotEmpty) {
      _currentUserId = userId.trim();
      // Public topics do not authenticate customer ownership. Private alerts
      // require a server-verified device-token registration instead.
      _instance.unsubscribeFromTopic(formatCustomerTopic(_currentUserId!));
    }
  }

  @override
  void removeExternalId() {
    if (_currentUserId != null) {
      _instance.unsubscribeFromTopic(formatCustomerTopic(_currentUserId!));
      _currentUserId = null;
    }
  }
}
