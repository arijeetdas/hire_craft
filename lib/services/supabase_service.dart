import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hire_craft/core/constants/supabase_config.dart';
import 'package:hire_craft/models/resume.dart';
import 'dart:typed_data';

class UserProfile {
  const UserProfile({required this.id, required this.onboardingCompleted});

  final String id;
  final bool onboardingCompleted;
}

class ResumeVersionEntry {
  const ResumeVersionEntry({
    required this.id,
    required this.version,
    required this.lastEdited,
  });

  final int id;
  final int version;
  final DateTime lastEdited;
}

class ProfilePromptContext {
  const ProfilePromptContext({
    required this.careerLevel,
    required this.targetRole,
    required this.industry,
    required this.writingStyle,
  });

  final String? careerLevel;
  final String? targetRole;
  final String? industry;
  final String? writingStyle;
}

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  SupabaseClient get database => client;
  SupabaseStorageClient get storage => client.storage;

  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_isInitialized) {
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _isInitialized = true;
  }

  Future<void> initializeFromEnvironment() async {
    const url = SupabaseConfig.url;
    const anonKey = SupabaseConfig.anonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided using --dart-define.',
      );
    }

    await initialize(url: url, anonKey: anonKey);
  }

  Session? get currentSession => auth.currentSession;
  User? get currentUser => auth.currentUser;

  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  Future<UserProfile?> loadUserProfile(String userId) async {
    final response = await database
        .from('profiles')
        .select('id, onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final data = response;
    return UserProfile(
      id: data['id'] as String? ?? userId,
      onboardingCompleted: data['onboarding_completed'] as bool? ?? false,
    );
  }

  Future<void> createProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      await database.from('profiles').upsert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'onboarding_completed': false,
      });
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('full_name') && message.contains('does not exist')) {
        await database.from('profiles').upsert({
          'id': userId,
          'email': email,
          'name': fullName,
          'onboarding_completed': false,
        });
        return;
      }
      rethrow;
    }
  }

  Future<void> saveOnboardingProfile({
    required String userId,
    required String careerLevel,
    required String targetRole,
    required String industry,
    required String writingStyle,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      'career_level': careerLevel,
      'target_role': targetRole,
      'industry': industry,
      'writing_style': writingStyle,
      'onboarding_completed': true,
    };

    try {
      await database.from('profiles').upsert(payload);
      return;
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      final missingOnboardingColumns =
          message.contains('does not exist') &&
          (message.contains('career_level') ||
              message.contains('target_role') ||
              message.contains('industry') ||
              message.contains('writing_style'));

      if (missingOnboardingColumns) {
        final fallbackPayload = <String, dynamic>{
          'id': userId,
          'onboarding_completed': true,
        };
        final email = currentUser?.email;
        if (email != null && email.isNotEmpty) {
          fallbackPayload['email'] = email;
        }

        await database.from('profiles').upsert(fallbackPayload);
        return;
      }

      final emailNullViolation =
          message.contains('null value in column "email"') ||
          message.contains("null value in column 'email'");
      if (emailNullViolation) {
        final email = currentUser?.email;
        if (email != null && email.isNotEmpty) {
          await database.from('profiles').upsert({...payload, 'email': email});
          return;
        }
      }

      rethrow;
    }
  }

  Future<ProfilePromptContext?> fetchProfilePromptContext(String userId) async {
    final response = await database
        .from('profiles')
        .select('career_level, target_role, industry, writing_style')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final data = response;
    return ProfilePromptContext(
      careerLevel: data['career_level'] as String?,
      targetRole: data['target_role'] as String?,
      industry: data['industry'] as String?,
      writingStyle: data['writing_style'] as String?,
    );
  }

  Future<List<Resume>> fetchUserResumes(String userId) async {
    final response = await database
        .from('resumes')
        .select('id, user_id, title, ats_score, last_edited_at, content')
        .eq('user_id', userId)
        .order('last_edited_at', ascending: false);

    return (response as List<dynamic>).map((item) {
      final row = item as Map<String, dynamic>;
      return Resume(
        id: row['id'] as String,
        userId: row['user_id'] as String? ?? userId,
        title: row['title'] as String? ?? 'Untitled Resume',
        atsScore: row['ats_score'] as int? ?? 0,
        lastEdited:
            DateTime.tryParse(row['last_edited_at'] as String? ?? '') ??
            DateTime.now(),
        content:
            (row['content'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      );
    }).toList();
  }

  Stream<List<Resume>> watchUserResumes(String userId) {
    return database
        .from('resumes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('last_edited_at', ascending: false)
        .map((rows) {
          return rows.map((row) {
            return Resume(
              id: row['id'] as String,
              userId: row['user_id'] as String? ?? userId,
              title: row['title'] as String? ?? 'Untitled Resume',
              atsScore: row['ats_score'] as int? ?? 0,
              lastEdited:
                  DateTime.tryParse(row['last_edited_at'] as String? ?? '') ??
                  DateTime.now(),
              content:
                  (row['content'] as Map<String, dynamic>?) ??
                  const <String, dynamic>{},
            );
          }).toList();
        });
  }

  Future<Resume?> fetchResumeById(String resumeId) async {
    final response = await database
        .from('resumes')
        .select('id, user_id, title, ats_score, last_edited_at, content')
        .eq('id', resumeId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final row = response;
    final fallbackUserId = currentUser?.id ?? '';
    return Resume(
      id: _asString(row['id']) ?? resumeId,
      userId: _asString(row['user_id']) ?? fallbackUserId,
      title: _asString(row['title']) ?? 'Untitled Resume',
      atsScore: row['ats_score'] as int? ?? 0,
      lastEdited: _asDateTime(row['last_edited_at']) ?? DateTime.now(),
      content:
          (row['content'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  Future<Resume?> fetchLatestUserResume(String userId) async {
    final response = await database
        .from('resumes')
        .select('id, user_id, title, ats_score, last_edited_at, content')
        .eq('user_id', userId)
        .order('last_edited_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final row = response;
    return Resume(
      id: _asString(row['id']) ?? '',
      userId: _asString(row['user_id']) ?? userId,
      title: _asString(row['title']) ?? 'Untitled Resume',
      atsScore: row['ats_score'] as int? ?? 0,
      lastEdited: _asDateTime(row['last_edited_at']) ?? DateTime.now(),
      content:
          (row['content'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  Future<String> uploadResumePdf({
    required String userId,
    required String resumeId,
    required Uint8List pdfBytes,
  }) async {
    final path =
        'resumes/$userId/$resumeId-${DateTime.now().millisecondsSinceEpoch}.pdf';
    await storage
        .from('resume-pdfs')
        .uploadBinary(
          path,
          pdfBytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    return storage.from('resume-pdfs').getPublicUrl(path);
  }

  Future<String> uploadGeneratedResumeImage({
    required String userId,
    required String resumeId,
    required Uint8List imageBytes,
  }) async {
    final path =
        'generated/$userId/$resumeId-${DateTime.now().millisecondsSinceEpoch}.png';
    await storage
        .from('resume-pdfs')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );

    return storage.from('resume-pdfs').getPublicUrl(path);
  }

  Future<void> upsertResume({
    required Resume resume,
    bool createVersionSnapshot = false,
  }) async {
    await database.from('resumes').upsert({
      'id': resume.id,
      'user_id': resume.userId,
      'title': resume.title,
      'ats_score': resume.atsScore,
      'last_edited_at': resume.lastEdited.toUtc().toIso8601String(),
      'content': resume.content,
    }, onConflict: 'id');

    if (!createVersionSnapshot) {
      return;
    }

    final latestVersionRow = await database
        .from('resume_versions')
        .select('version')
        .eq('resume_id', resume.id)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();

    final nextVersion = ((latestVersionRow?['version'] as int?) ?? 0) + 1;
    await database.from('resume_versions').insert({
      'resume_id': resume.id,
      'version': nextVersion,
      'content': resume.content,
      'last_edited_at': resume.lastEdited.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteResumeById(String resumeId) async {
    await database.from('resumes').delete().eq('id', resumeId);
  }

  Future<List<ResumeVersionEntry>> fetchResumeVersions(String resumeId) async {
    final response = await database
        .from('resume_versions')
        .select('id, version, last_edited_at')
        .eq('resume_id', resumeId)
        .order('version', ascending: false);

    return (response as List<dynamic>).map((item) {
      final row = item as Map<String, dynamic>;
      return ResumeVersionEntry(
        id: row['id'] as int,
        version: row['version'] as int? ?? 0,
        lastEdited:
            DateTime.tryParse(row['last_edited_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> deleteResumeVersion(int versionId) async {
    await database.from('resume_versions').delete().eq('id', versionId);
  }

  Future<void> updateResumeAtsScore({
    required String resumeId,
    required int atsScore,
  }) async {
    await database
        .from('resumes')
        .update({
          'ats_score': atsScore,
          'last_edited_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', resumeId);
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final converted = value.toString().trim();
    return converted.isEmpty ? null : converted;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    final parsed = DateTime.tryParse(value.toString());
    return parsed;
  }
}
