// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionDto {

 String get id;@JsonKey(name: 'class_id') String get classId;@JsonKey(name: 'teacher_id') String get teacherId; String get type; int? get period; DateTime get date; String get mode; String get status;@JsonKey(name: 'started_at') DateTime get startedAt;@JsonKey(name: 'ended_at') DateTime? get endedAt;@JsonKey(name: 'close_at') DateTime? get closeAt;@JsonKey(name: 'auto_late_after_minutes') int? get autoLateAfterMinutes;
/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionDtoCopyWith<SessionDto> get copyWith => _$SessionDtoCopyWithImpl<SessionDto>(this as SessionDto, _$identity);

  /// Serializes this SessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.type, type) || other.type == type)&&(identical(other.period, period) || other.period == period)&&(identical(other.date, date) || other.date == date)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.closeAt, closeAt) || other.closeAt == closeAt)&&(identical(other.autoLateAfterMinutes, autoLateAfterMinutes) || other.autoLateAfterMinutes == autoLateAfterMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,classId,teacherId,type,period,date,mode,status,startedAt,endedAt,closeAt,autoLateAfterMinutes);

@override
String toString() {
  return 'SessionDto(id: $id, classId: $classId, teacherId: $teacherId, type: $type, period: $period, date: $date, mode: $mode, status: $status, startedAt: $startedAt, endedAt: $endedAt, closeAt: $closeAt, autoLateAfterMinutes: $autoLateAfterMinutes)';
}


}

/// @nodoc
abstract mixin class $SessionDtoCopyWith<$Res>  {
  factory $SessionDtoCopyWith(SessionDto value, $Res Function(SessionDto) _then) = _$SessionDtoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'class_id') String classId,@JsonKey(name: 'teacher_id') String teacherId, String type, int? period, DateTime date, String mode, String status,@JsonKey(name: 'started_at') DateTime startedAt,@JsonKey(name: 'ended_at') DateTime? endedAt,@JsonKey(name: 'close_at') DateTime? closeAt,@JsonKey(name: 'auto_late_after_minutes') int? autoLateAfterMinutes
});




}
/// @nodoc
class _$SessionDtoCopyWithImpl<$Res>
    implements $SessionDtoCopyWith<$Res> {
  _$SessionDtoCopyWithImpl(this._self, this._then);

  final SessionDto _self;
  final $Res Function(SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? classId = null,Object? teacherId = null,Object? type = null,Object? period = freezed,Object? date = null,Object? mode = null,Object? status = null,Object? startedAt = null,Object? endedAt = freezed,Object? closeAt = freezed,Object? autoLateAfterMinutes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closeAt: freezed == closeAt ? _self.closeAt : closeAt // ignore: cast_nullable_to_non_nullable
as DateTime?,autoLateAfterMinutes: freezed == autoLateAfterMinutes ? _self.autoLateAfterMinutes : autoLateAfterMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionDto].
extension SessionDtoPatterns on SessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionDto value)  $default,){
final _that = this;
switch (_that) {
case _SessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'teacher_id')  String teacherId,  String type,  int? period,  DateTime date,  String mode,  String status, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'ended_at')  DateTime? endedAt, @JsonKey(name: 'close_at')  DateTime? closeAt, @JsonKey(name: 'auto_late_after_minutes')  int? autoLateAfterMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.id,_that.classId,_that.teacherId,_that.type,_that.period,_that.date,_that.mode,_that.status,_that.startedAt,_that.endedAt,_that.closeAt,_that.autoLateAfterMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'teacher_id')  String teacherId,  String type,  int? period,  DateTime date,  String mode,  String status, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'ended_at')  DateTime? endedAt, @JsonKey(name: 'close_at')  DateTime? closeAt, @JsonKey(name: 'auto_late_after_minutes')  int? autoLateAfterMinutes)  $default,) {final _that = this;
switch (_that) {
case _SessionDto():
return $default(_that.id,_that.classId,_that.teacherId,_that.type,_that.period,_that.date,_that.mode,_that.status,_that.startedAt,_that.endedAt,_that.closeAt,_that.autoLateAfterMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'class_id')  String classId, @JsonKey(name: 'teacher_id')  String teacherId,  String type,  int? period,  DateTime date,  String mode,  String status, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'ended_at')  DateTime? endedAt, @JsonKey(name: 'close_at')  DateTime? closeAt, @JsonKey(name: 'auto_late_after_minutes')  int? autoLateAfterMinutes)?  $default,) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.id,_that.classId,_that.teacherId,_that.type,_that.period,_that.date,_that.mode,_that.status,_that.startedAt,_that.endedAt,_that.closeAt,_that.autoLateAfterMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionDto extends SessionDto {
  const _SessionDto({required this.id, @JsonKey(name: 'class_id') required this.classId, @JsonKey(name: 'teacher_id') required this.teacherId, required this.type, this.period, required this.date, required this.mode, required this.status, @JsonKey(name: 'started_at') required this.startedAt, @JsonKey(name: 'ended_at') this.endedAt, @JsonKey(name: 'close_at') this.closeAt, @JsonKey(name: 'auto_late_after_minutes') this.autoLateAfterMinutes}): super._();
  factory _SessionDto.fromJson(Map<String, dynamic> json) => _$SessionDtoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'class_id') final  String classId;
