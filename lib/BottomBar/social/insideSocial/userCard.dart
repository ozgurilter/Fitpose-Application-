

import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_tracking_app/provider/socialProvider.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const UserCard({
    Key? key,
    required this.user,
    required this.isFollowing,
    required this.onFollow,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Consumer to always get the latest data from the provider
    return Consumer<SocialProvider>(
      builder: (context, provider, child) {
        // Get the current user from context to find updated following status
        final UserModel currentUser = ModalRoute.of(context)?.settings.arguments as UserModel? ??
            provider.allUsers.firstWhere(
                  (u) => u.following.contains(user.userId) || user.followers.contains(u.userId),
              orElse: () => UserModel(
                userId: '',
                nameSurname: '',
                email: '',
                gender: '',
                height: 0,
                weight: 0,
              ),
            );

        // Get real-time following status, not the one passed in props
        final isCurrentlyFollowing = currentUser.userId.isNotEmpty &&
            currentUser.following.contains(user.userId);

        // Get the most up-to-date user data from provider
        final updatedUser = provider.allUsers.firstWhere(
              (u) => u.userId == user.userId,
          orElse: () => user,
        );

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // User avatar (circular with first letter)
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF4361EE),
                    child: Text(
                      updatedUser.nameSurname[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // User info (name and stats)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updatedUser.nameSurname,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          updatedUser.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "${updatedUser.followers.length} takipçi",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "${updatedUser.myForms.length} gönderi",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Follow/Unfollow button - using real-time status
                  TextButton(
                    onPressed: onFollow,
                    style: TextButton.styleFrom(
                      backgroundColor: isCurrentlyFollowing ? Colors.white : Color(0xFF4361EE),
                      foregroundColor: isCurrentlyFollowing ? Color(0xFF4361EE) : Colors.white,
                      side: isCurrentlyFollowing ? BorderSide(color: Color(0xFF4361EE)) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      minimumSize: Size(0, 0),
                    ),
                    child: Text(
                      isCurrentlyFollowing ? "Takipte" : "Takip Et",
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
      },
    );
  }
}