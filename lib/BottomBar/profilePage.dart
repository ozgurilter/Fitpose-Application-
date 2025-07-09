
import 'package:fitness_tracking_app/Auth/welcomePage.dart';
import 'package:fitness_tracking_app/BottomBar/social/insideSocial/UserProfilePage.dart';
import 'package:fitness_tracking_app/provider/userProvider.dart';
import 'package:fitness_tracking_app/provider/socialProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_tracking_app/models/userModel.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserModel _currentUser;
  bool _isEditing = false;
  bool _isLoading = false;
  double _bmi = 0;
  String _bmiCategory = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  // Uygulama renkleri
  static const Color primaryColor = Color(0xFF5046E5);
  static const Color secondaryColor = Color(0xFF9aa0a6);
  static const Color accentColor = Color(0xFFFF7D30); // Turuncu renk düzeltildi

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _initializeControllers();
    _calculateBMI();

    // Listen to changes in the SocialProvider to refresh UI when forms are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socialProvider = Provider.of<SocialProvider>(
        context,
        listen: false,
      );
      socialProvider.initialize(_currentUser.userId);
    });
  }

  // Refresh user data from the provider
  void _refreshUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);

    // Find the current user in the allUsers list from socialProvider
    final updatedUser = socialProvider.allUsers.firstWhere(
      (user) => user.userId == _currentUser.userId,
      orElse: () => _currentUser,
    );

    setState(() {
      _currentUser = updatedUser;
      _calculateBMI();
    });
  }

  void _initializeControllers() {
    _nameController.text = _currentUser.nameSurname;
    _emailController.text = _currentUser.email;
    _heightController.text = _currentUser.height.toString();
    _weightController.text = _currentUser.weight.toString();
    _passwordController.clear();
    _currentPasswordController.clear();
  }

  void _calculateBMI() {
    // BMI formula: weight(kg) / (height(m))²
    double heightInMeters = _currentUser.height / 100;
    _bmi = _currentUser.weight / (heightInMeters * heightInMeters);

    // Determine BMI category
    if (_bmi < 18.5) {
      _bmiCategory = 'Zayıf';
    } else if (_bmi < 25) {
      _bmiCategory = 'Normal';
    } else if (_bmi < 30) {
      _bmiCategory = 'Fazla Kilolu';
    } else {
      _bmiCategory = 'Obez';
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _initializeControllers();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Update user info
      await userProvider.updateUserInfo(
        uid: _currentUser.userId,
        nameSurname: _nameController.text,
        height: double.tryParse(_heightController.text) ?? _currentUser.height,
        weight: double.tryParse(_weightController.text) ?? _currentUser.weight,
        newPassword:
            _passwordController.text.isNotEmpty
                ? _passwordController.text
                : null,
        currentPassword:
            _passwordController.text.isNotEmpty
                ? _currentPasswordController.text
                : null,
      );

      // Refresh user data from providers
      _refreshUserData();

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla güncellendi'),
          backgroundColor: Color(0xFF4A56E2),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show followers dialog
  void _showFollowersDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildFollowersDialog(true),
    );
  }

  // Show following dialog
  void _showFollowingDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildFollowersDialog(false),
    );
  }

  // Build enhanced followers/following dialog
  Widget _buildFollowersDialog(bool isFollowers) {
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);

    final String title = isFollowers ? 'Takipçiler' : 'Takip Edilenler';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: primaryColor,), // Renk güncellendi
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Description text
            Text(
              isFollowers
                  ? 'Sizi takip eden kullanıcılar'
                  : 'Takip ettiğiniz kullanıcılar',
              style: const TextStyle(color: Color(0xFF9aa0a6), fontSize: 14), // Renk güncellendi
            ),

            const Divider(height: 24),

            // Consumer ile anlık güncellemeleri dinliyoruz
            Consumer<SocialProvider>(
              builder: (context, provider, child) {
                // Dinamik olarak güncel listeyi alıyoruz
                final List<String> userIds =
                isFollowers ? _currentUser.followers : _currentUser.following;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Counter text
                    Text(
                      '${userIds.length} ${isFollowers ? 'takipçi' : 'takip edilen'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: secondaryColor, // Renk güncellendi
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Empty state
                    userIds.isEmpty
                        ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            isFollowers
                                ? Icons.people_outline
                                : Icons.person_add_disabled_outlined,
                            size: 56,
                            color: secondaryColor, // Renk güncellendi
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isFollowers
                                ? 'Henüz takipçiniz yok'
                                : 'Henüz kimseyi takip etmiyorsunuz',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: secondaryColor, // Renk güncellendi
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFollowers
                                ? 'Diğer kullanıcılar sizi takip ettiğinde burada görünecekler'
                                : 'Takip etmek istediğiniz kullanıcıları aramayı deneyin',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: secondaryColor, // Renk güncellendi
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                    // User list
                        : Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: userIds.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 68,
                          ),
                          itemBuilder: (context, index) {
                            final userId = userIds[index];
                            final user = provider.allUsers.firstWhere(
                                  (u) => u.userId == userId,
                              orElse: () => UserModel(
                                userId: userId,
                                nameSurname: 'Kullanıcı',
                                email: '',
                                gender: '',
                                height: 0,
                                weight: 0,
                              ),
                            );

                            return _buildUserListItem(user, isFollowers);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Bottom button for finding new users
            if (!isFollowers)
              Consumer<SocialProvider>(
                builder: (context, provider, child) {
                  final List<String> userIds = _currentUser.following;

                  if (userIds.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Navigate to the users tab in social page
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Kullanıcı Bul'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5046E5), // Renk güncellendi
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  // User list item with appropriate actions
  Widget _buildUserListItem(UserModel user, bool isFollowers) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        _navigateToUserProfile(user);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF4A56E2), const Color(0xFF8A80FE)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A56E2).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            user.nameSurname.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      title: Text(
        user.nameSurname,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.article_outlined, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            "${user.myForms.length} gönderi",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),
          Icon(Icons.people_outline, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            "${user.followers.length} takipçi",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      trailing:
          _currentUser.userId != user.userId
              ? _buildUserActionButton(user, isFollowers)
              : null,
    );
  }

  // Action button for each user (follow/unfollow/remove)
  Widget _buildUserActionButton(UserModel user, bool isFollowers) {
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    final bool isFollowing = _currentUser.following.contains(user.userId);

    // For followers list, show remove button for user's followers
    if (isFollowers) {
      return IconButton(
        icon: const Icon(Icons.person_remove, color: Colors.red),
        tooltip: 'Takipçiyi Çıkar',
        onPressed: () => _showRemoveFollowerConfirmation(user),
      );
    }
    // For following list, show unfollow button
    else {
      return TextButton(
        onPressed: () async {
          await socialProvider.toggleFollow(_currentUser.userId, user.userId);
          _refreshUserData();
        },
        style: TextButton.styleFrom(
          backgroundColor:
              isFollowing
                  ? Colors.red.shade50
                  : const Color(0xFF4A56E2).withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          isFollowing ? 'Takibi Bırak' : 'Takip Et',
          style: TextStyle(
            color: isFollowing ? Colors.red : const Color(0xFF4A56E2),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  // Confirmation dialog for removing a follower
  Future<void> _showRemoveFollowerConfirmation(UserModel follower) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Takipçiyi Çıkar'),
            content: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(text: 'Bu işlem '),
                  TextSpan(
                    text: follower.nameSurname,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        ' kullanıcısını takipçilerinizden çıkaracak. Onaylamak istediğinize emin misiniz?',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Çıkar'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );

    if (result == true) {
      await _removeFollower(follower);
    }
  }

  // Remove a follower
  Future<void> _removeFollower(UserModel follower) async {
    try {
      final socialProvider = Provider.of<SocialProvider>(
        context,
        listen: false,
      );

      // First, make the follower unfollow the current user
      await socialProvider.toggleFollow(follower.userId, _currentUser.userId);

      // Refresh user data
      _refreshUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${follower.nameSurname} takipçilerinizden çıkarıldı'),
          backgroundColor: const Color(0xFF4A56E2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Takipçiyi çıkarırken bir hata oluştu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Navigate to user profile
  void _navigateToUserProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UserProfilePage(user: user, currentUser: _currentUser),
      ),
    ).then((_) {
      // Refresh data when returning from profile
      _refreshUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the SocialProvider to refresh UI when forms are added
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        // Find the latest user data in the provider
        if (socialProvider.allUsers.isNotEmpty) {
          final updatedUser = socialProvider.allUsers.firstWhere(
            (user) => user.userId == _currentUser.userId,
            orElse: () => _currentUser,
          );

          if (updatedUser != _currentUser) {
            _currentUser = updatedUser;
            _calculateBMI();
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  80,
                ), // Added bottom padding for navbar
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildProfileForm(),
                    const SizedBox(height: 16),
                    _buildBMICard(),
                    const SizedBox(height: 16),
                    _buildStatsSection(),
                    const SizedBox(height: 16),
                    _buildPoseErrorsSection(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4A56E2),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _currentUser.nameSurname,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [const Color(0xFF4A56E2), const Color(0xFF8A80FE)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(75),
                  ),
                ),
              ),
              Center(
                child: Hero(
                  tag: 'profile-${_currentUser.userId}',
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: Text(
                        _currentUser.nameSurname.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A56E2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Düzenle butonu
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: Colors.white,
              ),
              onPressed: _isLoading ? null : _toggleEditMode,
              tooltip: _isEditing ? 'İptal' : 'Düzenle',
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        // Çıkış butonu
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: _showLogoutConfirmation,
              tooltip: 'Çıkış Yap',
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon üstte
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF7D33),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Başlık
              const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),

              // İçerik
              const Text(
                'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Butonlar
              Row(
                children: [
                  // İptal butonu
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Çıkış butonu
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF7D33),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      _logout();
    }
  }

  // Çıkış yap fonksiyonu
  Future<void> _logout() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();

      // WelcomeScreen'e yönlendir ve geri tuşu ile dönülemesin
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
            (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapılırken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF4A56E2)),
                  const SizedBox(width: 8),
                  const Text(
                    'Profil Bilgileri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A56E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Düzenleniyor',
                        style: TextStyle(
                          color: Color(0xFF4A56E2),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
              _buildEditableTextField(
                controller: _nameController,
                label: 'Ad Soyad',
                icon: Icons.person_outline,
                validator:
                    (value) => value!.isEmpty ? 'Bu alan zorunludur' : null,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildEditableTextField(
                controller: _emailController,
                label: 'E-posta',
                icon: Icons.email_outlined,
                enabled: false,
              ),

              if (_isEditing) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableTextField(
                        controller: _heightController,
                        label: 'Boy (cm)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Bu alan zorunludur';
                          if (double.tryParse(value) == null)
                            return 'Geçerli bir sayı girin';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEditableTextField(
                        controller: _weightController,
                        label: 'Kilo (kg)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Bu alan zorunludur';
                          if (double.tryParse(value) == null)
                            return 'Geçerli bir sayı girin';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEditableTextField(
                  controller: _passwordController,
                  label: 'Yeni Şifre (isteğe bağlı)',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value!.isNotEmpty && value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),

                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildEditableTextField(
                    controller: _currentPasswordController,
                    label: 'Mevcut Şifre',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty &&
                          value!.isEmpty) {
                        return 'Şifre değişikliği için mevcut şifre gereklidir';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A56E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Değişiklikleri Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                _buildInfoTile('Cinsiyet', _currentUser.gender),
                _buildInfoTile('Boy', '${_currentUser.height} cm'),
                _buildInfoTile('Kilo', '${_currentUser.weight} kg'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    Color bmiColor;
    if (_bmi < 18.5) {
      bmiColor = Colors.blue;
    } else if (_bmi < 25) {
      bmiColor = Colors.green;
    } else if (_bmi < 30) {
      bmiColor = Colors.orange;
    } else {
      bmiColor = Colors.red;
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Color(0xFF4A56E2)),
                const SizedBox(width: 8),
                const Text(
                  'Vücut Kitle İndeksi (BMI)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BMI Değeriniz:',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bmi.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: bmiColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bmiColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: bmiColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _bmiCategory,
                          style: TextStyle(
                            color: bmiColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBMIScale(
                        'Zayıf',
                        '<18.5',
                        Colors.blue,
                        _bmi < 18.5,
                      ),
                      const SizedBox(height: 4),
                      _buildBMIScale(
                        'Normal',
                        '18.5-24.9',
                        Colors.green,
                        _bmi >= 18.5 && _bmi < 25,
                      ),
                      const SizedBox(height: 4),
                      _buildBMIScale(
                        'Fazla Kilolu',
                        '25-29.9',
                        Colors.orange,
                        _bmi >= 25 && _bmi < 30,
                      ),
                      const SizedBox(height: 4),
                      _buildBMIScale('Obez', '>30', Colors.red, _bmi >= 30),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIScale(
    String label,
    String range,
    Color color,
    bool isActive,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? color : Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          range,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    // Use latest data from SocialProvider
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        // Find latest user in all users
        final updatedUser = socialProvider.allUsers.firstWhere(
          (user) => user.userId == _currentUser.userId,
          orElse: () => _currentUser,
        );

        final myFormsCount = socialProvider.myForms.length;

        return Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Color(0xFF4A56E2)),
                    const SizedBox(width: 8),
                    const Text(
                      'İstatistikler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Beğeni',
                        updatedUser.likedForms.length.toString(),
                        Icons.favorite,
                        const Color(0xFFFF6B6B),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Form',
                        myFormsCount.toString(),
                        Icons.fitness_center,
                        const Color(0xFF4A56E2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showFollowersDialog,
                        child: _buildStatItem(
                          'Takipçi',
                          updatedUser.followers.length.toString(),
                          Icons.people,
                          const Color(0xFF4ECDC4),
                          isButton: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showFollowingDialog,
                        child: _buildStatItem(
                          'Takip',
                          updatedUser.following.length.toString(),
                          Icons.person_add,
                          const Color(0xFFFFBE0B),
                          isButton: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoseErrorsSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Color(0xFF4A56E2)),
                const SizedBox(width: 8),
                const Text(
                  'Hareket Analizi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_currentUser.poseErrors.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Harika!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tespit edilen hareket hatası yok',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              Column(
                children:
                    _currentUser.poseErrors.map((error) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A56E2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A56E2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    IconData icon,
    Color color, {
    bool isButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow:
            isButton
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 3,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isButton) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade700,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }
}
