import 'package:flutter_test/flutter_test.dart';
import 'package:wps_mobile/features/qc_spk_bj/model/qc_spk_bundle.dart';

void main() {
  group('QcSpkBundle.fromJson', () {
    test('membaca array fotoTebalUrls (3 foto)', () {
      final b = QcSpkBundle.fromJson({
        'noBundle': 1,
        'fotoTebalUrls': [
          'https://minio.test/a.jpg',
          'https://minio.test/b.jpg',
          'https://minio.test/c.jpg',
        ],
        'fotoTebalUrl': 'https://minio.test/a.jpg',
        'fotoTebalCaptions': ['10', '20', '30'],
        'fotoTebalSlots': [0, 1, 2],
      });

      expect(b.fotoTebalUrls.length, 3);
      expect(b.fotoTebalUrls[1], 'https://minio.test/b.jpg');
      expect(b.fotoTebalUrls[2], 'https://minio.test/c.jpg');
      expect(b.fotoTebalCaptions, ['10', '20', '30']);
      expect(b.fotoTebalSlots, [0, 1, 2]);
      expect(b.photoCount, 3);
    });

    test('membaca array fotoLebarUrls & fotoPanjangUrls', () {
      final b = QcSpkBundle.fromJson({
        'noBundle': 2,
        'fotoLebarUrls': [
          'https://minio.test/l1.jpg',
          'https://minio.test/l2.jpg',
        ],
        'fotoPanjangUrls': ['https://minio.test/p1.jpg'],
        'fotoBundleUrls': ['https://minio.test/b1.jpg'],
      });

      expect(b.fotoLebarUrls.length, 2);
      expect(b.fotoPanjangUrls.length, 1);
      expect(b.fotoBundleUrls.length, 1);
    });

    test('fallback ke scalar fotoTebalUrl untuk server versi lama', () {
      final b = QcSpkBundle.fromJson({
        'noBundle': 3,
        'fotoTebalUrl': 'https://minio.test/only.jpg',
      });

      expect(b.fotoTebalUrls, ['https://minio.test/only.jpg']);
      expect(b.fotoTebalSlots, [0]);
    });

    test('slot di luar rentang diabaikan, jumlah dibatasi 3', () {
      final b = QcSpkBundle.fromJson({
        'noBundle': 4,
        'fotoTebalUrls': [
          'https://minio.test/1.jpg',
          'https://minio.test/2.jpg',
          'https://minio.test/3.jpg',
          'https://minio.test/4.jpg',
        ],
        'fotoTebalSlots': [0, 9, 2],
      });

      expect(b.fotoTebalUrls.length, QcSpkBundle.maxPhotosPerField);
      expect(b.fotoTebalSlots, [0, 1, 2]);
    });
  });
}
