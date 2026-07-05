// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_record_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceRecordDto {

 String get id;@JsonKey(name: 'student_id') String get studentId;@JsonKey(name: 'class_id') String get classId;@JsonKey(name: 'session_id') String get sessionId; String get method; String get status; String? get reason;@JsonKey(name: 'reason_code') String? get reasonCode;@JsonKey(name: 'reason_detail') String? get reasonDetail;@JsonKey(name: 'document_submitted') bool get documentSubmitted;@JsonKey(name: 'neis_excluded') bool get neisExcluded;@JsonKey(name: 'kiosk_device_id') String? get kioskDeviceId;@JsonKey(name: 'check_in_time') DateTime get checkInTime;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'updated_by') String? get updatedBy;
/// Create a copy of AttendanceRecordDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceRecordDtoCopyWith<AttendanceRecordDto> get copyWith => _$AttendanceRecordDtoCopyWithImpl<AttendanceRecordDto>(this as AttendanceRecordDto, _$identity);

  /// Serializes this AttendanceRecordDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceRecordDto&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.reasonDetail, reasonDetail) || other.reasonDetail == reasonDetail)&&(identical(other.documentSubmitted, documentSubmitted) || other.documentSubmitted == documentSubmitted)&&(identical(other.neisExcluded, neisExcluded) || other.neisExcluded == neisExcluded)&&(identical(other.kioskDeviceId, kioskDeviceId) || other.kioskDeviceId == kioskDeviceId)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,classId,sessionId,method,status,reason,reasonCode,reasonDetail,documentSubmitted,neisExcluded,kioskDeviceId,checkInTime,updatedAt,updatedBy);

