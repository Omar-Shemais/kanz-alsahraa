import 'package:flutter/material.dart';

/// A manually entered address returned to checkout. Native map selection is
/// deliberately not included in Kanz; delivery is confirmed on the website.
class LocationResult {
  String? street;
  String? country;
  String? state;
  String? city;
  String? zip;
}

class PlacePicker extends StatefulWidget {
  const PlacePicker(this.apiKey, {super.key});

  /// Retained for old callers; the app no longer uses a Maps API key.
  final String? apiKey;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController(text: 'المملكة العربية السعودية');
  final _zip = TextEditingController();

  @override
  void dispose() {
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _zip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدخال العنوان')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('أدخل عنوان التوصيل يدوياً.'),
              const SizedBox(height: 12),
              _field(_street, 'العنوان'),
              _field(_city, 'المدينة'),
              _field(_state, 'المنطقة'),
              _field(_country, 'الدولة'),
              _field(_zip, 'الرمز البريدي', TextInputType.number),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    LocationResult()
                      ..street = _street.text.trim()
                      ..city = _city.text.trim()
                      ..state = _state.text.trim()
                      ..country = _country.text.trim()
                      ..zip = _zip.text.trim(),
                  ),
                  child: const Text('حفظ العنوان'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, [
    TextInputType? keyboardType,
  ]) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
