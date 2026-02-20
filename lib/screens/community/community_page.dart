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

      floatingActionButton: Semantics(
        label: 'Create a new post',
        button: true,
        child: FloatingActionButton(
          tooltip: 'Create Post',
          onPressed: () => _showCreatePostDialog(
            context,
            currentUserId,
            currentUserName,
          ),
          child: const Icon(Icons.edit),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return Center(
              child: Text(
                'No posts yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
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

                      /// AUTHOR ROW
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Post author: $authorName',
                              child: Text(
                                authorName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),

                          if (authorId == currentUserId)
                            Semantics(
                              label: 'Delete this post',
                              button: true,
                              child: IconButton(
                                tooltip: 'Delete post',
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await _service.deletePost(postId: postId);
                                },
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// POST TEXT
                      Semantics(
                        label: 'Post content: $text',
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// LIKE + COMMENT
                      Row(
                        children: [
                          Semantics(
                            label: isLiked
                                ? 'Unlike post. $likeCount likes'
                                : 'Like post. $likeCount likes',
                            button: true,
                            child: IconButton(
                              tooltip: isLiked
                                  ? 'Unlike post'
                                  : 'Like post',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
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
                          ),

                          Semantics(
                            label: '$likeCount likes',
                            child: Text(
                              '$likeCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Semantics(
                            label: 'Open comments for this post',
                            button: true,
                            child: TextButton.icon(
                              icon: const Icon(Icons.comment_outlined),
                              label: Text(
                                'Comment',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge,
                              ),
                              onPressed: () => _openCommentsSheet(
                                context,
                                postId,
                                authorName,
                                text,
                                currentUserId,
                                currentUserName,
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
        },
      ),
    );
  }

  /// CREATE POST
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
        content: Semantics(
          label: 'Post text input field',
          textField: true,
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write something...',
              border: OutlineInputBorder(),
            ),
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

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  /// COMMENTS SHEET
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  postText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                      return Center(
                        child: Text(
                          'No comments yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i].data();
                        final commentId = comments[i].id;
                        final commentAuthorId =
                            c['authorId'] ?? '';

                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c['authorName'] ?? 'Unknown',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (commentAuthorId ==
                                  currentUserId)
                                IconButton(
                                  tooltip: 'Delete comment',
                                  constraints:
                                      const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await _service.deleteComment(
                                      postId: postId,
                                      commentId: commentId,
                                    );
                                  },
                                ),
                            ],
                          ),
                          subtitle: Text(
                            c['text'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
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
                    tooltip: 'Send comment',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (commentController.text
                          .trim()
                          .isEmpty) return;

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