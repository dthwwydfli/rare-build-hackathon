enum HelpResourceCategory {
  crisis,
  licensed,
  coach,
  tool;

  String get sectionTitle => switch (this) {
        crisis => 'crisis & helplines',
        licensed => 'licensed support',
        coach => 'recovery coaches & peer specialists',
        tool => 'self-serve tools',
      };
}

class ProfessionalResource {
  const ProfessionalResource({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.subtitle,
    this.phone,
    this.url,
    this.email,
    this.internalRoute,
    this.available24_7 = false,
  });

  final String id;
  final String name;
  final HelpResourceCategory category;
  final String description;
  final String? subtitle;
  final String? phone;
  final String? url;
  final String? email;
  final String? internalRoute;
  final bool available24_7;

  factory ProfessionalResource.fromJson(Map<String, dynamic> json) {
    return ProfessionalResource(
      id: json['id'] as String,
      name: json['name'] as String,
      category: HelpResourceCategory.values.byName(json['category'] as String),
      description: json['description'] as String,
      subtitle: json['subtitle'] as String?,
      phone: json['phone'] as String?,
      url: json['url'] as String?,
      email: json['email'] as String?,
      internalRoute: json['internalRoute'] as String?,
      available24_7: json['available24_7'] as bool? ?? false,
    );
  }
}
