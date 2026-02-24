// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Resume _$ResumeFromJson(Map<String, dynamic> json) => _Resume(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  atsScore: (json['atsScore'] as num?)?.toInt() ?? 0,
  lastEdited: DateTime.parse(json['lastEdited'] as String),
  content:
      json['content'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  versions:
      (json['versions'] as List<dynamic>?)
          ?.map((e) => ResumeVersion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResumeVersion>[],
);

Map<String, dynamic> _$ResumeToJson(_Resume instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'atsScore': instance.atsScore,
  'lastEdited': instance.lastEdited.toIso8601String(),
  'content': instance.content,
  'versions': instance.versions,
};

_ResumeVersion _$ResumeVersionFromJson(Map<String, dynamic> json) =>
    _ResumeVersion(
      id: json['id'] as String,
      resumeId: json['resumeId'] as String,
      version: (json['version'] as num).toInt(),
      lastEdited: DateTime.parse(json['lastEdited'] as String),
      content:
          json['content'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$ResumeVersionToJson(_ResumeVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'resumeId': instance.resumeId,
      'version': instance.version,
      'lastEdited': instance.lastEdited.toIso8601String(),
      'content': instance.content,
    };
