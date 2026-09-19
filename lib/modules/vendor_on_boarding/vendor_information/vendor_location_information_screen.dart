import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../widgets/common/edit_product_info_widget.dart';
import '../model/vendor_on_boarding_model.dart';
import '../widgets/navigation_buttons.dart';

/// Vendor location is entered as text. This keeps onboarding functional
/// without shipping the unused native Maps SDK.
class VendorLocationInformation extends StatefulWidget {
  const VendorLocationInformation({super.key, required this.onCallBack});

  final Function(bool isPrev) onCallBack;

  @override
  State<VendorLocationInformation> createState() =>
      _VendorLocationInformationState();
}

class _VendorLocationInformationState extends State<VendorLocationInformation> {
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _locationController.text =
            context.read<VendorOnBoardingModel>().location;
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    context.read<VendorOnBoardingModel>().updateLocation({
      'location': _locationController.text.trim(),
      'lat': null,
      'long': null,
    });
    widget.onCallBack(false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(S.of(context).location),
                    const SizedBox(height: 12),
                    EditProductInfoWidget(
                      controller: _locationController,
                      label: S.of(context).location,
                    ),
                  ],
                ),
              ),
            ),
            NavigationButtons(
              onBack: () => widget.onCallBack(true),
              onNext: _onUpdate,
            ),
          ],
        ),
      );
}
