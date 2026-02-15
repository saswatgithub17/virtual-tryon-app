// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'tryon_model.dart';

class TryOnResultMapper extends ClassMapperBase<TryOnResult> {
  TryOnResultMapper._();

  static TryOnResultMapper? _instance;
  static TryOnResultMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TryOnResultMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TryOnResult';

  static String _$resultUrl(TryOnResult v) => v.resultUrl;
  static const Field<TryOnResult, String> _f$resultUrl =
      Field('resultUrl', _$resultUrl, key: r'result_url');
  static int _$dressId(TryOnResult v) => v.dressId;
  static const Field<TryOnResult, int> _f$dressId =
      Field('dressId', _$dressId, key: r'dress_id');
  static String _$dressName(TryOnResult v) => v.dressName;
  static const Field<TryOnResult, String> _f$dressName =
      Field('dressName', _$dressName, key: r'dress_name');
  static bool _$aiGenerated(TryOnResult v) => v.aiGenerated;
  static const Field<TryOnResult, bool> _f$aiGenerated =
      Field('aiGenerated', _$aiGenerated, key: r'ai_generated');
  static String? _$method(TryOnResult v) => v.method;
  static const Field<TryOnResult, String> _f$method =
      Field('method', _$method, opt: true);

  @override
  final MappableFields<TryOnResult> fields = const {
    #resultUrl: _f$resultUrl,
    #dressId: _f$dressId,
    #dressName: _f$dressName,
    #aiGenerated: _f$aiGenerated,
    #method: _f$method,
  };

  static TryOnResult _instantiate(DecodingData data) {
    return TryOnResult(
        resultUrl: data.dec(_f$resultUrl),
        dressId: data.dec(_f$dressId),
        dressName: data.dec(_f$dressName),
        aiGenerated: data.dec(_f$aiGenerated),
        method: data.dec(_f$method));
  }

  @override
  final Function instantiate = _instantiate;

  static TryOnResult fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TryOnResult>(map);
  }

  static TryOnResult fromJson(String json) {
    return ensureInitialized().decodeJson<TryOnResult>(json);
  }
}

mixin TryOnResultMappable {
  String toJson() {
    return TryOnResultMapper.ensureInitialized()
        .encodeJson<TryOnResult>(this as TryOnResult);
  }

  Map<String, dynamic> toMap() {
    return TryOnResultMapper.ensureInitialized()
        .encodeMap<TryOnResult>(this as TryOnResult);
  }

  TryOnResultCopyWith<TryOnResult, TryOnResult, TryOnResult> get copyWith =>
      _TryOnResultCopyWithImpl<TryOnResult, TryOnResult>(
          this as TryOnResult, $identity, $identity);
  @override
  String toString() {
    return TryOnResultMapper.ensureInitialized()
        .stringifyValue(this as TryOnResult);
  }

  @override
  bool operator ==(Object other) {
    return TryOnResultMapper.ensureInitialized()
        .equalsValue(this as TryOnResult, other);
  }

  @override
  int get hashCode {
    return TryOnResultMapper.ensureInitialized().hashValue(this as TryOnResult);
  }
}

extension TryOnResultValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TryOnResult, $Out> {
  TryOnResultCopyWith<$R, TryOnResult, $Out> get $asTryOnResult =>
      $base.as((v, t, t2) => _TryOnResultCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TryOnResultCopyWith<$R, $In extends TryOnResult, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? resultUrl,
      int? dressId,
      String? dressName,
      bool? aiGenerated,
      String? method});
  TryOnResultCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TryOnResultCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TryOnResult, $Out>
    implements TryOnResultCopyWith<$R, TryOnResult, $Out> {
  _TryOnResultCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TryOnResult> $mapper =
      TryOnResultMapper.ensureInitialized();
  @override
  $R call(
          {String? resultUrl,
          int? dressId,
          String? dressName,
          bool? aiGenerated,
          Object? method = $none}) =>
      $apply(FieldCopyWithData({
        if (resultUrl != null) #resultUrl: resultUrl,
        if (dressId != null) #dressId: dressId,
        if (dressName != null) #dressName: dressName,
        if (aiGenerated != null) #aiGenerated: aiGenerated,
        if (method != $none) #method: method
      }));
  @override
  TryOnResult $make(CopyWithData data) => TryOnResult(
      resultUrl: data.get(#resultUrl, or: $value.resultUrl),
      dressId: data.get(#dressId, or: $value.dressId),
      dressName: data.get(#dressName, or: $value.dressName),
      aiGenerated: data.get(#aiGenerated, or: $value.aiGenerated),
      method: data.get(#method, or: $value.method));

  @override
  TryOnResultCopyWith<$R2, TryOnResult, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _TryOnResultCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
