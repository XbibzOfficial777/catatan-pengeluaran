import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import '../lib/services/backup_integrity_service.dart';

void main() {
  test('canonicalization ignores manifest formatting whitespace', () {
    final service = BackupIntegrityService();
    final original = XmlElement.tag(
      'bibzcup',
      attributes: [
        XmlAttribute(XmlName.parts('format'), 'bibzcup'),
        XmlAttribute(XmlName.parts('version'), '2'),
        XmlAttribute(XmlName.parts('manifest'), 'xml'),
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
                    XmlAttribute(XmlName.parts('name'), 'title'),
                    XmlAttribute(XmlName.parts('type'), 'string'),
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
    final pretty = XmlDocument([original])
        .toXmlString(pretty: true, indent: '  ');
    final parsed = XmlDocument.parse(pretty).rootElement;

    expect(service.canonicalize(parsed), service.canonicalize(original));
  });
}
