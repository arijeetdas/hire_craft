import 'dart:math';

class AtsAnalysisResult {
	const AtsAnalysisResult({
		required this.totalScore,
		required this.keywordScore,
		required this.bulletScore,
		required this.lengthScore,
		required this.readabilityScore,
		required this.missingKeywords,
		required this.suggestions,
		required this.wordCount,
		required this.readabilityRaw,
	});

	final int totalScore;
	final int keywordScore;
	final int bulletScore;
	final int lengthScore;
	final int readabilityScore;
	final List<String> missingKeywords;
	final List<String> suggestions;
	final int wordCount;
	final double readabilityRaw;
}

class AtsService {
	static const _strengthVerbs = <String>{
		'achieved',
		'built',
		'created',
		'designed',
		'developed',
		'drove',
		'enhanced',
		'implemented',
		'improved',
		'increased',
		'launched',
		'led',
		'managed',
		'optimized',
		'reduced',
		'scaled',
		'streamlined',
	};

	AtsAnalysisResult scoreResume({
		required String resumeText,
		required List<String> targetKeywords,
	}) {
		final normalized = resumeText.toLowerCase();
		final words = _extractWords(normalized);
		final wordCount = words.length;

		final cleanedKeywords = targetKeywords
				.map((k) => k.trim().toLowerCase())
				.where((k) => k.isNotEmpty)
				.toList();

		final keywordMentions = cleanedKeywords
				.map((keyword) => _countKeyword(normalized, keyword))
				.fold<int>(0, (sum, value) => sum + value);

		final foundKeywords = cleanedKeywords
				.where((keyword) => _countKeyword(normalized, keyword) > 0)
				.toList();
		final missingKeywords = cleanedKeywords
				.where((keyword) => !foundKeywords.contains(keyword))
				.toList();

		final density = wordCount == 0 ? 0.0 : keywordMentions / wordCount;
		final densityScore = ((density / 0.035) * 16).clamp(0, 16).toDouble();
		final coverageScore = cleanedKeywords.isEmpty
				? 16.0
				: (foundKeywords.length / cleanedKeywords.length) * 16;
		final keywordPresenceBonus = foundKeywords.length >= 8
				? 8
				: foundKeywords.length >= 5
				? 5
				: foundKeywords.length >= 3
				? 3
				: 0;
		final keywordScore =
				(densityScore + coverageScore + keywordPresenceBonus).round().clamp(0, 40);

		final bulletScore = _bulletStrengthScore(resumeText);
		final lengthScore = _lengthRuleScore(wordCount);

		final readabilityRaw = _fleschReadingEase(resumeText);
		final readabilityScore = _readabilityScore(readabilityRaw);

		final totalScore =
				(keywordScore + bulletScore + lengthScore + readabilityScore)
						.clamp(0, 100);

		final suggestions = _buildSuggestions(
			missingKeywords: missingKeywords,
			bulletScore: bulletScore,
			wordCount: wordCount,
			readabilityRaw: readabilityRaw,
			keywordScore: keywordScore,
		);

		return AtsAnalysisResult(
			totalScore: totalScore,
			keywordScore: keywordScore,
			bulletScore: bulletScore,
			lengthScore: lengthScore,
			readabilityScore: readabilityScore,
			missingKeywords: missingKeywords,
			suggestions: suggestions,
			wordCount: wordCount,
			readabilityRaw: readabilityRaw,
		);
	}

	int _bulletStrengthScore(String text) {
		final lines = text
				.split(RegExp(r'\r?\n'))
				.map((line) => line.trim())
				.where((line) => line.isNotEmpty)
				.toList();
		final bulletLines = lines
				.where((line) => RegExp(r'^[-•*]').hasMatch(line))
				.toList();

		if (bulletLines.isEmpty) {
			return 6;
		}

		final strong = bulletLines.where((line) {
			final cleaned = line.replaceFirst(RegExp(r'^[-•*]\s*'), '').toLowerCase();
			final firstWord = cleaned.split(RegExp(r'\s+')).firstOrNull ?? '';
			return _strengthVerbs.contains(firstWord);
		}).length;

		final quantified = bulletLines.where((line) {
			return RegExp(r'\d|%|\$|kpi|roi|revenue|latency|uptime', caseSensitive: false)
					.hasMatch(line);
		}).length;

		final strengthRatio = strong / bulletLines.length;
		final quantifiedRatio = quantified / bulletLines.length;
		final score = (strengthRatio * 12) + (quantifiedRatio * 8);
		return score.round().clamp(0, 20);
	}

	int _lengthRuleScore(int words) {
		if (words < 200) {
			return 4;
		}
		if (words < 350) {
			return 10;
		}
		if (words <= 900) {
			return 20;
		}
		if (words <= 1200) {
			return 12;
		}
		return 6;
	}

	int _readabilityScore(double raw) {
		if (raw >= 50 && raw <= 75) {
			return 20;
		}
		final distance = min((raw - 62.5).abs(), 62.5);
		return max(0, (20 - (distance / 62.5) * 20).round());
	}

	double _fleschReadingEase(String text) {
		final sentences = text
				.split(RegExp(r'[.!?]+'))
				.map((s) => s.trim())
				.where((s) => s.isNotEmpty)
				.length;
		final words = _extractWords(text.toLowerCase());
		if (words.isEmpty || sentences == 0) {
			return 0;
		}

		final syllables = words.fold<int>(0, (sum, w) => sum + _countSyllables(w));
		final wordsPerSentence = words.length / sentences;
		final syllablesPerWord = syllables / words.length;
		return 206.835 - (1.015 * wordsPerSentence) - (84.6 * syllablesPerWord);
	}

	int _countKeyword(String text, String keyword) {
		final escaped = RegExp.escape(keyword);
		final regex = RegExp('\\b$escaped\\b');
		return regex.allMatches(text).length;
	}

	List<String> _extractWords(String text) {
		return RegExp(r'[a-zA-Z]+')
				.allMatches(text)
				.map((m) => m.group(0) ?? '')
				.where((w) => w.isNotEmpty)
				.toList();
	}

	int _countSyllables(String word) {
		final cleaned = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
		if (cleaned.isEmpty) {
			return 1;
		}
		final groups = RegExp(r'[aeiouy]+').allMatches(cleaned).length;
		final silentE = cleaned.endsWith('e') && groups > 1 ? 1 : 0;
		return max(1, groups - silentE);
	}

	List<String> _buildSuggestions({
		required List<String> missingKeywords,
		required int bulletScore,
		required int wordCount,
		required double readabilityRaw,
		required int keywordScore,
	}) {
		final suggestions = <String>[];

		if (missingKeywords.isNotEmpty) {
			suggestions.add(
				'Add missing keywords: ${missingKeywords.take(6).join(', ')}.',
			);
		}
		if (keywordScore < 24) {
			suggestions.add(
				'Use target role terminology naturally in summary, experience, and skills sections.',
			);
		}
		if (bulletScore < 12) {
			suggestions.add(
				'Start bullet points with strong action verbs and include measurable outcomes.',
			);
		}
		if (wordCount < 350) {
			suggestions.add('Increase resume detail to at least 350 words.');
		} else if (wordCount > 900) {
			suggestions.add('Trim resume content to under 900 words.');
		}
		if (readabilityRaw < 45) {
			suggestions.add(
				'Simplify long sentences and reduce complex phrasing to improve readability.',
			);
		}

		if (suggestions.isEmpty) {
			suggestions.add('Great work. Fine-tune achievements with more metrics.');
		}

		return suggestions;
	}
}

extension on List<String> {
	String? get firstOrNull => isEmpty ? null : first;
}