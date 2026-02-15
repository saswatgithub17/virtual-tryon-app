import 'package:dart_mappable/dart_mappable.dart';

part 'tryon_model.mapper.dart';

@MappableClass(caseStyle: CaseStyle.snakeCase)
class TryOnResult with TryOnResultMappable {
  final String resultUrl;
  final int dressId;
  final String dressName;
  final bool aiGenerated;
  final String? method;

  TryOnResult({
    required this.resultUrl,
    required this.dressId,
    required this.dressName,
    required this.aiGenerated,
    this.method,
  });

  static const fromMap = TryOnResultMapper.fromMap;
  static const fromJson = TryOnResultMapper.fromJson;
}
