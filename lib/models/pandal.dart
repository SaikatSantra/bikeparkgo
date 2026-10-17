class Pandal {
  final String id;
  final String name;
  final String nameEn;
  final String zone;
  final String tag;
  final String crowd;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String parkingTip;

  Pandal({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.zone,
    required this.tag,
    required this.crowd,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.parkingTip,
  });

  factory Pandal.fromJson(Map<String, dynamic> json) {
    return Pandal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '✨ Famous Pandal',
      crowd: json['crowd']?.toString() ?? 'Moderate',
      imageUrl: json['imageUrl']?.toString() ?? '',
      latitude: (json['lat'] ?? json['latitude'] ?? 22.5726).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 88.3639).toDouble(),
      parkingTip: json['parkingTip']?.toString() ?? 'Designated two-wheeler parking available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'zone': zone,
      'tag': tag,
      'crowd': crowd,
      'imageUrl': imageUrl,
      'lat': latitude,
      'lng': longitude,
      'parkingTip': parkingTip,
    };
  }
}
