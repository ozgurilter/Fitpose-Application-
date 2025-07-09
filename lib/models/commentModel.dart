
import 'package:fitness_tracking_app/models/userModel.dart';

class CommentModel {
  final String commentId;
  final UserModel user;
  final String comment;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.user,
    required this.comment,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] ?? '',
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : UserModel(
        userId: '',
        nameSurname: '',
        email: '',
        gender: '',
        height: 0,
        weight: 0,
      ),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "commentId": commentId,
      "user": user.toJson(),
      "comment": comment,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}