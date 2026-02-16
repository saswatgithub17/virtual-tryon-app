/// Try-on result model
class TryOnResult {
  final bool success;
  final int? dressId;
  final String? dressName;
  final String? originalDressImage;
  final String? tryonResultUrl;
  final String? resultUrl;
  final String? method;
  final bool aiGenerated;
  final String? error;
  final int? dressIndex;

  TryOnResult({
    this.success = false,
    this.dressId,
    this.dressName,
    this.originalDressImage,
    this.tryonResultUrl,
    this.resultUrl,
    this.method,
    this.aiGenerated = false,
    this.error,
    this.dressIndex,
  });

  // Get the best available result URL
  String? get displayUrl => tryonResultUrl ?? resultUrl;

  factory TryOnResult.fromMap(Map<String, dynamic> json) {
    return TryOnResult(
      success: json['success'] == true,
      dressId: json['dressId'] is int ? json['dressId'] : int.tryParse(json['dressId']?.toString() ?? ''),
      dressName: json['dressName']?.toString(),
      originalDressImage: json['originalDressImage']?.toString(),
      tryonResultUrl: json['tryonResultUrl']?.toString(),
      resultUrl: json['resultUrl']?.toString(),
      method: json['method']?.toString(),
      aiGenerated: json['aiGenerated'] == true || json['method'] != null,
      error: json['error']?.toString(),
      dressIndex: json['dressIndex'] is int ? json['dressIndex'] : int.tryParse(json['dressIndex']?.toString() ?? ''),
    );
  }
}

/// Response wrapper for try-on API
class TryOnResponse {
  final bool success;
  final String? message;
  final TryOnData? data;
  final String? sessionId;
  final String? userPhoto;
  final int? totalDresses;
  final int? successfulTryOns;
  final List<TryOnResult>? results;

  TryOnResponse({
    this.success = false,
    this.message,
    this.data,
    this.sessionId,
    this.userPhoto,
    this.totalDresses,
    this.successfulTryOns,
    this.results,
  });

  factory TryOnResponse.fromMap(Map<String, dynamic> json) {
    List<TryOnResult>? results;
    if (json['results'] != null) {
      results = (json['results'] as List)
          .map((r) => TryOnResult.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    // Handle both direct results and nested data.results
    TryOnData? data;
    if (json['data'] != null) {
      data = TryOnData.fromMap(json['data'] as Map<String, dynamic>);
      // If results are in data, use those
      if (results == null && data.results != null) {
        results = data.results;
      }
    }

    return TryOnResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: data,
      sessionId: json['sessionId']?.toString() ?? data?.sessionId,
      userPhoto: json['userPhoto']?.toString() ?? data?.userPhoto,
      totalDresses: json['totalDresses'] is int 
          ? json['totalDresses'] 
          : int.tryParse(json['totalDresses']?.toString() ?? '') ?? data?.totalDresses,
      successfulTryOns: json['successfulTryOns'] is int 
          ? json['successfulTryOns'] 
          : int.tryParse(json['successfulTryOns']?.toString() ?? '') ?? data?.successfulTryOns,
      results: results,
    );
  }
}

/// Try-on data container
class TryOnData {
  final String? sessionId;
  final String? userPhoto;
  final int? totalDresses;
  final int? successfulTryOns;
  final List<TryOnResult>? results;

  TryOnData({
    this.sessionId,
    this.userPhoto,
    this.totalDresses,
    this.successfulTryOns,
    this.results,
  });

  factory TryOnData.fromMap(Map<String, dynamic> json) {
    List<TryOnResult>? results;
    if (json['results'] != null) {
      results = (json['results'] as List)
          .map((r) => TryOnResult.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    return TryOnData(
      sessionId: json['sessionId']?.toString(),
      userPhoto: json['userPhoto']?.toString(),
      totalDresses: json['totalDresses'] is int 
          ? json['totalDresses'] 
          : int.tryParse(json['totalDresses']?.toString() ?? ''),
      successfulTryOns: json['successfulTryOns'] is int 
          ? json['successfulTryOns'] 
          : int.tryParse(json['successfulTryOns']?.toString() ?? ''),
      results: results,
    );
  }
}
