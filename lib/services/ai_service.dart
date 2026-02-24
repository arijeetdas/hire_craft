import 'dart:convert';
import 'dart:typed_data';

import 'package:hire_craft/core/constants/ai_config.dart';
import 'package:hire_craft/core/constants/supabase_config.dart';
import 'package:hire_craft/services/supabase_service.dart';
import 'package:http/http.dart' as http;

class AiAtsInspectionResult {
	const AiAtsInspectionResult({
		required this.totalScore,
		required this.keywordScore,
		required this.bulletScore,
		required this.lengthScore,
		required this.readabilityScore,
		required this.missingKeywords,
		required this.suggestions,
	});

	final int totalScore;
	final int keywordScore;
	final int bulletScore;
	final int lengthScore;
	final int readabilityScore;
	final List<String> missingKeywords;
	final List<String> suggestions;
}

class AiService {
	AiService._();

	static final AiService instance = AiService._();

	Future<List<String>> generateResume({
		required Map<String, dynamic> structuredResumeData,
		String? careerLevel,
		String? targetRole,
		String? industry,
		String? tone,
		String? jobDescription,
		bool strongRewrite = false,
	}) async {
		if (AiConfig.backendUrl.isEmpty) {
			throw StateError(
				'AI_BACKEND_URL is not configured. Provide it using --dart-define.',
			);
		}

		final uri = Uri.parse('${AiConfig.backendUrl}${AiConfig.generatePath}');
		final response = await _postWithAuthRetry(
			uri,
			{
				'resumeData': structuredResumeData,
				'career_level': careerLevel,
				'target_role': targetRole,
				'industry': industry,
				'tone': tone,
				'job_description_or_null': jobDescription,
				'strong_rewrite': strongRewrite,
			},
		);

		if (response.statusCode < 200 || response.statusCode >= 300) {
			throw Exception(
				'AI generation failed: ${response.statusCode} ${response.body}',
			);
		}

		final decoded = jsonDecode(response.body);
		final variations = _extractVariations(decoded);

		if (variations.length < 3) {
			throw Exception('AI response must include 3 resume variations.');
		}

		return variations.take(3).toList();
	}

	Future<List<String>> optimizeResume({
		required Map<String, dynamic> structuredResumeData,
		required String jobDescription,
		String? careerLevel,
		String? targetRole,
		String? industry,
		String? tone,
	}) async {
		if (AiConfig.backendUrl.isEmpty) {
			throw StateError(
				'AI_BACKEND_URL is not configured. Provide it using --dart-define.',
			);
		}

		final uri = Uri.parse('${AiConfig.backendUrl}${AiConfig.optimizePath}');
		final response = await _postWithAuthRetry(
			uri,
			{
				'resumeData': structuredResumeData,
				'jobDescription': jobDescription,
				'career_level': careerLevel,
				'target_role': targetRole,
				'industry': industry,
				'tone': tone,
			},
		);

		if (response.statusCode < 200 || response.statusCode >= 300) {
			throw Exception('AI optimization failed: ${response.statusCode}');
		}

		final decoded = jsonDecode(response.body);
		if (decoded is List) {
			return decoded.map((e) => e.toString()).toList();
		}
		if (decoded is Map<String, dynamic>) {
			final suggestions = decoded['suggestions'];
			if (suggestions is List) {
				return suggestions.map((e) => e.toString()).toList();
			}
		}

		throw Exception('Invalid optimize response format.');
	}

	Future<Uint8List?> generateResumeImage({
		required Map<String, dynamic> structuredResumeData,
		String? careerLevel,
		String? targetRole,
		String? industry,
		String? tone,
		String? jobDescription,
	}) async {
		if (AiConfig.backendUrl.isEmpty) {
			return null;
		}

		final uri = Uri.parse('${AiConfig.backendUrl}${AiConfig.generatePath}');
		final response = await _postWithAuthRetry(
			uri,
			{
				'resumeData': structuredResumeData,
				'career_level': careerLevel,
				'target_role': targetRole,
				'industry': industry,
				'tone': tone,
				'job_description_or_null': jobDescription,
			},
		);

		if (response.statusCode < 200 || response.statusCode >= 300) {
			return null;
		}

		final decoded = jsonDecode(response.body);
		if (decoded is Map<String, dynamic>) {
			final imageBase64 = decoded['imageBase64'] as String?;
			if (imageBase64 != null && imageBase64.isNotEmpty) {
				final normalized = imageBase64.contains(',')
						? imageBase64.split(',').last
						: imageBase64;
				return base64Decode(normalized);
			}
		}

		return null;
	}

