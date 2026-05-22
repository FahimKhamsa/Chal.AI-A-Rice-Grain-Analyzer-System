class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String location;
  final String? designation;
  final String email;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.location,
    this.designation,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phoneNumber: json['phone_number'] as String,
      location: json['location'] as String,
      designation: json['designation'] as String?,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'location': location,
        'designation': designation,
        'email': email,
      };

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? location,
    String? designation,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      designation: designation ?? this.designation,
      email: email,
    );
  }
}
