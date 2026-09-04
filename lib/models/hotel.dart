class Hotel {
  final int id;
  final String name;
  final String address;
  final String city;

  const Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
      );
}
