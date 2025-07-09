
import 'package:fitness_tracking_app/models/commentModel.dart';
import 'package:fitness_tracking_app/models/userModel.dart';

class FormModel {
  final String formId;
  final UserModel user;
  final String content;
  final DateTime createdAt;
  final List<String> likes; // Store as user IDs to match SocialProvider implementation
  final List<CommentModel> comments;

  FormModel({
    required this.formId,
    required this.user,
    required this.content,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
  });

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      formId: json['formId'] ?? '',
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
      content: json['content'] ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.now()),
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] is List)
          ? (json['comments'] as List)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'user': user.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}
