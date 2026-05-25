class Sticker {
  const Sticker({
    required this.id,
    required this.number,
    required this.name,
    required this.team,
    required this.collectionId,
    this.imageUrl,
    this.rarity,
  });

  final String id;
  final int number;
  final String name;
  final String team;
  final String collectionId;
  final String? imageUrl;
  final String? rarity;

  String get catalogCode {
    final prefix = switch (team.toLowerCase()) {
      'mexico' => 'MEX',
      'uruguay' => 'URU',
      'uzbekistan' => 'UZB',
      _ => null,
    };
    final countryNumberMatch = RegExp(r'-(\d+)$').firstMatch(id);

    if (prefix != null && id.endsWith('-logo')) {
      return '$prefix-ESC';
    }
    if (prefix != null && countryNumberMatch != null) {
      final countryNumber = int.parse(countryNumberMatch.group(1)!);
      return '$prefix-${countryNumber.toString().padLeft(2, '0')}';
    }

    final mockSection = switch (team.toLowerCase()) {
      'equipo andino' => ('PER', 1),
      'equipo costero' => ('CAN', 6),
      'equipo selva' => ('USA', 11),
      'equipo austral' => ('ARG', 16),
      'equipo norte' => ('BRA', 21),
      'equipo plata' => ('ESP', 26),
      'equipo dorado' => ('FRA', 31),
      'equipo oceano' => ('ING', 36),
      'equipo capital' => ('ALE', 41),
      'equipo granate' => ('JPN', 46),
      _ => null,
    };
    if (mockSection != null) {
      final sectionNumber = number - mockSection.$2 + 1;
      return '${mockSection.$1}-${sectionNumber.toString().padLeft(2, '0')}';
    }

    return number.toString().padLeft(3, '0');
  }

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'] as String,
      number: json['number'] as int,
      name: json['name'] as String,
      team: json['team'] as String,
      collectionId: json['collectionId'] as String,
      imageUrl: json['imageUrl'] as String?,
      rarity: json['rarity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'team': team,
      'collectionId': collectionId,
      'imageUrl': imageUrl,
      'rarity': rarity,
    };
  }
}
