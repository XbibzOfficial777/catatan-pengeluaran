import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import '../lib/services/backup_integrity_service.dart';

void main() {
  test('canonicalization ignores manifest formatting whitespace', () {
    final service = BackupIntegrityService();
    final original = XmlElement.tag(
      'bibzcup',
      attributes: [
        XmlAttribute(XmlName('format'), 'bibzcup'),
        XmlAttribute(XmlName('version'), '2'),
        XmlAttribute(XmlName('manifest'), 'xml'),
      ],
      children: [
        XmlElement.tag(
          'expenses',
          children: [
            XmlElement.tag(
              'expense',
              children: [
                XmlElement.tag(
                  'field',
                  attributes: [
                    XmlAttribute(XmlName('name'), 'title'),
                    XmlAttribute(XmlName('type'), 'string'),
                  ],
                  children: [XmlText('Makan siang')],
                ),
              ],
            ),
          ],
        ),
        XmlElement.tag('files'),
      ],
    );
    final pretty = XmlDocument([
      original,
    ]).toXmlString(pretty: true, indent: '  ');
    final parsed = XmlDocument.parse(pretty).rootElement;

    expect(service.canonicalize(parsed), service.canonicalize(original));
  });

  test('nested JSON fields round-trip through XML entry parser', () {
    final service = BackupIntegrityService();
    final entry = service.createEntry('splitBill', {
      'title': 'Makan bersama',
      'participants': [
        {'id': '1', 'name': 'A', 'amount': 50000},
        {'id': '2', 'name': 'B', 'amount': 50000},
      ],
    });
    final parsed = service.parseEntry(entry);
    expect(parsed['title'], 'Makan bersama');
    expect(parsed['participants'], isA<List>());
    expect((parsed['participants'] as List).length, 2);
    expect((parsed['participants'] as List).first['name'], 'A');
  });
}
