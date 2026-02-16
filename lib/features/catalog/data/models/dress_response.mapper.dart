// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'dress_response.dart';

class DressResponseMapper extends ClassMapperBase<DressResponse> {
  DressResponseMapper._();

  static DressResponseMapper? _instance;
  static DressResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DressResponseMapper._());
      DressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DressResponse';

  static bool _$success(DressResponse v) => v.success;
  static const Field<DressResponse, bool> _f$success =
      Field('success', _$success);
  static int _$count(DressResponse v) => v.count;
  static const Field<DressResponse, int> _f$count = Field('count', _$count);
  static List<Dress> _$data(DressResponse v) => v.data;
  static const Field<DressResponse, List<Dress>> _f$data =
      Field('data', _$data);
  static String? _$message(DressResponse v) => v.message;
  static const Field<DressResponse, String> _f$message =
      Field('message', _$message, opt: true);

  @override
  final MappableFields<DressResponse> fields = const {
    #success: _f$success,
    #count: _f$count,
    #data: _f$data,
    #message: _f$message,
  };

  static DressResponse _instantiate(DecodingData data) {
    return DressResponse(
        success: data.dec(_f$success),
        count: data.dec(_f$count),
        data: data.dec(_f$data),
        message: data.dec(_f$message));
  }

  @override
  final Function instantiate = _instantiate;

  static DressResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DressResponse>(map);
  }

  static DressResponse fromJson(String json) {
    return ensureInitialized().decodeJson<DressResponse>(json);
  }
}

mixin DressResponseMappable {
  String toJson() {
    return DressResponseMapper.ensureInitialized()
        .encodeJson<DressResponse>(this as DressResponse);
  }

  Map<String, dynamic> toMap() {
    return DressResponseMapper.ensureInitialized()
        .encodeMap<DressResponse>(this as DressResponse);
  }

  DressResponseCopyWith<DressResponse, DressResponse, DressResponse>
      get copyWith => _DressResponseCopyWithImpl<DressResponse, DressResponse>(
          this as DressResponse, $identity, $identity);
  @override
  String toString() {
    return DressResponseMapper.ensureInitialized()
        .stringifyValue(this as DressResponse);
  }

  @override
  bool operator ==(Object other) {
    return DressResponseMapper.ensureInitialized()
        .equalsValue(this as DressResponse, other);
  }

  @override
  int get hashCode {
    return DressResponseMapper.ensureInitialized()
        .hashValue(this as DressResponse);
  }
}

extension DressResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DressResponse, $Out> {
  DressResponseCopyWith<$R, DressResponse, $Out> get $asDressResponse =>
      $base.as((v, t, t2) => _DressResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DressResponseCopyWith<$R, $In extends DressResponse, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Dress, DressCopyWith<$R, Dress, Dress>> get data;
  $R call({bool? success, int? count, List<Dress>? data, String? message});
  DressResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DressResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DressResponse, $Out>
    implements DressResponseCopyWith<$R, DressResponse, $Out> {
  _DressResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DressResponse> $mapper =
      DressResponseMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Dress, DressCopyWith<$R, Dress, Dress>> get data =>
      ListCopyWith(
          $value.data, (v, t) => v.copyWith.$chain(t), (v) => call(data: v));
  @override
  $R call(
          {bool? success,
          int? count,
          List<Dress>? data,
          Object? message = $none}) =>
      $apply(FieldCopyWithData({
        if (success != null) #success: success,
        if (count != null) #count: count,
        if (data != null) #data: data,
        if (message != $none) #message: message
      }));
  @override
  DressResponse $make(CopyWithData data) => DressResponse(
      success: data.get(#success, or: $value.success),
      count: data.get(#count, or: $value.count),
      data: data.get(#data, or: $value.data),
      message: data.get(#message, or: $value.message));

  @override
  DressResponseCopyWith<$R2, DressResponse, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _DressResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
