/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {

  @override
  void initState() {
    super.initState();
    addSamplePostsIfEmpty();
  }

  // ✅ This adds sample posts ONLY if database is empty
  Future<void> addSamplePostsIfEmpty() async {
    final firestore = FirebaseFirestore.instance;

    final snapshot =
        await firestore.collection("community_posts").get();

    if (snapshot.docs.isEmpty) {
      await firestore.collection("community_posts").add({
        "username": "Manvir",
        "title": "Welcome to SkillSync!",
        "content": "This is our new community feature 🚀",
        "timestamp": Timestamp.now(),
      });

      await firestore.collection("community_posts").add({
        "username": "Judy",
        "title": "Study Group Tomorrow",
        "content": "Anyone free for database revision at 3pm?",
        "timestamp": Timestamp.now(),
      });

      await firestore.collection("community_posts").add({
        "username": "Alex",
        "title": "Flutter Tip",
        "content": "Enable virtualization if emulator crashes.",
        "timestamp": Timestamp.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(
              child: Text("No posts yet."),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {

              final post = posts[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        post['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        post['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(post['content']),
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
}
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/services/community_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _service = CommunityService();

  // ✅ Demo user (no auth needed)
  // If you have FirebaseAuth, you can replace these with currentUser uid/name.
  final String _demoUserId = 'demo_user_1';
  final String _demoUserName = 'Manvir';

  // Adds demo posts ONLY when collection is empty (optional)
  Future<void> addSamplePostsIfEmpty() async {
    final snap = await FirebaseFirestore.instance.collection('community_posts').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    await _service.createPost(
      text: 'Welcome to SkillSync community 🚀',
      authorId: 'demo_user_1',
      authorName: 'Manvir',
    );

    await _service.createPost(
      text: 'Anyone up for a quick revision session later?',
      authorId: 'demo_user_2',
      authorName: 'Judy',
    );

    await _service.createPost(
      text: 'Tip: Use StreamBuilder with Firestore snapshots for real-time UI.',
      authorId: 'demo_user_3',
      authorName: 'Alex',
    );
  }

  @override
  void initState() {
    super.initState();
    addSamplePostsIfEmpty();
  }

  Future<void> _showCreatePostDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.createPost(
                text: controller.text,
                authorId: _demoUserId,
                authorName: _demoUserName,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _openCommentsSheet({
    required String postId,
    required String postAuthor,
    required String postText,
  }) {
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
                title: Text(postAuthor, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(postText),
              ),
              const Divider(),
              Flexible(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.streamComments(postId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!.docs;
                    if (comments.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i].data();
                        return ListTile(
                          dense: true,
                          title: Text(c['authorName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      await _service.addComment(
                        postId: postId,
                        text: commentController.text,
                        authorId: _demoUserId,
                        authorName: _demoUserName,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.edit),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
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
              final String authorName = (data['authorName'] ?? 'Unknown').toString();
              final String authorId = (data['authorId'] ?? '').toString();
              final String text = (data['text'] ?? '').toString();

              final int likeCount = (data['likeCount'] ?? 0) as int;
              final List likedBy = (data['likedBy'] ?? []) as List;
              final bool isLiked = likedBy.contains(_demoUserId);

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (author + delete)
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
                          IconButton(
                            tooltip: 'Delete post',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              // Only allow delete if you are the author (demo)
                              if (authorId != _demoUserId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("You can only delete your own posts.")),
                                );
                                return;
                              }
                              await _service.deletePost(postId: postId);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Post text
                      Text(text, style: const TextStyle(fontSize: 15)),

                      const SizedBox(height: 12),

                      // Actions: Like + Comment
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Like',
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                            onPressed: () async {
                              await _service.toggleLike(postId: postId, userId: _demoUserId);
                            },
                          ),
                          Text('$likeCount'),

                          const SizedBox(width: 16),

                          TextButton.icon(
                            onPressed: () => _openCommentsSheet(
                              postId: postId,
                              postAuthor: authorName,
                              postText: text,
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
}
