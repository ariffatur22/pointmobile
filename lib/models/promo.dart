class Promo {
  final int id;
  final String name;
  final String? imageUrl; // Tambahkan imageUrl
  final String? description;
  final DateTime endDate;

  Promo({
    required this.id,
    required this.name,
    this.imageUrl, // Tambahkan imageUrl
    this.description,
    required this.endDate,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'], // Ambil imageUrl dari JSON
      description: json['description'],
      endDate: DateTime.parse(json['end_date']),
    );
  }
}