@override@JsonKey(name: 'teacher_id') final  String teacherId;
@override final  String type;
@override final  int? period;
@override final  DateTime date;
@override final  String mode;
@override final  String status;
@override@JsonKey(name: 'started_at') final  DateTime startedAt;
@override@JsonKey(name: 'ended_at') final  DateTime? endedAt;
@override@JsonKey(name: 'close_at') final  DateTime? closeAt;
@override@JsonKey(name: 'auto_late_after_minutes') final  int? autoLateAfterMinutes;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionDtoCopyWith<_SessionDto> get copyWith => __$SessionDtoCopyWithImpl<_SessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.type, type) || other.type == type)&&(identical(other.period, period) || other.period == period)&&(identical(other.date, date) || other.date == date)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.closeAt, closeAt) || other.closeAt == closeAt)&&(identical(other.autoLateAfterMinutes, autoLateAfterMinutes) || other.autoLateAfterMinutes == autoLateAfterMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,classId,teacherId,type,period,date,mode,status,startedAt,endedAt,closeAt,autoLateAfterMinutes);

@override
String toString() {
  return 'SessionDto(id: $id, classId: $classId, teacherId: $teacherId, type: $type, period: $period, date: $date, mode: $mode, status: $status, startedAt: $startedAt, endedAt: $endedAt, closeAt: $closeAt, autoLateAfterMinutes: $autoLateAfterMinutes)';
}


}

/// @nodoc
abstract mixin class _$SessionDtoCopyWith<$Res> implements $SessionDtoCopyWith<$Res> {
  factory _$SessionDtoCopyWith(_SessionDto value, $Res Function(_SessionDto) _then) = __$SessionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'class_id') String classId,@JsonKey(name: 'teacher_id') String teacherId, String type, int? period, DateTime date, String mode, String status,@JsonKey(name: 'started_at') DateTime startedAt,@JsonKey(name: 'ended_at') DateTime? endedAt,@JsonKey(name: 'close_at') DateTime? closeAt,@JsonKey(name: 'auto_late_after_minutes') int? autoLateAfterMinutes
});




}
/// @nodoc
class __$SessionDtoCopyWithImpl<$Res>
    implements _$SessionDtoCopyWith<$Res> {
  __$SessionDtoCopyWithImpl(this._self, this._then);

  final _SessionDto _self;
  final $Res Function(_SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? classId = null,Object? teacherId = null,Object? type = null,Object? period = freezed,Object? date = null,Object? mode = null,Object? status = null,Object? startedAt = null,Object? endedAt = freezed,Object? closeAt = freezed,Object? autoLateAfterMinutes = freezed,}) {
  return _then(_SessionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closeAt: freezed == closeAt ? _self.closeAt : closeAt // ignore: cast_nullable_to_non_nullable
as DateTime?,autoLateAfterMinutes: freezed == autoLateAfterMinutes ? _self.autoLateAfterMinutes : autoLateAfterMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
