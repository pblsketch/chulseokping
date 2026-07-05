// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_room_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClassRoomDto {

 String get id;@JsonKey(name: 'school_id') String? get schoolId;@JsonKey(name: 'teacher_id') String get teacherId; String get name;@JsonKey(name: 'invite_code') String get inviteCode;
/// Create a copy of ClassRoomDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassRoomDtoCopyWith<ClassRoomDto> get copyWith => _$ClassRoomDtoCopyWithImpl<ClassRoomDto>(this as ClassRoomDto, _$identity);

  /// Serializes this ClassRoomDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassRoomDto&&(identical(other.id, id) || other.id == id)&&(identical(other.schoolId, schoolId) || other.schoolId == schoolId)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.name, name) || other.name == name)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,schoolId,teacherId,name,inviteCode);

@override
String toString() {
  return 'ClassRoomDto(id: $id, schoolId: $schoolId, teacherId: $teacherId, name: $name, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class $ClassRoomDtoCopyWith<$Res>  {
  factory $ClassRoomDtoCopyWith(ClassRoomDto value, $Res Function(ClassRoomDto) _then) = _$ClassRoomDtoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'school_id') String? schoolId,@JsonKey(name: 'teacher_id') String teacherId, String name,@JsonKey(name: 'invite_code') String inviteCode
});




}
/// @nodoc
class _$ClassRoomDtoCopyWithImpl<$Res>
    implements $ClassRoomDtoCopyWith<$Res> {
  _$ClassRoomDtoCopyWithImpl(this._self, this._then);

  final ClassRoomDto _self;
  final $Res Function(ClassRoomDto) _then;

/// Create a copy of ClassRoomDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? schoolId = freezed,Object? teacherId = null,Object? name = null,Object? inviteCode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schoolId: freezed == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String?,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassRoomDto].
extension ClassRoomDtoPatterns on ClassRoomDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassRoomDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassRoomDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassRoomDto value)  $default,){
final _that = this;
switch (_that) {
case _ClassRoomDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassRoomDto value)?  $default,){
final _that = this;
switch (_that) {
case _ClassRoomDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'school_id')  String? schoolId, @JsonKey(name: 'teacher_id')  String teacherId,  String name, @JsonKey(name: 'invite_code')  String inviteCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassRoomDto() when $default != null:
return $default(_that.id,_that.schoolId,_that.teacherId,_that.name,_that.inviteCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'school_id')  String? schoolId, @JsonKey(name: 'teacher_id')  String teacherId,  String name, @JsonKey(name: 'invite_code')  String inviteCode)  $default,) {final _that = this;
switch (_that) {
case _ClassRoomDto():
return $default(_that.id,_that.schoolId,_that.teacherId,_that.name,_that.inviteCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'school_id')  String? schoolId, @JsonKey(name: 'teacher_id')  String teacherId,  String name, @JsonKey(name: 'invite_code')  String inviteCode)?  $default,) {final _that = this;
switch (_that) {
case _ClassRoomDto() when $default != null:
return $default(_that.id,_that.schoolId,_that.teacherId,_that.name,_that.inviteCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassRoomDto extends ClassRoomDto {
  const _ClassRoomDto({required this.id, @JsonKey(name: 'school_id') this.schoolId, @JsonKey(name: 'teacher_id') required this.teacherId, required this.name, @JsonKey(name: 'invite_code') required this.inviteCode}): super._();
  factory _ClassRoomDto.fromJson(Map<String, dynamic> json) => _$ClassRoomDtoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'school_id') final  String? schoolId;
@override@JsonKey(name: 'teacher_id') final  String teacherId;
@override final  String name;
@override@JsonKey(name: 'invite_code') final  String inviteCode;

/// Create a copy of ClassRoomDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassRoomDtoCopyWith<_ClassRoomDto> get copyWith => __$ClassRoomDtoCopyWithImpl<_ClassRoomDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassRoomDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassRoomDto&&(identical(other.id, id) || other.id == id)&&(identical(other.schoolId, schoolId) || other.schoolId == schoolId)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.name, name) || other.name == name)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,schoolId,teacherId,name,inviteCode);

@override
String toString() {
  return 'ClassRoomDto(id: $id, schoolId: $schoolId, teacherId: $teacherId, name: $name, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class _$ClassRoomDtoCopyWith<$Res> implements $ClassRoomDtoCopyWith<$Res> {
  factory _$ClassRoomDtoCopyWith(_ClassRoomDto value, $Res Function(_ClassRoomDto) _then) = __$ClassRoomDtoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'school_id') String? schoolId,@JsonKey(name: 'teacher_id') String teacherId, String name,@JsonKey(name: 'invite_code') String inviteCode
});




}
/// @nodoc
class __$ClassRoomDtoCopyWithImpl<$Res>
    implements _$ClassRoomDtoCopyWith<$Res> {
  __$ClassRoomDtoCopyWithImpl(this._self, this._then);

  final _ClassRoomDto _self;
  final $Res Function(_ClassRoomDto) _then;

/// Create a copy of ClassRoomDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? schoolId = freezed,Object? teacherId = null,Object? name = null,Object? inviteCode = null,}) {
  return _then(_ClassRoomDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schoolId: freezed == schoolId ? _self.schoolId : schoolId // ignore: cast_nullable_to_non_nullable
as String?,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
