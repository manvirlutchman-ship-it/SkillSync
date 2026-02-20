import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import '/services/community_service.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunityService _service = CommunityService();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String currentUserId = currentUser.id;
    final String currentUserName =
        "${currentUser.firstName} ${currentUser.lastName}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),

      // ✅ Bottom Navigation
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          final routes = [
            '/home',
            '/notifications',
            '/explore',
            '/community',
            '/user_profile'
          ];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(
          context,
          currentUserId,
          currentUserName,
        ),
        child: const Icon(Icons.edit),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data();

              final String postId = doc.id;
              final String authorName =
                  (data['authorName'] ?? 'Unknown').toString();
              final String authorId =
                  (data['authorId'] ?? '').toString();
              final String text =
                  (data['text'] ?? '').toString();

              final int likeCount =
                  (data['likeCount'] ?? 0) as int;
              final List likedBy =
                  (data['likedBy'] ?? []) as List;
              final bool isLiked =
                  likedBy.contains(currentUserId);

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔹 Author + Delete
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          // ✅ Only show delete if user owns post
                          if (authorId == currentUserId)
                            IconButton(
                              tooltip: 'Delete post',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await _service.deletePost(postId: postId);
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Post text
                      Text(
                        text,
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 Like + Comment
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  isLiked ? Colors.red : null,
                            ),
                            onPressed: () async {
                              await _service.toggleLike(
                                postId: postId,
                                userId: currentUserId,
                              );
                            },
                          ),

                          Text('$likeCount'),

                          const SizedBox(width: 16),

                          TextButton.icon(
                            onPressed: () => _openCommentsSheet(
                              context,
                              postId,
                              authorName,
                              text,
                              currentUserId,
                              currentUserName,
                            ),
                            icon: const Icon(Icons.comment_outlined),
                            label: const Text('Comment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ CREATE POST
  Future<void> _showCreatePostDialog(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Post'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write something...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await _service.createPost(
                text: controller.text.trim(),
                authorId: userId,
                authorName: userName,
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  
  // ✅ COMMENTS SHEET
  void _openCommentsSheet(
    BuildContext context,
    String postId,
    String postAuthor,
    String postText,
    String currentUserId,
    String currentUserName,
  ) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                title: Text(
                  postAuthor,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(postText),
              ),

              const Divider(),

              Flexible(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.streamComments(postId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final comments = snapshot.data!.docs;

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('No comments yet.'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i].data();
                        final commentId = comments[i].id;
                        final commentAuthorId = c['authorId'] ?? '';

                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c['authorName'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),

                              // ✅ Show delete only if current user owns comment
                              if (commentAuthorId == currentUserId)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () async {
                                    await _service.deleteComment(
                                      postId: postId,
                                      commentId: commentId,
                                    );
                                  },
                                ),
                            ],
                          ),
                          subtitle: Text(c['text'] ?? ''),
                        );

                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;

                      await _service.addComment(
                        postId: postId,
                        text: commentController.text.trim(),
                        authorId: currentUserId,
                        authorName: currentUserName,
                      );

                      commentController.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
