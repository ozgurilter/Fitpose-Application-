import 'package:fitness_tracking_app/models/formModel.dart';

class UserModel {
  final String userId;
  final String nameSurname;
  final String email;
  final String gender;
  final double height;
  final double weight;
  final List<String> poseErrors;
  final List<String> following; // Store as IDs, not UserModel objects
  final List<String> followers; // Store as IDs, not UserModel objects
  final List<String> likedForms; // Store as IDs, not FormModel objects
  final List<String> myForms; // Store as IDs, not FormModel objects

  UserModel({
    required this.userId,
    required this.nameSurname,
    required this.email,
    required this.gender,
    required this.height,
    required this.weight,
    this.poseErrors = const [],
    this.following = const [],
    this.followers = const [],
    this.likedForms = const [],
    this.myForms = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      nameSurname: json['nameSurname'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      height: ((json['height'] ?? 0) as num).toDouble(),
      weight: ((json['weight'] ?? 0) as num).toDouble(),
      poseErrors: List<String>.from(json['poseErrors'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
      likedForms: List<String>.from(json['likedForms'] ?? []),
      myForms: List<String>.from(json['myForms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "nameSurname": nameSurname,
      "email": email,
      "gender": gender,
      "height": height,
      "weight": weight,
      "poseErrors": poseErrors,
      "likedForms": likedForms,
      "myForms": myForms,
      "following": following,
      "followers": followers,
    };
  }

  UserModel copyWith({
    String? userId,
    String? nameSurname,
    String? email,
    String? gender,
    double? height,
    double? weight,
    List<String>? poseErrors,
    List<String>? following,
    List<String>? followers,
    List<String>? likedForms,
    List<String>? myForms,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      nameSurname: nameSurname ?? this.nameSurname,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      poseErrors: poseErrors ?? List.from(this.poseErrors),
      likedForms: likedForms ?? List.from(this.likedForms),
      myForms: myForms ?? List.from(this.myForms),
      following: following ?? List.from(this.following),
      followers: followers ?? List.from(this.followers),
    );
  }
}