
import 'package:fitness_tracking_app/BottomBar/social/insideSocial/formCard.dart';
import 'package:fitness_tracking_app/models/commentModel.dart';
import 'package:fitness_tracking_app/models/formModel.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:fitness_tracking_app/provider/socialProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;
  final UserModel currentUser;

  const UserProfilePage({
    Key? key,
    required this.user,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      await Provider.of<SocialProvider>(context, listen: false)
          .initialize(widget.currentUser.userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı verileri yüklenirken hata oluştu'),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SocialProvider>(context);
    final bool isCurrentUser = widget.user.userId == widget.currentUser.userId;
    final bool isFollowing = widget.currentUser.following.contains(widget.user.userId);

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
          widget.user.nameSurname,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4361EE)),
        ),
      )
          : Column(
        children: [
          // User profile header
          _buildProfileHeader(isFollowing, isCurrentUser),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Color(0xFF5046E5),
              labelColor: Color(0xFF5046E5),
              unselectedLabelColor: Color(0xFF9aa0a6),
              tabs: [
                Tab(text: 'Paylaşımlar'),
                Tab(text: 'Takip Ettikleri'),
                Tab(text: 'Takipçiler'),
              ],
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // User Posts Tab
                _buildPostsTab(provider, isCurrentUser),

                // Following Tab
                _buildFollowingTab(provider),

                // Followers Tab
                _buildFollowersTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isFollowing, bool isCurrentUser) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar and stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF5046E5),
                child: Text(
                  widget.user.nameSurname[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(width: 20),

              // Stats
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA), // Açık gri arka plan
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(

                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImprovedStatItem("${widget.user.myForms.length}", "Paylaşım", Color(0xFF5046E5)),
                      _buildStatDivider(),
                      _buildImprovedStatItem("${widget.user.followers.length}", "Takipçi", Color(0xFF9aa0a6)),
                      _buildStatDivider(),
                      _buildImprovedStatItem("${widget.user.following.length}", "Takip", Color(0xFFFF7D33)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // User details
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.nameSurname,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    color: Color(0xFF9aa0a6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Follow/Unfollow button
          if (!isCurrentUser)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.white :  Color(0xFF5046E5),
                  foregroundColor: isFollowing ? Color(0xFF4361EE) : Colors.white,
                  elevation: 0,
                  side: BorderSide(
                    color: isFollowing ? Color(0xFF5046E5) : Colors.transparent,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isFollowing ? "Takibi Bırak" : "Takip Et",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // New helper method for improved stat items
  Widget _buildImprovedStatItem(String count, String label, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: iconColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF9aa0a6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

// New helper method for stat divider
  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.green,
    );
  }


  Widget _buildPostsTab(SocialProvider provider, bool isCurrentUser) {
    // Get user's posts
    final userPosts = provider.feedForms
        .where((form) => form.user.userId == widget.user.userId)
        .toList();

    if (userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz paylaşım yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isCurrentUser
                  ? 'İlk paylaşımınızı oluşturmak için ana sayfaya gidin'
                  : '${widget.user.nameSurname} henüz bir paylaşım yapmadı',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: userPosts.length,
      padding: EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: FormCard(
            form: userPosts[index],
            currentUser: widget.currentUser,
            onLike: () => _handleLike(userPosts[index]),
            onComment: () => _showCommentsDialog(userPosts[index]),
            onDelete: isCurrentUser
                ? () => _confirmDelete(userPosts[index].formId)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab(SocialProvider provider) {
    final followingUsers = provider.allUsers
        .where((user) => widget.user.following.contains(user.userId))
        .toList();

    if (followingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              '${widget.user.nameSurname} henüz kimseyi takip etmiyor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: followingUsers.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = followingUsers[index];
        final isFollowed = widget.currentUser.following.contains(user.userId);

        return _buildUserListItem(user, isFollowed);
      },
    );
  }

  Widget _buildFollowersTab(SocialProvider provider) {
    final followerUsers = provider.allUsers
        .where((user) => widget.user.followers.contains(user.userId))
        .toList();

    if (followerUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz takipçi yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: followerUsers.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = followerUsers[index];
        final isFollowed = widget.currentUser.following.contains(user.userId);

        return _buildUserListItem(user, isFollowed);
      },
    );
  }

  Widget _buildUserListItem(UserModel user, bool isFollowed) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          if (user.userId != widget.currentUser.userId) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(
                  user: user,
                  currentUser: widget.currentUser,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF4361EE),
                child: Text(
                  user.nameSurname[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nameSurname,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Follow/Unfollow button
              if (user.userId != widget.currentUser.userId)
                TextButton(
                  onPressed: () => _handleFollowForUser(user),
                  style: TextButton.styleFrom(
                    backgroundColor: isFollowed ? Colors.white : Color(0xFF4361EE),
                    foregroundColor: isFollowed ? Color(0xFF4361EE) : Colors.white,
                    side: isFollowed ? BorderSide(color: Color(0xFF4361EE)) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size(0, 0),
                  ),
                  child: Text(
                    isFollowed ? "Takipte" : "Takip Et",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFollow() async {
    try {
      // Optimistic update
      setState(() {
        bool isCurrentlyFollowing = widget.currentUser.following.contains(widget.user.userId);
        if (isCurrentlyFollowing) {
          widget.currentUser.following.remove(widget.user.userId);
          widget.user.followers.remove(widget.currentUser.userId);
        } else {
          widget.currentUser.following.add(widget.user.userId);
          widget.user.followers.add(widget.currentUser.userId);
        }
      });

      // Update in database
      await Provider.of<SocialProvider>(context, listen: false)
          .toggleFollow(widget.currentUser.userId, widget.user.userId);

      // Force refresh of provider
      Provider.of<SocialProvider>(context, listen: false).notifyListeners();

    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        bool isCurrentlyFollowing = widget.currentUser.following.contains(widget.user.userId);
        if (isCurrentlyFollowing) {
          widget.currentUser.following.remove(widget.user.userId);
          widget.user.followers.remove(widget.currentUser.userId);
        } else {
          widget.currentUser.following.add(widget.user.userId);
          widget.user.followers.add(widget.currentUser.userId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takip işlemi sırasında bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  void _handleFollowForUser(UserModel user) async {
    try {
      // Optimistic update
      setState(() {
        bool isCurrentlyFollowing = widget.currentUser.following.contains(user.userId);
        if (isCurrentlyFollowing) {
          widget.currentUser.following.remove(user.userId);
          user.followers.remove(widget.currentUser.userId);
        } else {
          widget.currentUser.following.add(user.userId);
          user.followers.add(widget.currentUser.userId);
        }
      });

      // Update in database
      await Provider.of<SocialProvider>(context, listen: false)
          .toggleFollow(widget.currentUser.userId, user.userId);

      // Force refresh
      Provider.of<SocialProvider>(context, listen: false).notifyListeners();

    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        bool isCurrentlyFollowing = widget.currentUser.following.contains(user.userId);
        if (isCurrentlyFollowing) {
          widget.currentUser.following.remove(user.userId);
          user.followers.remove(widget.currentUser.userId);
        } else {
          widget.currentUser.following.add(user.userId);
          user.followers.add(widget.currentUser.userId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takip işlemi sırasında bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
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
          ),
        );
      }
    }
  }

  Future<void> _showCommentsDialog(FormModel form) async {
    final commentController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(
            children: [
              // Drag indicator and header
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yorumlar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Comments list
              Expanded(
                child: form.comments.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Henüz yorum yok',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'İlk yorumu sen yap',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: form.comments.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (ctx, index) => _buildCommentItem(form.comments[index]),
                ),
              ),

              // Comment input
              Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
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
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Yorum yaz...',
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
                      ),
                    ),

                    SizedBox(width: 8),

                    // Send button
                    InkWell(
                      onTap: () async {
                        if (commentController.text.trim().isNotEmpty) {
                          await _addComment(form.formId, commentController.text.trim());
                          commentController.clear();
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4361EE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          CircleAvatar(
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

  Future<void> _addComment(String formId, String comment) async {
    try {
      await Provider.of<SocialProvider>(context, listen: false).addComment(
        formId: formId,
        user: widget.currentUser,
        comment: comment,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(String formId) async {
    return await showDialog<bool>(
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
  }

  Future<void> _deletePost(String formId) async {
    try {
      await Provider.of<SocialProvider>(context, listen: false)
          .deleteForm(formId, widget.currentUser.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderi başarıyla silindi'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderi silinirken bir hata oluştu'),
            backgroundColor: Colors.red.shade400,
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