class Member {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final int points;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.points,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      points: json['points'],
    );
  }
}
