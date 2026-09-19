import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/user_model.dart';
import 'setting_card_widget.dart';
import 'setting_item_widget.dart';

class SettingNotificationWidget extends StatefulWidget {
  const SettingNotificationWidget({
    super.key,
    this.cardStyle,
  });

  final SettingItemStyle? cardStyle;

  @override
  State<SettingNotificationWidget> createState() =>
      _SettingNotificationWidgetState();
}

class _SettingNotificationWidgetState extends State<SettingNotificationWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final model = Provider.of<NotificationModel>(context, listen: false);
    model.checkGranted().then((_) {
      if (!mounted) return;
      final cookie =
          Provider.of<UserModel>(context, listen: false).user?.cookie;
      model.updateNotificationStatus(cookie);
    });
  }

  Future _onChanged(BuildContext context, NotificationModel model,
      bool enableNotification) async {
    if (enableNotification) {
      final granted = await model.enableNotification();
      if (!granted && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تفعيل الإشعارات'),
            content: const Text(
              'الإشعارات غير مسموحة لهذا التطبيق. افتح إعدادات iPhone وفعّل الإشعارات، ثم ارجع إلى التطبيق.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await openAppSettings();
                },
                child: const Text('فتح الإعدادات'),
              ),
            ],
          ),
        );
        return;
      }
    } else {
      model.disableNotification();
    }
    var cookie = Provider.of<UserModel>(context, listen: false).user?.cookie;
    model.updateNotificationStatus(cookie);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(
      S.of(context).getNotification,
      style: const TextStyle(fontSize: 16),
    );

    final icon = Icon(
      CupertinoIcons.bell,
      color: Theme.of(context).colorScheme.secondary,
      size: 24,
    );

    final messageWidget = SettingItemWidget(
      cardStyle: widget.cardStyle,
      icon: CupertinoIcons.list_bullet,
      title: S.of(context).listMessages,
      onTap: () => Navigator.of(context).pushNamed(RouteList.notify),
    );

    return Consumer<NotificationModel>(builder: (context, model, child) {
      switch (widget.cardStyle) {
        case SettingItemStyle.flatShadow:
          return Column(
            children: [
              SettingCardWidget(
                style: SettingItemStyle.flatShadow,
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    child: icon,
                  ),
                  value: model.enable,
                  onChanged: (value) => _onChanged(context, model, value),
                  title: title,
                ),
              ),
              if (model.enable) messageWidget,
            ],
          );
        case SettingItemStyle.flat:
          return Column(
            children: [
              SettingCardWidget(
                style: SettingItemStyle.flat,
                child: SwitchListTile(
                  secondary: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: icon,
                  ),
                  value: model.enable,
                  onChanged: (value) => _onChanged(context, model, value),
                  title: title,
                ),
              ),
              if (model.enable) messageWidget,
            ],
          );
        case SettingItemStyle.flatListTile:
          return Column(
            children: [
              SettingCardWidget(
                style: SettingItemStyle.flatListTile,
                child: SwitchListTile(
                  secondary: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: icon,
                  ),
                  value: model.enable,
                  onChanged: (value) => _onChanged(context, model, value),
                  title: title,
                ),
              ),
              if (model.enable) messageWidget,
            ],
          );
        default:
          return Column(
            children: [
              SettingCardWidget(
                style: SettingItemStyle.listTile,
                child: SwitchListTile(
                  secondary: icon,
                  value: model.enable,
                  onChanged: (value) => _onChanged(context, model, value),
                  title: title,
                ),
              ),
              const Divider(color: Colors.black12, height: 1.0, indent: 75),
              if (model.enable) messageWidget,
            ],
          );
      }
    });
  }
}
