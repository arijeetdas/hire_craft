class TemplateConfig {
  const TemplateConfig({
    required this.id,
    required this.name,
    required this.layoutType,
    required this.primaryColor,
    required this.accentColor,
    required this.fontPair,
    required this.density,
    required this.sectionOrder,
    required this.aiTone,
    required this.aiSummaryStyle,
    required this.aiBulletStyle,
    required this.aiKeywordBias,
  });

  final String id;
  final String name;
  final String layoutType;
  final int primaryColor;
  final int accentColor;
  final String fontPair;
  final double density;
  final List<String> sectionOrder;
  final String aiTone;
  final String aiSummaryStyle;
  final String aiBulletStyle;
  final String aiKeywordBias;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'layoutType': layoutType,
      'primaryColor': primaryColor,
      'accentColor': accentColor,
      'fontPair': fontPair,
      'density': density,
      'sectionOrder': sectionOrder,
      'aiTone': aiTone,
      'aiSummaryStyle': aiSummaryStyle,
      'aiBulletStyle': aiBulletStyle,
      'aiKeywordBias': aiKeywordBias,
    };
  }

  factory TemplateConfig.fromJson(Map<String, dynamic> json) {
    return TemplateConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      layoutType: json['layoutType'] as String,
      primaryColor: json['primaryColor'] as int,
      accentColor: json['accentColor'] as int,
      fontPair: json['fontPair'] as String,
      density: (json['density'] as num).toDouble(),
      sectionOrder: (json['sectionOrder'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      aiTone: json['aiTone'] as String? ?? 'professional concise',
      aiSummaryStyle: json['aiSummaryStyle'] as String? ?? '2-3 lines, role-aligned, ATS keyword rich',
      aiBulletStyle: json['aiBulletStyle'] as String? ?? 'one-line impact bullets with measurable outcomes',
      aiKeywordBias: json['aiKeywordBias'] as String? ?? 'balanced',
    );
  }

  static const defaults = <TemplateConfig>[
    TemplateConfig(
      id: 'modern-clean',
      name: 'Premium ATS (Sample)',
      layoutType: 'single_column',
      primaryColor: 0xFF0F172A,
      accentColor: 0xFF2563EB,
      fontPair: 'Helvetica/Helvetica-Bold',
      density: 1.02,
      sectionOrder: ['summary', 'experience', 'projects', 'education', 'skills'],
      aiTone: 'premium professional, concise, and high-credibility',
      aiSummaryStyle: '2-3 lines, executive-clear value proposition aligned to role',
      aiBulletStyle: 'impact-first bullets with metrics, scale, and ATS-friendly wording',
      aiKeywordBias: 'very high',
    ),
    TemplateConfig(
      id: 'classic-professional',
      name: 'Classic Professional',
      layoutType: 'single_column',
      primaryColor: 0xFF111827,
      accentColor: 0xFF6B7280,
      fontPair: 'Times-Roman/Times-Bold',
      density: 1.1,
      sectionOrder: ['summary', 'experience', 'education', 'projects', 'skills'],
      aiTone: 'classic formal and achievement-oriented',
      aiSummaryStyle: '3-4 lines, formal and executive-ready',
      aiBulletStyle: 'structured accomplishment bullets with clear business outcomes',
      aiKeywordBias: 'medium',
    ),
    TemplateConfig(
      id: 'compact-tech',
      name: 'Compact Tech',
      layoutType: 'two_column',
      primaryColor: 0xFF0F172A,
      accentColor: 0xFF14B8A6,
      fontPair: 'Courier/Courier-Bold',
      density: 0.85,
      sectionOrder: ['summary', 'skills', 'experience', 'projects', 'education'],
      aiTone: 'technical direct and ATS keyword-heavy',
      aiSummaryStyle: '2 lines, technical stack + domain emphasis',
      aiBulletStyle: 'dense ATS-ready bullets with technology and quantified results',
      aiKeywordBias: 'very high',
    ),
    TemplateConfig(
      id: 'executive-elegant',
      name: 'Executive Elegant',
      layoutType: 'single_column',
      primaryColor: 0xFF312E81,
      accentColor: 0xFF7C3AED,
      fontPair: 'Helvetica/Helvetica-Bold',
      density: 1.05,
      sectionOrder: ['summary', 'experience', 'skills', 'education', 'projects'],
      aiTone: 'executive strategic and leadership-focused',
      aiSummaryStyle: '3 lines, strategic leadership narrative with scale',
      aiBulletStyle: 'leadership/ownership bullets with org impact and KPIs',
      aiKeywordBias: 'medium',
    ),
    TemplateConfig(
      id: 'minimal-mono',
      name: 'Minimal Mono',
      layoutType: 'single_column',
      primaryColor: 0xFF111827,
      accentColor: 0xFF374151,
      fontPair: 'Courier/Courier-Bold',
      density: 0.9,
      sectionOrder: ['summary', 'projects', 'experience', 'skills', 'education'],
      aiTone: 'minimal crisp and no-fluff',
      aiSummaryStyle: '2 lines, sharp and plain-language',
      aiBulletStyle: 'short minimal bullets, no filler, measurable wherever possible',
      aiKeywordBias: 'balanced',
    ),
  ];
}