@override
String toString() {
  return 'AttendanceRecordDto(id: $id, studentId: $studentId, classId: $classId, sessionId: $sessionId, method: $method, status: $status, reason: $reason, reasonCode: $reasonCode, reasonDetail: $reasonDetail, documentSubmitted: $documentSubmitted, neisExcluded: $neisExcluded, kioskDeviceId: $kioskDeviceId, checkInTime: $checkInTime, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $AttendanceRecordDtoCopyWith<$Res>  {
  factory $AttendanceRecordDtoCopyWith(AttendanceRecordDto value, $Res Function(AttendanceRecordDto) _then) = _$AttendanceRecordDtoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'student_id') String studentId,@JsonKey(name: 'class_id') String classId,@JsonKey(name: 'session_id') String sessionId, String method, String status, String? reason,@JsonKey(name: 'reason_code') String? reasonCode,@JsonKey(name: 'reason_detail') String? reasonDetail,@JsonKey(name: 'document_submitted') bool documentSubmitted,@JsonKey(name: 'neis_excluded') bool neisExcluded,@JsonKey(name: 'kiosk_device_id') String? kioskDeviceId,@JsonKey(name: 'check_in_time') DateTime checkInTime,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'updated_by') String? updatedBy
});




}
/// @nodoc
class _$AttendanceRecordDtoCopyWithImpl<$Res>
    implements $AttendanceRecordDtoCopyWith<$Res> {
  _$AttendanceRecordDtoCopyWithImpl(this._self, this._then);

  final AttendanceRecordDto _self;
  final $Res Function(AttendanceRecordDto) _then;

/// Create a copy of AttendanceRecordDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? classId = null,Object? sessionId = null,Object? method = null,Object? status = null,Object? reason = freezed,Object? reasonCode = freezed,Object? reasonDetail = freezed,Object? documentSubmitted = null,Object? neisExcluded = null,Object? kioskDeviceId = freezed,Object? checkInTime = null,Object? updatedAt = freezed,Object? updatedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,reasonDetail: freezed == reasonDetail ? _self.reasonDetail : reasonDetail // ignore: cast_nullable_to_non_nullable
as String?,documentSubmitted: null == documentSubmitted ? _self.documentSubmitted : documentSubmitted // ignore: cast_nullable_to_non_nullable
as bool,neisExcluded: null == neisExcluded ? _self.neisExcluded : neisExcluded // ignore: cast_nullable_to_non_nullable
as bool,kioskDeviceId: freezed == kioskDeviceId ? _self.kioskDeviceId : kioskDeviceId // ignore: cast_nullable_to_non_nullable
as String?,checkInTime: null == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceRecordDto].
extension AttendanceRecordDtoPatterns on AttendanceRecordDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceRecordDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceRecordDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceRecordDto value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceRecordDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceRecordDto value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceRecordDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'session_id')  String sessionId,  String method,  String status,  String? reason, @JsonKey(name: 'reason_code')  String? reasonCode, @JsonKey(name: 'reason_detail')  String? reasonDetail, @JsonKey(name: 'document_submitted')  bool documentSubmitted, @JsonKey(name: 'neis_excluded')  bool neisExcluded, @JsonKey(name: 'kiosk_device_id')  String? kioskDeviceId, @JsonKey(name: 'check_in_time')  DateTime checkInTime, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'updated_by')  String? updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceRecordDto() when $default != null:
return $default(_that.id,_that.studentId,_that.classId,_that.sessionId,_that.method,_that.status,_that.reason,_that.reasonCode,_that.reasonDetail,_that.documentSubmitted,_that.neisExcluded,_that.kioskDeviceId,_that.checkInTime,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'session_id')  String sessionId,  String method,  String status,  String? reason, @JsonKey(name: 'reason_code')  String? reasonCode, @JsonKey(name: 'reason_detail')  String? reasonDetail, @JsonKey(name: 'document_submitted')  bool documentSubmitted, @JsonKey(name: 'neis_excluded')  bool neisExcluded, @JsonKey(name: 'kiosk_device_id')  String? kioskDeviceId, @JsonKey(name: 'check_in_time')  DateTime checkInTime, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'updated_by')  String? updatedBy)  $default,) {final _that = this;
switch (_that) {
case _AttendanceRecordDto():
return $default(_that.id,_that.studentId,_that.classId,_that.sessionId,_that.method,_that.status,_that.reason,_that.reasonCode,_that.reasonDetail,_that.documentSubmitted,_that.neisExcluded,_that.kioskDeviceId,_that.checkInTime,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'student_id')  String studentId, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'session_id')  String sessionId,  String method,  String status,  String? reason, @JsonKey(name: 'reason_code')  String? reasonCode, @JsonKey(name: 'reason_detail')  String? reasonDetail, @JsonKey(name: 'document_submitted')  bool documentSubmitted, @JsonKey(name: 'neis_excluded')  bool neisExcluded, @JsonKey(name: 'kiosk_device_id')  String? kioskDeviceId, @JsonKey(name: 'check_in_time')  DateTime checkInTime, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'updated_by')  String? updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceRecordDto() when $default != null:
return $default(_that.id,_that.studentId,_that.classId,_that.sessionId,_that.method,_that.status,_that.reason,_that.reasonCode,_that.reasonDetail,_that.documentSubmitted,_that.neisExcluded,_that.kioskDeviceId,_that.checkInTime,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceRecordDto extends AttendanceRecordDto {
  const _AttendanceRecordDto({required this.id, @JsonKey(name: 'student_id') required this.studentId, @JsonKey(name: 'class_id') required this.classId, @JsonKey(name: 'session_id') required this.sessionId, required this.method, required this.status, this.reason, @JsonKey(name: 'reason_code') this.reasonCode, @JsonKey(name: 'reason_detail') this.reasonDetail, @JsonKey(name: 'document_submitted') this.documentSubmitted = false, @JsonKey(name: 'neis_excluded') this.neisExcluded = false, @JsonKey(name: 'kiosk_device_id') this.kioskDeviceId, @JsonKey(name: 'check_in_time') required this.checkInTime, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'updated_by') this.updatedBy}): super._();
  factory _AttendanceRecordDto.fromJson(Map<String, dynamic> json) => _$AttendanceRecordDtoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'student_id') final  String studentId;
