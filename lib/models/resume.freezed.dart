// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resume.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Resume {

 String get id; String get userId; String get title; int get atsScore; DateTime get lastEdited; Map<String, dynamic> get content; List<ResumeVersion> get versions;
/// Create a copy of Resume
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResumeCopyWith<Resume> get copyWith => _$ResumeCopyWithImpl<Resume>(this as Resume, _$identity);

  /// Serializes this Resume to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Resume&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.atsScore, atsScore) || other.atsScore == atsScore)&&(identical(other.lastEdited, lastEdited) || other.lastEdited == lastEdited)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.versions, versions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,atsScore,lastEdited,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(versions));

@override
String toString() {
  return 'Resume(id: $id, userId: $userId, title: $title, atsScore: $atsScore, lastEdited: $lastEdited, content: $content, versions: $versions)';
}


}

/// @nodoc
abstract mixin class $ResumeCopyWith<$Res>  {
  factory $ResumeCopyWith(Resume value, $Res Function(Resume) _then) = _$ResumeCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String title, int atsScore, DateTime lastEdited, Map<String, dynamic> content, List<ResumeVersion> versions
});




}
/// @nodoc
class _$ResumeCopyWithImpl<$Res>
    implements $ResumeCopyWith<$Res> {
  _$ResumeCopyWithImpl(this._self, this._then);

  final Resume _self;
  final $Res Function(Resume) _then;

/// Create a copy of Resume
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? atsScore = null,Object? lastEdited = null,Object? content = null,Object? versions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,atsScore: null == atsScore ? _self.atsScore : atsScore // ignore: cast_nullable_to_non_nullable
as int,lastEdited: null == lastEdited ? _self.lastEdited : lastEdited // ignore: cast_nullable_to_non_nullable
as DateTime,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,versions: null == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as List<ResumeVersion>,
  ));
}

}


/// Adds pattern-matching-related methods to [Resume].
extension ResumePatterns on Resume {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Resume value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Resume() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Resume value)  $default,){
final _that = this;
switch (_that) {
case _Resume():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Resume value)?  $default,){
final _that = this;
switch (_that) {
case _Resume() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String title,  int atsScore,  DateTime lastEdited,  Map<String, dynamic> content,  List<ResumeVersion> versions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Resume() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.atsScore,_that.lastEdited,_that.content,_that.versions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String title,  int atsScore,  DateTime lastEdited,  Map<String, dynamic> content,  List<ResumeVersion> versions)  $default,) {final _that = this;
switch (_that) {
case _Resume():
return $default(_that.id,_that.userId,_that.title,_that.atsScore,_that.lastEdited,_that.content,_that.versions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String title,  int atsScore,  DateTime lastEdited,  Map<String, dynamic> content,  List<ResumeVersion> versions)?  $default,) {final _that = this;
switch (_that) {
case _Resume() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.atsScore,_that.lastEdited,_that.content,_that.versions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Resume implements Resume {
  const _Resume({required this.id, required this.userId, required this.title, this.atsScore = 0, required this.lastEdited, final  Map<String, dynamic> content = const <String, dynamic>{}, final  List<ResumeVersion> versions = const <ResumeVersion>[]}): _content = content,_versions = versions;
  factory _Resume.fromJson(Map<String, dynamic> json) => _$ResumeFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String title;
@override@JsonKey() final  int atsScore;
@override final  DateTime lastEdited;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

 final  List<ResumeVersion> _versions;
@override@JsonKey() List<ResumeVersion> get versions {
  if (_versions is EqualUnmodifiableListView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_versions);
}


/// Create a copy of Resume
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResumeCopyWith<_Resume> get copyWith => __$ResumeCopyWithImpl<_Resume>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResumeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Resume&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.atsScore, atsScore) || other.atsScore == atsScore)&&(identical(other.lastEdited, lastEdited) || other.lastEdited == lastEdited)&&const DeepCollectionEquality().equals(other._content, _content)&&const DeepCollectionEquality().equals(other._versions, _versions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,atsScore,lastEdited,const DeepCollectionEquality().hash(_content),const DeepCollectionEquality().hash(_versions));

@override
String toString() {
  return 'Resume(id: $id, userId: $userId, title: $title, atsScore: $atsScore, lastEdited: $lastEdited, content: $content, versions: $versions)';
}


}

/// @nodoc
abstract mixin class _$ResumeCopyWith<$Res> implements $ResumeCopyWith<$Res> {
  factory _$ResumeCopyWith(_Resume value, $Res Function(_Resume) _then) = __$ResumeCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String title, int atsScore, DateTime lastEdited, Map<String, dynamic> content, List<ResumeVersion> versions
});




}
/// @nodoc
class __$ResumeCopyWithImpl<$Res>
    implements _$ResumeCopyWith<$Res> {
  __$ResumeCopyWithImpl(this._self, this._then);

  final _Resume _self;
  final $Res Function(_Resume) _then;

/// Create a copy of Resume
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? atsScore = null,Object? lastEdited = null,Object? content = null,Object? versions = null,}) {
  return _then(_Resume(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,atsScore: null == atsScore ? _self.atsScore : atsScore // ignore: cast_nullable_to_non_nullable
as int,lastEdited: null == lastEdited ? _self.lastEdited : lastEdited // ignore: cast_nullable_to_non_nullable
as DateTime,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,versions: null == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as List<ResumeVersion>,
  ));
}


}


