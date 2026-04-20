String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final absolute = cents.abs();
  final reais = absolute ~/ 100;
  final centavos = (absolute % 100).toString().padLeft(2, '0');

  return '${sign}R\$ $reais,$centavos';
}

int? parseCents(String value) {
  final cleaned = value
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();

  if (cleaned.isEmpty) {
    return null;
  }

  final amount = double.tryParse(cleaned);
  if (amount == null || amount < 0) {
    return null;
  }

  return (amount * 100).round();
}
