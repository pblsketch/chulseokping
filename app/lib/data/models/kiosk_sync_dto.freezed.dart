// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kiosk_sync_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KioskSessionDto {

 String get id; String get type; int? get period;
/// Create a copy of KioskSessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KioskSessionDtoCopyWith<KioskSessionDto> get copyWith => _$KioskSessionDtoCopyWithImpl<KioskSessionDto>(this as KioskSessionDto, _$identity);

  /// Serializes this KioskSessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KioskSessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,period);

@override
String toString() {
  return 'KioskSessionDto(id: $id, type: $type, period: $period)';
}


}

/// @nodoc
abstract mixin class $KioskSessionDtoCopyWith<$Res>  {
  factory $KioskSessionDtoCopyWith(KioskSessionDto value, $Res Function(KioskSessionDto) _then) = _$KioskSessionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String type, int? period
});




}
/// @nodoc
class _$KioskSessionDtoCopyWithImpl<$Res>
    implements $KioskSessionDtoCopyWith<$Res> {
  _$KioskSessionDtoCopyWithImpl(this._self, this._then);

  final KioskSessionDto _self;
  final $Res Function(KioskSessionDto) _then;

/// Create a copy of KioskSessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? period = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [KioskSessionDto].
extension KioskSessionDtoPatterns on KioskSessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KioskSessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KioskSessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KioskSessionDto value)  $default,){
final _that = this;
switch (_that) {
case _KioskSessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KioskSessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _KioskSessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  int? period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KioskSessionDto() when $default != null:
return $default(_that.id,_that.type,_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  int? period)  $default,) {final _that = this;
switch (_that) {
case _KioskSessionDto():
return $default(_that.id,_that.type,_that.period);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  int? period)?  $default,) {final _that = this;
switch (_that) {
case _KioskSessionDto() when $default != null:
return $default(_that.id,_that.type,_that.period);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KioskSessionDto extends KioskSessionDto {
  const _KioskSessionDto({required this.id, required this.type, this.period}): super._();
  factory _KioskSessionDto.fromJson(Map<String, dynamic> json) => _$KioskSessionDtoFromJson(json);

@override final  String id;
@override final  String type;
@override final  int? period;

/// Create a copy of KioskSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KioskSessionDtoCopyWith<_KioskSessionDto> get copyWith => __$KioskSessionDtoCopyWithImpl<_KioskSessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KioskSessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KioskSessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,period);

@override
String toString() {
  return 'KioskSessionDto(id: $id, type: $type, period: $period)';
}


}

/// @nodoc
abstract mixin class _$KioskSessionDtoCopyWith<$Res> implements $KioskSessionDtoCopyWith<$Res> {
  factory _$KioskSessionDtoCopyWith(_KioskSessionDto value, $Res Function(_KioskSessionDto) _then) = __$KioskSessionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, int? period
});




}
/// @nodoc
class __$KioskSessionDtoCopyWithImpl<$Res>
    implements _$KioskSessionDtoCopyWith<$Res> {
  __$KioskSessionDtoCopyWithImpl(this._self, this._then);

  final _KioskSessionDto _self;
  final $Res Function(_KioskSessionDto) _then;

/// Create a copy of KioskSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? period = freezed,}) {
  return _then(_KioskSessionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$KioskSyncDto {

@JsonKey(name: 'device_id') String get deviceId;@JsonKey(name: 'class_id') String get classId;@JsonKey(name: 'class_name') String get className;@JsonKey(name: 'beacon_major') int get beaconMajor;@JsonKey(name: 'beacon_secret') String get beaconSecret;@JsonKey(name: 'qr_secret') String? get qrSecret; KioskSessionDto? get session;
/// Create a copy of KioskSyncDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KioskSyncDtoCopyWith<KioskSyncDto> get copyWith => _$KioskSyncDtoCopyWithImpl<KioskSyncDto>(this as KioskSyncDto, _$identity);

  /// Serializes this KioskSyncDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KioskSyncDto&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.className, className) || other.className == className)&&(identical(other.beaconMajor, beaconMajor) || other.beaconMajor == beaconMajor)&&(identical(other.beaconSecret, beaconSecret) || other.beaconSecret == beaconSecret)&&(identical(other.qrSecret, qrSecret) || other.qrSecret == qrSecret)&&(identical(other.session, session) || other.session == session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,classId,className,beaconMajor,beaconSecret,qrSecret,session);

@override
String toString() {
  return 'KioskSyncDto(deviceId: $deviceId, classId: $classId, className: $className, beaconMajor: $beaconMajor, beaconSecret: $beaconSecret, qrSecret: $qrSecret, session: $session)';
}


}

/// @nodoc
abstract mixin class $KioskSyncDtoCopyWith<$Res>  {
  factory $KioskSyncDtoCopyWith(KioskSyncDto value, $Res Function(KioskSyncDto) _then) = _$KioskSyncDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'class_id') String classId,@JsonKey(name: 'class_name') String className,@JsonKey(name: 'beacon_major') int beaconMajor,@JsonKey(name: 'beacon_secret') String beaconSecret,@JsonKey(name: 'qr_secret') String? qrSecret, KioskSessionDto? session
});


$KioskSessionDtoCopyWith<$Res>? get session;

}
/// @nodoc
class _$KioskSyncDtoCopyWithImpl<$Res>
    implements $KioskSyncDtoCopyWith<$Res> {
  _$KioskSyncDtoCopyWithImpl(this._self, this._then);

  final KioskSyncDto _self;
  final $Res Function(KioskSyncDto) _then;

/// Create a copy of KioskSyncDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? classId = null,Object? className = null,Object? beaconMajor = null,Object? beaconSecret = null,Object? qrSecret = freezed,Object? session = freezed,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,beaconMajor: null == beaconMajor ? _self.beaconMajor : beaconMajor // ignore: cast_nullable_to_non_nullable
as int,beaconSecret: null == beaconSecret ? _self.beaconSecret : beaconSecret // ignore: cast_nullable_to_non_nullable
as String,qrSecret: freezed == qrSecret ? _self.qrSecret : qrSecret // ignore: cast_nullable_to_non_nullable
as String?,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as KioskSessionDto?,
  ));
}
/// Create a copy of KioskSyncDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KioskSessionDtoCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $KioskSessionDtoCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [KioskSyncDto].
extension KioskSyncDtoPatterns on KioskSyncDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KioskSyncDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KioskSyncDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KioskSyncDto value)  $default,){
final _that = this;
switch (_that) {
case _KioskSyncDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KioskSyncDto value)?  $default,){
final _that = this;
switch (_that) {
case _KioskSyncDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'class_name')  String className, @JsonKey(name: 'beacon_major')  int beaconMajor, @JsonKey(name: 'beacon_secret')  String beaconSecret, @JsonKey(name: 'qr_secret')  String? qrSecret,  KioskSessionDto? session)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KioskSyncDto() when $default != null:
return $default(_that.deviceId,_that.classId,_that.className,_that.beaconMajor,_that.beaconSecret,_that.qrSecret,_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'class_name')  String className, @JsonKey(name: 'beacon_major')  int beaconMajor, @JsonKey(name: 'beacon_secret')  String beaconSecret, @JsonKey(name: 'qr_secret')  String? qrSecret,  KioskSessionDto? session)  $default,) {final _that = this;
switch (_that) {
case _KioskSyncDto():
return $default(_that.deviceId,_that.classId,_that.className,_that.beaconMajor,_that.beaconSecret,_that.qrSecret,_that.session);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'class_name')  String className, @JsonKey(name: 'beacon_major')  int beaconMajor, @JsonKey(name: 'beacon_secret')  String beaconSecret, @JsonKey(name: 'qr_secret')  String? qrSecret,  KioskSessionDto? session)?  $default,) {final _that = this;
switch (_that) {
case _KioskSyncDto() when $default != null:
return $default(_that.deviceId,_that.classId,_that.className,_that.beaconMajor,_that.beaconSecret,_that.qrSecret,_that.session);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KioskSyncDto extends KioskSyncDto {
  const _KioskSyncDto({@JsonKey(name: 'device_id') required this.deviceId, @JsonKey(name: 'class_id') required this.classId, @JsonKey(name: 'class_name') required this.className, @JsonKey(name: 'beacon_major') required this.beaconMajor, @JsonKey(name: 'beacon_secret') required this.beaconSecret, @JsonKey(name: 'qr_secret') this.qrSecret, this.session}): super._();
  factory _KioskSyncDto.fromJson(Map<String, dynamic> json) => _$KioskSyncDtoFromJson(json);

@override@JsonKey(name: 'device_id') final  String deviceId;
@override@JsonKey(name: 'class_id') final  String classId;
@override@JsonKey(name: 'class_name') final  String className;
@override@JsonKey(name: 'beacon_major') final  int beaconMajor;
@override@JsonKey(name: 'beacon_secret') final  String beaconSecret;
@override@JsonKey(name: 'qr_secret') final  String? qrSecret;
@override final  KioskSessionDto? session;

/// Create a copy of KioskSyncDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KioskSyncDtoCopyWith<_KioskSyncDto> get copyWith => __$KioskSyncDtoCopyWithImpl<_KioskSyncDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KioskSyncDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KioskSyncDto&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.className, className) || other.className == className)&&(identical(other.beaconMajor, beaconMajor) || other.beaconMajor == beaconMajor)&&(identical(other.beaconSecret, beaconSecret) || other.beaconSecret == beaconSecret)&&(identical(other.qrSecret, qrSecret) || other.qrSecret == qrSecret)&&(identical(other.session, session) || other.session == session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,classId,className,beaconMajor,beaconSecret,qrSecret,session);

@override
String toString() {
  return 'KioskSyncDto(deviceId: $deviceId, classId: $classId, className: $className, beaconMajor: $beaconMajor, beaconSecret: $beaconSecret, qrSecret: $qrSecret, session: $session)';
}


}

/// @nodoc
abstract mixin class _$KioskSyncDtoCopyWith<$Res> implements $KioskSyncDtoCopyWith<$Res> {
  factory _$KioskSyncDtoCopyWith(_KioskSyncDto value, $Res Function(_KioskSyncDto) _then) = __$KioskSyncDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'class_id') String classId,@JsonKey(name: 'class_name') String className,@JsonKey(name: 'beacon_major') int beaconMajor,@JsonKey(name: 'beacon_secret') String beaconSecret,@JsonKey(name: 'qr_secret') String? qrSecret, KioskSessionDto? session
});


@override $KioskSessionDtoCopyWith<$Res>? get session;

}
/// @nodoc
class __$KioskSyncDtoCopyWithImpl<$Res>
    implements _$KioskSyncDtoCopyWith<$Res> {
  __$KioskSyncDtoCopyWithImpl(this._self, this._then);

  final _KioskSyncDto _self;
  final $Res Function(_KioskSyncDto) _then;

/// Create a copy of KioskSyncDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? classId = null,Object? className = null,Object? beaconMajor = null,Object? beaconSecret = null,Object? qrSecret = freezed,Object? session = freezed,}) {
  return _then(_KioskSyncDto(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,beaconMajor: null == beaconMajor ? _self.beaconMajor : beaconMajor // ignore: cast_nullable_to_non_nullable
as int,beaconSecret: null == beaconSecret ? _self.beaconSecret : beaconSecret // ignore: cast_nullable_to_non_nullable
as String,qrSecret: freezed == qrSecret ? _self.qrSecret : qrSecret // ignore: cast_nullable_to_non_nullable
as String?,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as KioskSessionDto?,
  ));
}

/// Create a copy of KioskSyncDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KioskSessionDtoCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $KioskSessionDtoCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
