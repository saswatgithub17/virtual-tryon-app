import 'package:dart_mappable/dart_mappable.dart';
import 'dress_model.dart';

part 'dress_response.mapper.dart';

@MappableClass(caseStyle: CaseStyle.snakeCase)
class DressResponse with DressResponseMappable {
  final bool success;
  final int count;
  final List<Dress> data;
  final String? message;

  DressResponse({
    required this.success,
    required this.count,
    required this.data,
    this.message,
  });

  static const fromMap = DressResponseMapper.fromMap;
  static const fromJson = DressResponseMapper.fromJson;

  /// Creates a successful response from a list of dresses
  factory DressResponse.success({
    required List<Dress> dresses,
    String? message,
  }) {
    return DressResponse(
      success: true,
      count: dresses.length,
      data: dresses,
      message: message,
    );
  }

  /// Creates a failure response
  factory DressResponse.failure({
    required String message,
    int? statusCode,
  }) {
    return DressResponse(
      success: false,
      count: 0,
      data: [],
      message: message,
    );
  }

  /// Checks if the response is successful
  bool get isSuccess => success;

  /// Checks if there are no dresses
  bool get isEmpty => data.isEmpty;

  /// Checks if there are dresses
  bool get isNotEmpty => data.isNotEmpty;
}
