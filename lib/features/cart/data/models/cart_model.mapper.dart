// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'cart_model.dart';

class CartItemMapper extends ClassMapperBase<CartItem> {
  CartItemMapper._();

  static CartItemMapper? _instance;
  static CartItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CartItemMapper._());
      DressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CartItem';

  static Dress _$dress(CartItem v) => v.dress;
  static const Field<CartItem, Dress> _f$dress = Field('dress', _$dress);
  static String _$selectedSize(CartItem v) => v.selectedSize;
  static const Field<CartItem, String> _f$selectedSize =
      Field('selectedSize', _$selectedSize, key: r'selected_size');
  static int _$quantity(CartItem v) => v.quantity;
  static const Field<CartItem, int> _f$quantity =
      Field('quantity', _$quantity, opt: true, def: 1);

  @override
  final MappableFields<CartItem> fields = const {
    #dress: _f$dress,
    #selectedSize: _f$selectedSize,
    #quantity: _f$quantity,
  };

  static CartItem _instantiate(DecodingData data) {
    return CartItem(
        dress: data.dec(_f$dress),
        selectedSize: data.dec(_f$selectedSize),
        quantity: data.dec(_f$quantity));
  }

  @override
  final Function instantiate = _instantiate;

  static CartItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartItem>(map);
  }

  static CartItem fromJson(String json) {
    return ensureInitialized().decodeJson<CartItem>(json);
  }
}

mixin CartItemMappable {
  String toJson() {
    return CartItemMapper.ensureInitialized()
        .encodeJson<CartItem>(this as CartItem);
  }

  Map<String, dynamic> toMap() {
    return CartItemMapper.ensureInitialized()
        .encodeMap<CartItem>(this as CartItem);
  }

  CartItemCopyWith<CartItem, CartItem, CartItem> get copyWith =>
      _CartItemCopyWithImpl<CartItem, CartItem>(
          this as CartItem, $identity, $identity);
  @override
  String toString() {
    return CartItemMapper.ensureInitialized().stringifyValue(this as CartItem);
  }

  @override
  bool operator ==(Object other) {
    return CartItemMapper.ensureInitialized()
        .equalsValue(this as CartItem, other);
  }

  @override
  int get hashCode {
    return CartItemMapper.ensureInitialized().hashValue(this as CartItem);
  }
}

extension CartItemValueCopy<$R, $Out> on ObjectCopyWith<$R, CartItem, $Out> {
  CartItemCopyWith<$R, CartItem, $Out> get $asCartItem =>
      $base.as((v, t, t2) => _CartItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CartItemCopyWith<$R, $In extends CartItem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  DressCopyWith<$R, Dress, Dress> get dress;
  $R call({Dress? dress, String? selectedSize, int? quantity});
  CartItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CartItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartItem, $Out>
    implements CartItemCopyWith<$R, CartItem, $Out> {
  _CartItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartItem> $mapper =
      CartItemMapper.ensureInitialized();
  @override
  DressCopyWith<$R, Dress, Dress> get dress =>
      $value.dress.copyWith.$chain((v) => call(dress: v));
  @override
  $R call({Dress? dress, String? selectedSize, int? quantity}) =>
      $apply(FieldCopyWithData({
        if (dress != null) #dress: dress,
        if (selectedSize != null) #selectedSize: selectedSize,
        if (quantity != null) #quantity: quantity
      }));
  @override
  CartItem $make(CopyWithData data) => CartItem(
      dress: data.get(#dress, or: $value.dress),
      selectedSize: data.get(#selectedSize, or: $value.selectedSize),
      quantity: data.get(#quantity, or: $value.quantity));

  @override
  CartItemCopyWith<$R2, CartItem, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CartItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
