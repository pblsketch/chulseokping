// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consent_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConsentDto {

 String get id;@JsonKey(name: 'student_id') String get studentId;@JsonKey(name: 'policy_version') String get policyVersion;@JsonKey(name: 'guardian_confirmed_by') String? get guardianConfirmedBy;@JsonKey(name: 'consented_at') DateTime get consentedAt;
/// Create a copy of ConsentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentDtoCopyWith<ConsentDto> get copyWith => _$ConsentDtoCopyWithImpl<ConsentDto>(this as ConsentDto, _$identity);

  /// Serializes this ConsentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.guardianConfirmedBy, guardianConfirmedBy) || other.guardianConfirmedBy == guardianConfirmedBy)&&(identical(other.consentedAt, consentedAt) || other.consentedAt == consentedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,policyVersion,guardianConfirmedBy,consentedAt);

@override
String toString() {
  return 'ConsentDto(id: $id, studentId: $studentId, policyVersion: $policyVersion, guardianConfirmedBy: $guardianConfirmedBy, consentedAt: $consentedAt)';
}


}

/// @nodoc
abstract mixin class $ConsentDtoCopyWith<$Res>  {
  factory $ConsentDtoCopyWith(ConsentDto value, $Res Function(ConsentDto) _then) = _$ConsentDtoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'student_id') String studentId,@JsonKey(name: 'policy_version') String policyVersion,@JsonKey(name: 'guardian_confirmed_by') String? guardianConfirmedBy,@JsonKey(name: 'consented_at') DateTime consentedAt
});




}
/// @nodoc
class _$ConsentDtoCopyWithImpl<$Res>
    implements $ConsentDtoCopyWith<$Res> {
  _$ConsentDtoCopyWithImpl(this._self, this._then);

  final ConsentDto _self;
  final $Res Function(ConsentDto) _then;

/// Create a copy of ConsentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? policyVersion = null,Object? guardianConfirmedBy = freezed,Object? consentedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,policyVersion: null == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String,guardianConfirmedBy: freezed == guardianConfirmedBy ? _self.guardianConfirmedBy : guardianConfirmedBy // ignore: cast_nullable_to_non_nullable
as String?,consentedAt: null == consentedAt ? _self.consentedAt : consentedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsentDto].
extension ConsentDtoPatterns on ConsentDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsentDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsentDto value)  $default,){
final _that = this;
switch (_that) {
case _ConsentDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsentDto value)?  $default,){
final _that = this;
switch (_that) {
case _ConsentDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'policy_version')  String policyVersion, @JsonKey(name: 'guardian_confirmed_by')  String? guardianConfirmedBy, @JsonKey(name: 'consented_at')  DateTime consentedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsentDto() when $default != null:
return $default(_that.id,_that.studentId,_that.policyVersion,_that.guardianConfirmedBy,_that.consentedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'policy_version')  String policyVersion, @JsonKey(name: 'guardian_confirmed_by')  String? guardianConfirmedBy, @JsonKey(name: 'consented_at')  DateTime consentedAt)  $default,) {final _that = this;
switch (_that) {
case _ConsentDto():
return $default(_that.id,_that.studentId,_that.policyVersion,_that.guardianConfirmedBy,_that.consentedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'policy_version')  String policyVersion, @JsonKey(name: 'guardian_confirmed_by')  String? guardianConfirmedBy, @JsonKey(name: 'consented_at')  DateTime consentedAt)?  $default,) {final _that = this;
switch (_that) {
case _ConsentDto() when $default != null:
return $default(_that.id,_that.studentId,_that.policyVersion,_that.guardianConfirmedBy,_that.consentedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsentDto extends ConsentDto {
  const _ConsentDto({required this.id, @JsonKey(name: 'student_id') required this.studentId, @JsonKey(name: 'policy_version') required this.policyVersion, @JsonKey(name: 'guardian_confirmed_by') this.guardianConfirmedBy, @JsonKey(name: 'consented_at') required this.consentedAt}): super._();
  factory _ConsentDto.fromJson(Map<String, dynamic> json) => _$ConsentDtoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'student_id') final  String studentId;
@override@JsonKey(name: 'policy_version') final  String policyVersion;
@override@JsonKey(name: 'guardian_confirmed_by') final  String? guardianConfirmedBy;
@override@JsonKey(name: 'consented_at') final  DateTime consentedAt;

/// Create a copy of ConsentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentDtoCopyWith<_ConsentDto> get copyWith => __$ConsentDtoCopyWithImpl<_ConsentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.guardianConfirmedBy, guardianConfirmedBy) || other.guardianConfirmedBy == guardianConfirmedBy)&&(identical(other.consentedAt, consentedAt) || other.consentedAt == consentedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,policyVersion,guardianConfirmedBy,consentedAt);

@override
String toString() {
  return 'ConsentDto(id: $id, studentId: $studentId, policyVersion: $policyVersion, guardianConfirmedBy: $guardianConfirmedBy, consentedAt: $consentedAt)';
}


}

/// @nodoc
abstract mixin class _$ConsentDtoCopyWith<$Res> implements $ConsentDtoCopyWith<$Res> {
  factory _$ConsentDtoCopyWith(_ConsentDto value, $Res Function(_ConsentDto) _then) = __$ConsentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'student_id') String studentId,@JsonKey(name: 'policy_version') String policyVersion,@JsonKey(name: 'guardian_confirmed_by') String? guardianConfirmedBy,@JsonKey(name: 'consented_at') DateTime consentedAt
});




}
/// @nodoc
class __$ConsentDtoCopyWithImpl<$Res>
    implements _$ConsentDtoCopyWith<$Res> {
  __$ConsentDtoCopyWithImpl(this._self, this._then);

  final _ConsentDto _self;
  final $Res Function(_ConsentDto) _then;

/// Create a copy of ConsentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? policyVersion = null,Object? guardianConfirmedBy = freezed,Object? consentedAt = null,}) {
  return _then(_ConsentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,policyVersion: null == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String,guardianConfirmedBy: freezed == guardianConfirmedBy ? _self.guardianConfirmedBy : guardianConfirmedBy // ignore: cast_nullable_to_non_nullable
as String?,consentedAt: null == consentedAt ? _self.consentedAt : consentedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