	Future<AiAtsInspectionResult> inspectAts({
		required Map<String, dynamic> structuredResumeData,
		required String resumeText,
		required List<String> targetKeywords,
		String? careerLevel,
		String? targetRole,
		String? industry,
		String? tone,
	}) async {
		if (AiConfig.backendUrl.isEmpty) {
			throw StateError(
				'AI_BACKEND_URL is not configured. Provide it using --dart-define.',
			);
		}

		final uri = Uri.parse('${AiConfig.backendUrl}${AiConfig.atsPath}');
		final response = await _postWithAuthRetry(
			uri,
			{
				'resumeData': structuredResumeData,
				'resume_text': resumeText,
				'target_keywords': targetKeywords,
				'career_level': careerLevel,
				'target_role': targetRole,
				'industry': industry,
				'tone': tone,
			},
		);

		if (response.statusCode < 200 || response.statusCode >= 300) {
			throw Exception(
				'AI ATS inspection failed: ${response.statusCode} ${response.body}',
			);
		}

		final decoded = jsonDecode(response.body);
		if (decoded is! Map<String, dynamic>) {
			throw Exception('Invalid AI ATS response format.');
		}

		int toScore(dynamic value, {required int fallback}) {
			if (value is num) {
				return value.round().clamp(0, 100);
			}
			if (value is String) {
				final parsed = num.tryParse(value.trim());
				if (parsed != null) {
					return parsed.round().clamp(0, 100);
				}
			}
			return fallback;
		}

		List<String> toList(dynamic value) {
			if (value is List) {
				return value
						.map((e) => e.toString().trim())
						.where((e) => e.isNotEmpty)
						.toList();
			}
			return const <String>[];
		}

		final suggestions = toList(decoded['suggestions']);
		if (suggestions.isEmpty) {
			throw Exception('AI ATS inspection returned no suggestions.');
		}

		return AiAtsInspectionResult(
			totalScore: toScore(decoded['total_score'], fallback: 60),
			keywordScore: toScore(decoded['keyword_score'], fallback: 24),
			bulletScore: toScore(decoded['bullet_score'], fallback: 12),
			lengthScore: toScore(decoded['length_score'], fallback: 12),
			readabilityScore: toScore(decoded['readability_score'], fallback: 12),
			missingKeywords: toList(decoded['missing_keywords']),
			suggestions: suggestions,
		);
	}

	Future<http.Response> _postWithAuthRetry(
		Uri uri,
		Map<String, dynamic> payload,
	) async {
		final sessionToken = SupabaseService.instance.currentSession?.accessToken;
		final firstBearer = (sessionToken != null && sessionToken.isNotEmpty)
				? sessionToken
				: SupabaseConfig.anonKey;

		var response = await http.post(
			uri,
			headers: _requestHeaders(firstBearer),
			body: jsonEncode(payload),
		);

		final usingSession =
				sessionToken != null && sessionToken.isNotEmpty && firstBearer == sessionToken;
		if (response.statusCode == 401 && usingSession) {
			response = await http.post(
				uri,
				headers: _requestHeaders(SupabaseConfig.anonKey),
				body: jsonEncode(payload),
			);
		}

		return response;
	}

	Map<String, String> _requestHeaders(String bearerToken) {

		return <String, String>{
			'Content-Type': 'application/json',
			'apikey': SupabaseConfig.anonKey,
			'Authorization': 'Bearer $bearerToken',
		};
	}

	List<String> _extractVariations(dynamic decoded) {
		if (decoded is List) {
			return decoded.map((e) => _toJsonString(e)).toList();
		}

		if (decoded is Map<String, dynamic>) {
			final raw = decoded['variations'];
			if (raw is List) {
				return raw.map((e) => _toJsonString(e)).toList();
			}
		}

		throw Exception('Invalid AI response format.');
	}

	String _toJsonString(dynamic value) {
		if (value is String) {
			return value;
		}
		return jsonEncode(value);
	}
}