@override@JsonKey(name: 'class_id') final  String classId;
@override@JsonKey(name: 'session_id') final  String sessionId;
@override final  String method;
@override final  String status;
@override final  String? reason;
@override@JsonKey(name: 'reason_code') final  String? reasonCode;
@override@JsonKey(name: 'reason_detail') final  String? reasonDetail;
@override@JsonKey(name: 'document_submitted') final  bool documentSubmitted;
@override@JsonKey(name: 'neis_excluded') final  bool neisExcluded;
@override@JsonKey(name: 'kiosk_device_id') final  String? kioskDeviceId;
@override@JsonKey(name: 'check_in_time') final  DateTime checkInTime;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'updated_by') final  String? updatedBy;

/// Create a copy of AttendanceRecordDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceRecordDtoCopyWith<_AttendanceRecordDto> get copyWith => __$AttendanceRecordDtoCopyWithImpl<_AttendanceRecordDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceRecordDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceRecordDto&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.reasonDetail, reasonDetail) || other.reasonDetail == reasonDetail)&&(identical(other.documentSubmitted, documentSubmitted) || other.documentSubmitted == documentSubmitted)&&(identical(other.neisExcluded, neisExcluded) || other.neisExcluded == neisExcluded)&&(identical(other.kioskDeviceId, kioskDeviceId) || other.kioskDeviceId == kioskDeviceId)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,classId,sessionId,method,status,reason,reasonCode,reasonDetail,documentSubmitted,neisExcluded,kioskDeviceId,checkInTime,updatedAt,updatedBy);

@override
String toString() {
  return 'AttendanceRecordDto(id: $id, studentId: $studentId, classId: $classId, sessionId: $sessionId, method: $method, status: $status, reason: $reason, reasonCode: $reasonCode, reasonDetail: $reasonDetail, documentSubmitted: $documentSubmitted, neisExcluded: $neisExcluded, kioskDeviceId: $kioskDeviceId, checkInTime: $checkInTime, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$AttendanceRecordDtoCopyWith<$Res> implements $AttendanceRecordDtoCopyWith<$Res> {
  factory _$AttendanceRecordDtoCopyWith(_AttendanceRecordDto value, $Res Function(_AttendanceRecordDto) _then) = __$AttendanceRecordDtoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'student_id') String studentId,@JsonKey(name: 'class_id') String classId,@JsonKey(name: 'session_id') String sessionId, String method, String status, String? reason,@JsonKey(name: 'reason_code') String? reasonCode,@JsonKey(name: 'reason_detail') String? reasonDetail,@JsonKey(name: 'document_submitted') bool documentSubmitted,@JsonKey(name: 'neis_excluded') bool neisExcluded,@JsonKey(name: 'kiosk_device_id') String? kioskDeviceId,@JsonKey(name: 'check_in_time') DateTime checkInTime,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'updated_by') String? updatedBy
});




}
/// @nodoc
class __$AttendanceRecordDtoCopyWithImpl<$Res>
    implements _$AttendanceRecordDtoCopyWith<$Res> {
  __$AttendanceRecordDtoCopyWithImpl(this._self, this._then);

  final _AttendanceRecordDto _self;
  final $Res Function(_AttendanceRecordDto) _then;

/// Create a copy of AttendanceRecordDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? classId = null,Object? sessionId = null,Object? method = null,Object? status = null,Object? reason = freezed,Object? reasonCode = freezed,Object? reasonDetail = freezed,Object? documentSubmitted = null,Object? neisExcluded = null,Object? kioskDeviceId = freezed,Object? checkInTime = null,Object? updatedAt = freezed,Object? updatedBy = freezed,}) {
  return _then(_AttendanceRecordDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,reasonDetail: freezed == reasonDetail ? _self.reasonDetail : reasonDetail // ignore: cast_nullable_to_non_nullable
as String?,documentSubmitted: null == documentSubmitted ? _self.documentSubmitted : documentSubmitted // ignore: cast_nullable_to_non_nullable
as bool,neisExcluded: null == neisExcluded ? _self.neisExcluded : neisExcluded // ignore: cast_nullable_to_non_nullable
as bool,kioskDeviceId: freezed == kioskDeviceId ? _self.kioskDeviceId : kioskDeviceId // ignore: cast_nullable_to_non_nullable
as String?,checkInTime: null == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
