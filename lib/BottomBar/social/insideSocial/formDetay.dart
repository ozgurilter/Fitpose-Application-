

import 'package:fitness_tracking_app/BottomBar/social/insideSocial/UserProfilePage.dart';
import 'package:fitness_tracking_app/models/commentModel.dart';
import 'package:fitness_tracking_app/models/formModel.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:fitness_tracking_app/provider/socialProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class FormDetailPage extends StatefulWidget {
  final FormModel form;
  final UserModel currentUser;

  const FormDetailPage({
    Key? key,
    required this.form,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<FormDetailPage> createState() => _FormDetailPageState();
}

class _FormDetailPageState extends State<FormDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FormModel form = Provider.of<SocialProvider>(context)
        .feedForms
        .firstWhere(
          (f) => f.formId == widget.form.formId,
      orElse: () => widget.form,
    );

    final bool isLiked = form.likes.contains(widget.currentUser.userId);
    final bool isOwnPost = form.user.userId == widget.currentUser.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Gönderi Detayları",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isOwnPost)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(form.formId),
            ),
        ],
      ),
      body: Column(
        children: [
          // Content - scrollable part
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header with user info
                  _buildPostHeader(form),

                  // Post content
                  _buildPostContent(form),

                  // Likes and comments count
                  _buildStatsBar(form),

                  // Action buttons
                  _buildActionButtons(form, isLiked),

                  // Divider
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

                  // Comments section
                  _buildCommentsSection(form),
                ],
              ),
            ),
          ),

          // Comment input (fixed at bottom)
          _buildCommentInput(form),
        ],
      ),
    );
  }

  Widget _buildPostHeader(FormModel form) {
    return GestureDetector(
      onTap: () {
        if (form.user.userId != widget.currentUser.userId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                user: form.user,
                currentUser: widget.currentUser,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF4361EE),
              child: Text(
                form.user.nameSurname[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            SizedBox(width: 12),

            // User name and post date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    form.user.nameSurname,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent(FormModel form) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        form.content,
        style: TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildStatsBar(FormModel form) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                size: 14,
                color: Colors.grey.shade700,
              ),
              SizedBox(width: 4),
              Text(
                "${form.likes.length}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: Colors.grey.shade700,
              ),
              SizedBox(width: 4),
              Text(
                "${form.comments.length}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(FormModel form, bool isLiked) {
    return Row(
      children: [
        // Like button
        Expanded(
          child: TextButton.icon(
            onPressed: () => _handleLike(form),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(),
            ),
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Color(0xFF4361EE) : Colors.grey.shade600,
              size: 20,
            ),
            label: Text(
              "Beğen",
              style: TextStyle(
                color: isLiked ? Color(0xFF4361EE) : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
              ),
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
            onPressed: () {
              FocusScope.of(context).requestFocus(
                _commentController.buildTextSpan(
                  context: context,
                  withComposing: true,
                ).toPlainText().isEmpty ? FocusNode() : null,
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(),
            ),
            icon: Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey.shade600,
              size: 20,
            ),
            label: Text(
              "Yorum Yap",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(FormModel form) {
    if (form.comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 16),
              Text(
                'Henüz yorum yok',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'İlk yorumu sen yap',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Yorumlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: form.comments.length,
          itemBuilder: (context, index) => _buildCommentItem(form.comments[index]),
        ),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    bool isCurrentUserComment = comment.user.userId == widget.currentUser.userId;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          GestureDetector(
            onTap: () {
              if (comment.user.userId != widget.currentUser.userId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      user: comment.user,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4361EE),
              child: Text(
                comment.user.nameSurname[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          SizedBox(width: 8),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment bubble
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentUserComment ? Color(0xFFEBEEFF) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        comment.user.nameSurname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isCurrentUserComment ? Color(0xFF4361EE) : Colors.black87,
                        ),
                      ),

                      SizedBox(height: 4),

                      // Comment text
                      Text(
                        comment.comment,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Comment time
                Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _formatDate(comment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(FormModel form) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF4361EE),
            child: Text(
              widget.currentUser.nameSurname[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          SizedBox(width: 8),

          // Comment text field
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Yorumunuzu yazın...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              onChanged: (text) {
                // TextField değişikliklerinde UI'ı güncellemek için
                setState(() {});
              },
            ),
          ),

          SizedBox(width: 8),

          // Send button
          _isLoading
              ? Container(
            width: 32,
            height: 32,
            padding: EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4361EE)),
            ),
          )
              : Material(
            color: _commentController.text.trim().isEmpty
                ? Colors.grey.shade300 // Devre dışı renk
                : Color(0xFF4361EE),   // Aktif renk
            shape: CircleBorder(),
            child: InkWell(
              onTap: _commentController.text.trim().isEmpty
                  ? null
                  : () => _addComment(form.formId),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.send,
                  color: _commentController.text.trim().isEmpty
                      ? Colors.grey.shade500  // Devre dışı icon rengi
                      : Colors.white,         // Aktif icon rengi
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLike(FormModel form) async {
    try {
      await Provider.of<SocialProvider>(context, listen: false)
          .toggleLike(form.formId, widget.currentUser.userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beğeni işlemi sırasında bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addComment(String formId) async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<SocialProvider>(context, listen: false).addComment(
        formId: formId,
        user: widget.currentUser,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(String formId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gönderiyi Sil'),
        content: Text('Bu gönderiyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deletePost(formId);
    }
  }

  Future<void> _deletePost(String formId) async {
    try {
      await Provider.of<SocialProvider>(context, listen: false)
          .deleteForm(formId, widget.currentUser.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderi başarıyla silindi'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context); // Go back after deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderi silinirken bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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