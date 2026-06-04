import '../services/api_service.dart';

// bantu parse angka dari json backend (kadang num bukan int)
class JsonUtils {
  // ubah id/json jadi int, kalo gagal lempar error jelas
  static int asInt(dynamic value, {String label = 'ID'}) {
    if (value == null) {
      throw ApiException('$label tidak valid.');
    }
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ApiException('$label tidak valid.');
  }
}
