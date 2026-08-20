import 'package:url_launcher/url_launcher.dart';

class CommunicationService {
  Future<bool> openWhatsApp({required String phone, required String message}) {
    final normalized = normalizePhone(phone);
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openSms({required String phone, required String message}) {
    final normalized = normalizePhone(phone);
    final uri = Uri(
      scheme: 'sms',
      path: normalized,
      queryParameters: {'body': message},
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String normalizePhone(String raw) {
    var value = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.startsWith('0')) value = '62${value.substring(1)}';
    return value;
  }
}
