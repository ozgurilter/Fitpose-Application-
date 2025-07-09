
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_tracking_app/models/commentModel.dart';
import 'package:fitness_tracking_app/models/formModel.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:flutter/material.dart';

class SocialProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  List<FormModel> _feedForms = [];
  List<FormModel> _myForms = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  String? _error;
  List<StreamSubscription> _subscriptions = [];

  // Getters
  List<FormModel> get feedForms => _feedForms;
  List<FormModel> get myForms => _myForms;
  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize(String userId) async {
    _isLoading = true;
    _error = null; // Reset error state
    notifyListeners();

    try {
      // Clear any existing subscriptions
      _clearSubscriptions();

      // Set up all listeners with error handling
      await _setupListenersWithRetry(userId);

      // Özel olarak kullanıcı takibini dinlemek için yeni metodu ekleyelim
      await setupDynamicListeners(userId);
    } catch (e) {
      _error = 'Initialization failed: ${e.toString()}';
      debugPrint(_error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupListenersWithRetry(String userId) async {
    try {
      _subscriptions.addAll([
        _setupFeedListener(),
        await _setupMyFormsListener(userId), // Use alternative query if index isn't ready
        _setupUsersListener(),
      ]);
    } catch (e) {
      // Log error and implement a retry mechanism
      debugPrint('Setting up listeners failed, retrying in 3 seconds: $e');
      await Future.delayed(Duration(seconds: 3));

      // Try one more time with fallback strategies
      _subscriptions.addAll([
        _setupFeedListener(),
        await _setupFallbackMyFormsListener(userId), // Fallback without ordering
        _setupUsersListener(),
      ]);
    }
  }

  // Clear all active subscriptions
  void _clearSubscriptions() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // Set up feed listener with proper error handling
  StreamSubscription<QuerySnapshot> _setupFeedListener() {
    return _firestore.collection('forms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      try {
        _feedForms = await _processForms(snapshot);
        notifyListeners();
      } catch (e) {
        _handleError('Error processing feed forms', e);
      }
    }, onError: (e) => _handleError('Feed listener error', e));
  }

  // Set up my forms listener with index error handling
  Future<StreamSubscription<QuerySnapshot>> _setupMyFormsListener(String userId) async {
    try {
      // Try with the compound query first
      return _firestore.collection('forms')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) async {
        try {
          _myForms = await _processForms(snapshot);
          notifyListeners();
        } catch (e) {
          _handleError('Error processing my forms', e);
        }
      }, onError: (e) {
        // If this fails, it's likely due to a missing index
        debugPrint('My forms listener compound query error: $e');
        // The method will throw, which will be caught in _setupListenersWithRetry
        throw e;
      });
    } catch (e) {
      // Let the caller handle this exception
      throw e;
    }
  }

  // Fallback implementation without ordering (for when index doesn't exist)
  Future<StreamSubscription<QuerySnapshot>> _setupFallbackMyFormsListener(String userId) async {
    debugPrint('Using fallback forms listener without compound indexing');

    // Get all forms for this user without ordering
    return _firestore.collection('forms')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      try {
        final forms = await _processForms(snapshot);
        // Sort manually in memory instead of relying on Firestore ordering
        forms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _myForms = forms;
        notifyListeners();
      } catch (e) {
        _handleError('Error processing my forms (fallback)', e);
      }
    }, onError: (e) => _handleError('My forms fallback listener error', e));
  }

  // Set up users listener with improved real-time updates
  StreamSubscription<QuerySnapshot> _setupUsersListener() {
    return _firestore.collection('users')
        .snapshots()
        .listen((snapshot) {
      try {
        _allUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          if (data.isEmpty) {
            debugPrint('Empty user document found: ${doc.id}');
            return null;
          }
          return UserModel.fromJson(data);
        })
            .where((user) => user != null)
            .cast<UserModel>()
            .toList();

        // Ensure we have up-to-date user data
        _refreshFormsWithUpdatedUserData();

        notifyListeners();
      } catch (e) {
        _handleError('Error processing users', e);
      }
    }, onError: (e) => _handleError('Users listener error', e));
  }

  // Refresh form models with updated user data
  void _refreshFormsWithUpdatedUserData() {
    if (_allUsers.isEmpty) return;

    // Create a map of userId -> UserModel for quick lookup
    final Map<String, UserModel> userMap = {
      for (var user in _allUsers) user.userId: user
    };

    // Update feed forms with the latest user data
    _feedForms = _feedForms.map((form) {
      final updatedUser = userMap[form.user.userId];
      if (updatedUser != null) {
        return FormModel(
          formId: form.formId,
          user: updatedUser,
          content: form.content,
          createdAt: form.createdAt,
          likes: form.likes,
          comments: form.comments.map((comment) {
            final commentUser = userMap[comment.user.userId];
            if (commentUser != null) {
              return CommentModel(
                commentId: comment.commentId,
                user: commentUser,
                comment: comment.comment,
                createdAt: comment.createdAt,
              );
            }
            return comment;
          }).toList(),
        );
      }
      return form;
    }).toList();

    // Update my forms with the latest user data
    _myForms = _myForms.map((form) {
      final updatedUser = userMap[form.user.userId];
      if (updatedUser != null) {
        return FormModel(
          formId: form.formId,
          user: updatedUser,
          content: form.content,
          createdAt: form.createdAt,
          likes: form.likes,
          comments: form.comments.map((comment) {
            final commentUser = userMap[comment.user.userId];
            if (commentUser != null) {
              return CommentModel(
                commentId: comment.commentId,
                user: commentUser,
                comment: comment.comment,
                createdAt: comment.createdAt,
              );
            }
            return comment;
          }).toList(),
        );
      }
      return form;
    }).toList();
  }

  // Process form documents with improved error handling
  Future<List<FormModel>> _processForms(QuerySnapshot snapshot) async {
    List<FormModel> forms = [];
    Map<String, UserModel> userCache = {};

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (data.isEmpty) {
          debugPrint('Empty form document found: ${doc.id}');
          continue;
        }

        // Add null checks for required fields
        final userId = data['userId'] as String?;
        if (userId == null || userId.isEmpty) {
          debugPrint('Skipping form ${doc.id}: userId is null or empty');
          continue;
        }

        // Get user data from cache or Firestore with retry mechanism
        UserModel? user = userCache[userId];
        if (user == null) {
          // Try to find user in local state first for efficiency
          user = _allUsers.firstWhere(
                (u) => u.userId == userId,
            orElse: () => UserModel(
              userId: '',
              nameSurname: '',
              email: '',
              gender: '',
              height: 0,
              weight: 0,
            ),
          );

          // If not found or empty, fetch from Firestore
          if (user.userId.isEmpty) {
            try {
              final userDoc = await _firestore.collection('users').doc(userId).get();
              if (!userDoc.exists || userDoc.data() == null) {
                debugPrint('User document not found or empty for userId: $userId');
                continue;
              }
              user = UserModel.fromJson(userDoc.data()!);
            } catch (e) {
              debugPrint('Error fetching user for form ${doc.id}: $e');
              // Try once more after a short delay
              await Future.delayed(Duration(milliseconds: 300));
              try {
                final userDoc = await _firestore.collection('users').doc(userId).get();
                if (!userDoc.exists || userDoc.data() == null) continue;
                user = UserModel.fromJson(userDoc.data()!);
              } catch (e) {
                debugPrint('Second attempt to fetch user failed: $e');
                continue;
              }
            }
          }
          userCache[userId] = user;
        }

        // Add null check for content
        final content = data['content'] as String? ?? '';

        // Safely get timestamp
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        // Safely get likes with null check
        final likes = data['likes'] != null
            ? List<String>.from(data['likes'])
            : <String>[];

        // Get comments
        final comments = await _getComments(doc.reference, userCache);

        forms.add(FormModel(
          formId: doc.id,
          user: user,
          content: content,
          createdAt: createdAt,
          likes: likes,
          comments: comments,
        ));
      } catch (e) {
        debugPrint('Error processing form ${doc.id}: $e');
        // Continue to the next form instead of failing the whole list
      }
    }

    return forms;
  }

  // Get comments for a form with improved error handling
  Future<List<CommentModel>> _getComments(
      DocumentReference formRef, Map<String, UserModel> userCache) async {
    try {
      final snapshot = await formRef.collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      List<CommentModel> comments = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data.isEmpty) {
            debugPrint('Empty comment document found: ${doc.id}');
            continue;
          }

          final userId = data['userId'] as String?;
          if (userId == null || userId.isEmpty) {
            debugPrint('Skipping comment ${doc.id}: userId is null or empty');
            continue;
          }

          // Get user from cache, local state, or Firestore
          UserModel? user = userCache[userId];
          if (user == null) {
            // Try to find in local state first
            user = _allUsers.firstWhere(
                  (u) => u.userId == userId,
              orElse: () => UserModel(
                userId: '',
                nameSurname: '',
                email: '',
                gender: '',
                height: 0,
                weight: 0,
              ),
            );

            // If not found in local state, fetch from Firestore
            if (user.userId.isEmpty) {
              try {
                final userDoc = await _firestore.collection('users').doc(userId).get();
                if (!userDoc.exists || userDoc.data() == null) continue;
                user = UserModel.fromJson(userDoc.data()!);
                userCache[userId] = user;
              } catch (e) {
                debugPrint('Error fetching user for comment ${doc.id}: $e');
                continue;
              }
            }
          }

          final comment = data['comment'] as String? ?? '';
          final createdAt = data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now();

          comments.add(CommentModel(
            commentId: doc.id,
            user: user,
            comment: comment,
            createdAt: createdAt,
          ));
        } catch (e) {
          debugPrint('Error processing comment ${doc.id}: $e');
          // Continue to next comment instead of failing all comments
        }
      }
      return comments;
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  // Create a new form with optimistic update and improved error handling
  Future<void> createForm({
    required UserModel user,
    required String content,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final formRef = _firestore.collection('forms').doc();
      final formId = formRef.id;
      final now = DateTime.now();

      final newForm = FormModel(
        formId: formId,
        user: user,
        content: content,
        createdAt: now,
        likes: [],
        comments: [],
      );

      // Optimistic update
      _myForms = [newForm, ..._myForms];
      _feedForms = [newForm, ..._feedForms]; // Also update feed for immediate visibility
      notifyListeners();

      // Create form document
      await formRef.set({
        'formId': formId,
        'userId': user.userId,
        'content': content,
        'createdAt': Timestamp.fromDate(now),
        'likes': [],
      });

      // Add to user's myForms
      await _firestore.collection('users').doc(user.userId).update({
        'myForms': FieldValue.arrayUnion([formId])
      });

    } catch (e) {
      // Revert optimistic update on error
      await initialize(user.userId);
      _handleError('Failed to create form', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle like with optimistic update
  Future<void> toggleLike(String formId, String userId) async {
    if (formId.isEmpty || userId.isEmpty) {
      debugPrint('Cannot toggle like: formId or userId is empty');
      return;
    }

    try {
      // Find the form in both lists
      FormModel? feedForm = _feedForms.firstWhere(
            (f) => f.formId == formId,
        orElse: () => FormModel(
          formId: '',
          user: UserModel(
            userId: '',
            nameSurname: '',
            email: '',
            gender: '',
            height: 0,
            weight: 0,
          ),
          content: '',
          createdAt: DateTime.now(),
        ),
      );

      // Skip if not found
      if (feedForm.formId.isEmpty) {
        debugPrint('Cannot toggle like: form not found in feed');
        return;
      }

      final isLiked = feedForm.likes.contains(userId);

      // Optimistic update
      List<FormModel> updatedFeedForms = _feedForms.map((form) {
        if (form.formId == formId) {
          List<String> newLikes = List.from(form.likes);
          if (isLiked) {
            newLikes.remove(userId);
          } else {
            newLikes.add(userId);
          }
          return FormModel(
            formId: form.formId,
            user: form.user,
            content: form.content,
            createdAt: form.createdAt,
            likes: newLikes,
            comments: form.comments,
          );
        }
        return form;
      }).toList();

      // Also update in myForms if present
      List<FormModel> updatedMyForms = _myForms.map((form) {
        if (form.formId == formId) {
          List<String> newLikes = List.from(form.likes);
          if (isLiked) {
            newLikes.remove(userId);
          } else {
            newLikes.add(userId);
          }
          return FormModel(
            formId: form.formId,
            user: form.user,
            content: form.content,
            createdAt: form.createdAt,
            likes: newLikes,
            comments: form.comments,
          );
        }
        return form;
      }).toList();

      _feedForms = updatedFeedForms;
      _myForms = updatedMyForms;
      notifyListeners();

      // Perform database update
      final batch = _firestore.batch();
      final formRef = _firestore.collection('forms').doc(formId);
      final userRef = _firestore.collection('users').doc(userId);

      if (isLiked) {
        batch.update(formRef, {'likes': FieldValue.arrayRemove([userId])});
        batch.update(userRef, {'likedForms': FieldValue.arrayRemove([formId])});
      } else {
        batch.update(formRef, {'likes': FieldValue.arrayUnion([userId])});
        batch.update(userRef, {'likedForms': FieldValue.arrayUnion([formId])});
      }

      await batch.commit();

      // Fetch updated user data to ensure all UI components reflect the change
      final updatedUserDoc = await _firestore.collection('users').doc(userId).get();
      if (updatedUserDoc.exists && updatedUserDoc.data() != null) {
        final updatedUser = UserModel.fromJson(updatedUserDoc.data()!);

        // Update the user in _allUsers list
        final userIndex = _allUsers.indexWhere((u) => u.userId == userId);
        if (userIndex >= 0) {
          _allUsers[userIndex] = updatedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: ${e.toString()}');
      rethrow;
    }
  }
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      debugPrint('Cannot toggle follow: currentUserId or targetUserId is empty');
      return;
    }

    try {
      if (currentUserId == targetUserId) return;

      // Önce mevcut kullanıcı ve hedef kullanıcı modellerini bulalım
      final currentUserModel = _allUsers.firstWhere(
            (user) => user.userId == currentUserId,
        orElse: () => UserModel(
          userId: '',
          nameSurname: '',
          email: '',
          gender: '',
          height: 0,
          weight: 0,
        ),
      );

      if (currentUserModel.userId.isEmpty) {
        debugPrint('Current user not found in users list');
        return;
      }

      final targetUserModel = _allUsers.firstWhere(
            (user) => user.userId == targetUserId,
        orElse: () => UserModel(
          userId: '',
          nameSurname: '',
          email: '',
          gender: '',
          height: 0,
          weight: 0,
        ),
      );

      if (targetUserModel.userId.isEmpty) {
        debugPrint('Target user not found in users list');
        return;
      }

      // Takip edilme durumunu alalım
      final isFollowing = currentUserModel.following.contains(targetUserId);

      // ÖNEMLİ DEĞİŞİKLİK: Kopyalar oluşturmak yerine doğrudan mevcut modelleri değiştirelim
      // Bu, UI'ın her yerinde anında yansıması için gereklidir
      List<UserModel> updatedUsers = List.from(_allUsers);

      // Mevcut kullanıcının takip listesini güncelleyelim
      final currentUserIndex = updatedUsers.indexWhere((u) => u.userId == currentUserId);
      if (currentUserIndex >= 0) {
        List<String> newFollowing = List.from(updatedUsers[currentUserIndex].following);
        if (isFollowing) {
          newFollowing.remove(targetUserId);
        } else {
          newFollowing.add(targetUserId);
        }

        // Güncelleme için kopyalama yapalım, referans değişsin
        updatedUsers[currentUserIndex] = updatedUsers[currentUserIndex].copyWith(following: newFollowing);
      }

      // Hedef kullanıcının takipçi listesini güncelleyelim
      final targetUserIndex = updatedUsers.indexWhere((u) => u.userId == targetUserId);
      if (targetUserIndex >= 0) {
        List<String> newFollowers = List.from(updatedUsers[targetUserIndex].followers);
        if (isFollowing) {
          newFollowers.remove(currentUserId);
        } else {
          newFollowers.add(currentUserId);
        }

        // Güncelleme için kopyalama yapalım, referans değişsin
        updatedUsers[targetUserIndex] = updatedUsers[targetUserIndex].copyWith(followers: newFollowers);
      }

      // Tüm kullanıcı listesini güncelleyelim
      _allUsers = updatedUsers;

      // ÖNEMLİ: Kullanıcı verilerinin değiştiğini bildirelim
      notifyListeners();

      // Firestore güncellemelerini yapalım
      final batch = _firestore.batch();
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      if (isFollowing) {
        batch.update(currentUserRef, {'following': FieldValue.arrayRemove([targetUserId])});
        batch.update(targetUserRef, {'followers': FieldValue.arrayRemove([currentUserId])});
      } else {
        batch.update(currentUserRef, {'following': FieldValue.arrayUnion([targetUserId])});
        batch.update(targetUserRef, {'followers': FieldValue.arrayUnion([currentUserId])});
      }

      await batch.commit();

      // Firestore'dan güncel verileri alalım ve UI'ı güncelleyelim
      // Bu, kullanıcı arayüzünün tamamında tutarlı olmasını sağlar
      final freshCurrentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final freshTargetUserDoc = await _firestore.collection('users').doc(targetUserId).get();

      if (freshCurrentUserDoc.exists && freshCurrentUserDoc.data() != null &&
          freshTargetUserDoc.exists && freshTargetUserDoc.data() != null) {

        final freshCurrentUser = UserModel.fromJson(freshCurrentUserDoc.data()!);
        final freshTargetUser = UserModel.fromJson(freshTargetUserDoc.data()!);

        // Kullanıcı listesindeki tüm nesneleri güncelleyelim
        final updatedAllUsers = _allUsers.map((user) {
          if (user.userId == currentUserId) {
            return freshCurrentUser;
          } else if (user.userId == targetUserId) {
            return freshTargetUser;
          }
          return user;
        }).toList();

        _allUsers = updatedAllUsers;

        // UI'daki diğer verileri de güncelleyelim
        _refreshFormsWithUpdatedUserData();

        // Son olarak, tüm değişikliklerin UI'a yansıması için bildirim gönderelim
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to toggle follow', e);
      rethrow;
    }
  }

// Bu yeni metot, ilgili tüm stream'lere dinamik olarak abone olarak daha güçlü gerçek zamanlı güncellemeler sağlar
  Future<void> setupDynamicListeners(String userId) async {
    // Kullanıcı için gerçek zamanlı takip dinleyicisi ekleyelim
    final userSubscription = _firestore.collection('users').doc(userId)
        .snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final updatedUser = UserModel.fromJson(snapshot.data()!);

        // Kullanıcı listesini güncelleyelim
        final userIndex = _allUsers.indexWhere((u) => u.userId == userId);
        if (userIndex >= 0) {
          final updatedUsers = List<UserModel>.from(_allUsers);
          updatedUsers[userIndex] = updatedUser;
          _allUsers = updatedUsers;

          // Formları kullanıcı verileriyle güncelleyelim
          _refreshFormsWithUpdatedUserData();

          notifyListeners();
        }
      }
    });

    _subscriptions.add(userSubscription);

    // Takip ettiği kullanıcıların formlarını dinlemek için de abonelikler ekleyebiliriz
    // Bu şekilde takip ettiği kullanıcılar değiştiğinde akış otomatik olarak güncellenecektir
  }

  // Add a comment with optimistic update and improved error handling
  Future<void> addComment({
    required String formId,
    required UserModel user,
    required String comment,
  }) async {
    if (formId.isEmpty || user.userId.isEmpty || comment.isEmpty) {
      debugPrint('Cannot add comment: missing required fields');
      return;
    }

    try {
      final now = DateTime.now();
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();

      final newComment = CommentModel(
        commentId: commentId,
        user: user,
        comment: comment,
        createdAt: now,
      );

      // Optimistic update for feed forms
      _feedForms = _feedForms.map((form) {
        if (form.formId == formId) {
          List<CommentModel> updatedComments = List.from(form.comments)..add(newComment);
          return FormModel(
            formId: form.formId,
            user: form.user,
            content: form.content,
            createdAt: form.createdAt,
            likes: form.likes,
            comments: updatedComments,
          );
        }
        return form;
      }).toList();

      // Optimistic update for my forms
      _myForms = _myForms.map((form) {
        if (form.formId == formId) {
          List<CommentModel> updatedComments = List.from(form.comments)..add(newComment);
          return FormModel(
            formId: form.formId,
            user: form.user,
            content: form.content,
            createdAt: form.createdAt,
            likes: form.likes,
            comments: updatedComments,
          );
        }
        return form;
      }).toList();

      notifyListeners();

      // Database update
      final commentRef = _firestore.collection('forms')
          .doc(formId)
          .collection('comments')
          .doc(commentId);

      await commentRef.set({
        'commentId': commentId,
        'userId': user.userId,
        'comment': comment,
        'createdAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      _handleError('Failed to add comment', e);
      rethrow;
    }
  }

  // Delete a form with optimistic update and improved error handling
  Future<void> deleteForm(String formId, String userId) async {
    if (formId.isEmpty || userId.isEmpty) {
      debugPrint('Cannot delete form: formId or userId is empty');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Optimistic update
      _myForms = _myForms.where((form) => form.formId != formId).toList();
      _feedForms = _feedForms.where((form) => form.formId != formId).toList();
      notifyListeners();

      final batch = _firestore.batch();
      final formRef = _firestore.collection('forms').doc(formId);

      // Delete the form
      batch.delete(formRef);

      // Remove from user's myForms
      batch.update(
        _firestore.collection('users').doc(userId),
        {'myForms': FieldValue.arrayRemove([formId])},
      );

      // Find users who liked this form and update them
      for (final user in _allUsers) {
        if (user.likedForms.contains(formId)) {
          batch.update(
            _firestore.collection('users').doc(user.userId),
            {'likedForms': FieldValue.arrayRemove([formId])},
          );
        }
      }

      // Delete all comments
      final comments = await formRef.collection('comments').get();
      for (final comment in comments.docs) {
        batch.delete(comment.reference);
      }

      await batch.commit();

      // Refresh the user data to ensure consistent UI
      final updatedUserDoc = await _firestore.collection('users').doc(userId).get();
      if (updatedUserDoc.exists && updatedUserDoc.data() != null) {
        final updatedUser = UserModel.fromJson(updatedUserDoc.data()!);

        // Update the user in _allUsers list
        final userIndex = _allUsers.indexWhere((u) => u.userId == userId);
        if (userIndex >= 0) {
          _allUsers[userIndex] = updatedUser;
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      await initialize(userId);
      _handleError('Failed to delete form', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle errors consistently
  void _handleError(String context, dynamic error) {
    final errorMessage = '$context: ${error.toString()}';
    _error = errorMessage;
    debugPrint(errorMessage);
    notifyListeners();
  }

  // Clean up when provider is disposed
  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }
}