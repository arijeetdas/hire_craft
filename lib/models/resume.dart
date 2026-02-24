import 'package:freezed_annotation/freezed_annotation.dart';

part 'resume.freezed.dart';
part 'resume.g.dart';

@freezed
abstract class Resume with _$Resume {
  const factory Resume({
    required String id,
    required String userId,
    required String title,
    @Default(0) int atsScore,
    required DateTime lastEdited,
    @Default(<String, dynamic>{}) Map<String, dynamic> content,
    @Default(<ResumeVersion>[]) List<ResumeVersion> versions,
  }) = _Resume;

  factory Resume.fromJson(Map<String, dynamic> json) => _$ResumeFromJson(json);
}

@freezed
abstract class ResumeVersion with _$ResumeVersion {
  const factory ResumeVersion({
    required String id,
    required String resumeId,
    required int version,
    required DateTime lastEdited,
    @Default(<String, dynamic>{}) Map<String, dynamic> content,
  }) = _ResumeVersion;

  factory ResumeVersion.fromJson(Map<String, dynamic> json) =>
      _$ResumeVersionFromJson(json);
}
