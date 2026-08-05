class FundamentalMetric {
  final String name;
  final String value;
  final String? description;

  FundamentalMetric({
    required this.name,
    required this.value,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'description': description ?? '',
  };
}

class TechnicalMetric {
  final String name;
  final String value;
  final String? signal;

  TechnicalMetric({
    required this.name,
    required this.value,
    this.signal,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'signal': signal ?? '',
  };
}