/// @nodoc
mixin _$ResumeVersion {

 String get id; String get resumeId; int get version; DateTime get lastEdited; Map<String, dynamic> get content;
/// Create a copy of ResumeVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResumeVersionCopyWith<ResumeVersion> get copyWith => _$ResumeVersionCopyWithImpl<ResumeVersion>(this as ResumeVersion, _$identity);

  /// Serializes this ResumeVersion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResumeVersion&&(identical(other.id, id) || other.id == id)&&(identical(other.resumeId, resumeId) || other.resumeId == resumeId)&&(identical(other.version, version) || other.version == version)&&(identical(other.lastEdited, lastEdited) || other.lastEdited == lastEdited)&&const DeepCollectionEquality().equals(other.content, content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,resumeId,version,lastEdited,const DeepCollectionEquality().hash(content));

@override
String toString() {
  return 'ResumeVersion(id: $id, resumeId: $resumeId, version: $version, lastEdited: $lastEdited, content: $content)';
}


}

/// @nodoc
abstract mixin class $ResumeVersionCopyWith<$Res>  {
  factory $ResumeVersionCopyWith(ResumeVersion value, $Res Function(ResumeVersion) _then) = _$ResumeVersionCopyWithImpl;
@useResult
$Res call({
 String id, String resumeId, int version, DateTime lastEdited, Map<String, dynamic> content
});




}
/// @nodoc
class _$ResumeVersionCopyWithImpl<$Res>
    implements $ResumeVersionCopyWith<$Res> {
  _$ResumeVersionCopyWithImpl(this._self, this._then);

  final ResumeVersion _self;
  final $Res Function(ResumeVersion) _then;

/// Create a copy of ResumeVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? resumeId = null,Object? version = null,Object? lastEdited = null,Object? content = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,resumeId: null == resumeId ? _self.resumeId : resumeId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,lastEdited: null == lastEdited ? _self.lastEdited : lastEdited // ignore: cast_nullable_to_non_nullable
as DateTime,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResumeVersion].
extension ResumeVersionPatterns on ResumeVersion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResumeVersion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResumeVersion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResumeVersion value)  $default,){
final _that = this;
switch (_that) {
case _ResumeVersion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResumeVersion value)?  $default,){
final _that = this;
switch (_that) {
case _ResumeVersion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String resumeId,  int version,  DateTime lastEdited,  Map<String, dynamic> content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResumeVersion() when $default != null:
return $default(_that.id,_that.resumeId,_that.version,_that.lastEdited,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String resumeId,  int version,  DateTime lastEdited,  Map<String, dynamic> content)  $default,) {final _that = this;
switch (_that) {
case _ResumeVersion():
return $default(_that.id,_that.resumeId,_that.version,_that.lastEdited,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String resumeId,  int version,  DateTime lastEdited,  Map<String, dynamic> content)?  $default,) {final _that = this;
switch (_that) {
case _ResumeVersion() when $default != null:
return $default(_that.id,_that.resumeId,_that.version,_that.lastEdited,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResumeVersion implements ResumeVersion {
  const _ResumeVersion({required this.id, required this.resumeId, required this.version, required this.lastEdited, final  Map<String, dynamic> content = const <String, dynamic>{}}): _content = content;
  factory _ResumeVersion.fromJson(Map<String, dynamic> json) => _$ResumeVersionFromJson(json);

@override final  String id;
@override final  String resumeId;
@override final  int version;
@override final  DateTime lastEdited;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}


/// Create a copy of ResumeVersion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResumeVersionCopyWith<_ResumeVersion> get copyWith => __$ResumeVersionCopyWithImpl<_ResumeVersion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResumeVersionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResumeVersion&&(identical(other.id, id) || other.id == id)&&(identical(other.resumeId, resumeId) || other.resumeId == resumeId)&&(identical(other.version, version) || other.version == version)&&(identical(other.lastEdited, lastEdited) || other.lastEdited == lastEdited)&&const DeepCollectionEquality().equals(other._content, _content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,resumeId,version,lastEdited,const DeepCollectionEquality().hash(_content));

@override
String toString() {
  return 'ResumeVersion(id: $id, resumeId: $resumeId, version: $version, lastEdited: $lastEdited, content: $content)';
}


}

/// @nodoc
abstract mixin class _$ResumeVersionCopyWith<$Res> implements $ResumeVersionCopyWith<$Res> {
  factory _$ResumeVersionCopyWith(_ResumeVersion value, $Res Function(_ResumeVersion) _then) = __$ResumeVersionCopyWithImpl;
@override @useResult
$Res call({
 String id, String resumeId, int version, DateTime lastEdited, Map<String, dynamic> content
});




}
/// @nodoc
class __$ResumeVersionCopyWithImpl<$Res>
    implements _$ResumeVersionCopyWith<$Res> {
  __$ResumeVersionCopyWithImpl(this._self, this._then);

  final _ResumeVersion _self;
  final $Res Function(_ResumeVersion) _then;

/// Create a copy of ResumeVersion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? resumeId = null,Object? version = null,Object? lastEdited = null,Object? content = null,}) {
  return _then(_ResumeVersion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,resumeId: null == resumeId ? _self.resumeId : resumeId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,lastEdited: null == lastEdited ? _self.lastEdited : lastEdited // ignore: cast_nullable_to_non_nullable
as DateTime,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
