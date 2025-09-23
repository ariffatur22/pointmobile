class Reward {
  final int id;
  final String name;
  final String? imageUrl; // Menambahkan properti imageUrl
  final int pointsRequired;
  final int stock;

  Reward({
    required this.id,
    required this.name,
    this.imageUrl, // Menambahkan imageUrl ke konstruktor
    required this.pointsRequired,
    required this.stock,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'], // Mengambil imageUrl dari data JSON
      pointsRequired: json['points_required'],
      stock: json['stock'],
    );
  }
}
