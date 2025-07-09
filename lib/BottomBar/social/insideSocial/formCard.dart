
import 'package:fitness_tracking_app/models/formModel.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormCard extends StatelessWidget {
  final FormModel form;
  final UserModel currentUser;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onDelete;

  const FormCard({
    Key? key,
    required this.form,
    required this.currentUser,
    required this.onLike,
    required this.onComment,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isLiked = form.likes.contains(currentUser.userId);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF5046E5),
                  child: Text(
                    form.user.nameSurname[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.user.nameSurname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(form.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu for own posts
                if (form.user.userId == currentUser.userId && onDelete != null)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              form.content,
              style: TextStyle(fontSize: 14),
            ),
          ),

          // Stats (likes and comments count)
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Text(
                  "${form.likes.length}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.favorite,
                  size: 14,
                  color:Color(0xFF5046E5).withOpacity(0.7),
                ),
                SizedBox(width: 12),
                Text(
                  "${form.comments.length}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Action buttons
          Row(
            children: [
              // Like button
              Expanded(
                child: TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Color(0xFF5046E5) : Colors.grey.shade600,
                    size: 20,
                  ),
                  label: Text(
                    "Beğen",
                    style: TextStyle(
                      color: isLiked ? Color(0xFF5046E5) : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),

              // Vertical divider
              Container(
                height: 20,
                width: 1,
                color: Colors.grey.shade200,
              ),

              // Comment button
              Expanded(
                child: TextButton.icon(
                  onPressed: onComment,
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  label: Text(
                    "Yorum Yap",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('d MMM y').format(date);
    }
  }
}

