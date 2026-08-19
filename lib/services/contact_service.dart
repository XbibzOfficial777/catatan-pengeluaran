import 'package:flutter_contacts/flutter_contacts.dart';

class SelectedContact {
  const SelectedContact({required this.id, required this.name, required this.phone});

  final String id;
  final String name;
  final String? phone;
}

class ContactService {
  Future<SelectedContact?> pickContact() async {
    final permission = await FlutterContacts.permissions.request(PermissionType.read);
    if (permission != PermissionStatus.granted && permission != PermissionStatus.limited) {
      return null;
    }

    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone},
    );
    if (contact == null || contact.id == null) return null;

    return SelectedContact(
      id: contact.id!,
      name: (contact.displayName ?? '').trim().isEmpty ? 'Kontak tanpa nama' : contact.displayName!.trim(),
      phone: contact.phones.isEmpty ? null : contact.phones.first.number.trim(),
    );
  }
}
