import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/matching_service.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/bottom_nav.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/primary_button.dart';
// import 'package:skillsync/widgets/rating_row.dart'; // Unused based on previous code

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final MatchingService _matchingService = MatchingService();
  final DatabaseService _dbService = DatabaseService();
  String? _pendingMatchId; 
  
  List<UserModel> _matches = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSkillLoading = false;

  List<String> _currentTeaches = [];
  List<String> _currentLearns = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _pendingMatchId == null) {
      _pendingMatchId = args;
      _loadSpecificMatch(args);
    } else if (_matches.isEmpty && _isLoading) {
      _loadMatches();
    }
  }

  Future<void> _loadSpecificMatch(String matchId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final matchDoc = await FirebaseFirestore.instance.collection('Match').doc(matchId).get();

      if (!matchDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = matchDoc.data() as Map<String, dynamic>;
      final requesterRef = data['user_1_id'] as DocumentReference;
      final requesterProfile = await _dbService.getUserProfile(requesterRef.id);

      if (requesterProfile != null && mounted) {
        setState(() {
          _matches = [requesterProfile];
          _currentIndex = 0;
          _isLoading = false;
        });
        await _loadSkillsForCurrentMatch();
      }
    } catch (e) {
      debugPrint("!!! Error in _loadSpecificMatch: $e !!!");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentUid = context.read<UserProvider>().user?.id;

    if (currentUid != null) {
      final results = await _matchingService.findMatchesForUser(currentUid, findTeachers: true);

      if (mounted) {
        setState(() {
          _matches = results
              .where((u) => u.username.isNotEmpty || u.firstName.isNotEmpty)
              .toList();
          _isLoading = false;
        });

        if (_matches.isNotEmpty) {
          await _loadSkillsForCurrentMatch();
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSkillsForCurrentMatch() async {
    if (_currentIndex >= _matches.length) return;

    setState(() => _isSkillLoading = true);
    final targetUser = _matches[_currentIndex];

    try {
      final userSkillDocs = await _dbService.getUserSkills(targetUser.id);
      List<String> teaches = [];
      List<String> learns = [];

      for (var s in userSkillDocs) {
        final skillDoc = await FirebaseFirestore.instance.collection('Skill').doc(s.skillId).get();
        final String skillName = skillDoc.data()?['skill_name'] ?? s.skillId;

        if (s.teachingOrLearning == 'teaching') {
          teaches.add(skillName);
        } else {
          learns.add(skillName);
        }
      }

      if (mounted) {
        setState(() {
          _currentTeaches = teaches;
          _currentLearns = learns;
          _isSkillLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading skill names: $e");
      if (mounted) setState(() => _isSkillLoading = false);
    }
  }

  Future<void> _handleAccept() async {
    final currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;
    final targetUser = _matches[_currentIndex];

    if (_pendingMatchId != null) {
      setState(() => _isLoading = true);
      await _matchingService.acceptExistingMatch(_pendingMatchId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("It's a Match! Conversation created.")),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      return;
    }

    final commonSkillId = await _matchingService.getCommonSkill(currentUser.id, targetUser.id, true);

    if (commonSkillId != null) {
      await _matchingService.createMatchRequest(
        currentUserId: currentUser.id,
        targetUserId: targetUser.id,
        skillId: commonSkillId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request sent to ${targetUser.firstName}!")),
        );
      }
    }
    _nextCard();
  }

  void _nextCard() {
    setState(() {
      _currentIndex++;
      _currentTeaches = [];
      _currentLearns = [];
    });
    // Announce to screen reader that a new card is loaded? 
    // Usually standard focus management handles this, but changing state might require a re-announcement if using a LiveRegion.
    // For now, standard Flutter focus behavior is usually sufficient.
    
    if (_currentIndex < _matches.length) {
      _loadSkillsForCurrentMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasMatches = !_isLoading && _currentIndex < _matches.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Ensure Back Button in Custom AppBar is accessible
      appBar: const AppAppBar(title: 'Discover Matches', showBack: false),
      body: SafeArea(
        child: _isLoading
            ? Semantics(
                label: "Loading matches",
                child: const Center(child: CircularProgressIndicator())
              )
            : !hasMatches
            ? _buildEmptyState()
            : SingleChildScrollView( // Added scroll view to prevent overflow on small screens/large text
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🟦 MODERN MATCH CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ⭐ Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Group the Heart Icon and the Number so they are read together: "5 Likes"
                              MergeSemantics(
                                child: Semantics(
                                  label: "${_matches[_currentIndex].likesCount} Likes",
                                  child: Row(
                                    children: [
                                      // Exclude icon from individual reading since label covers it
                                      ExcludeSemantics(
                                        child: const Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_matches[_currentIndex].likesCount}',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Info Button with clear label and target size
                              Semantics(
                                button: true,
                                label: "View full profile",
                                child: IconButton(
                                  tooltip: "View Profile",
                                  icon: Icon(
                                    Icons.info_outline_rounded,
                                    color: colorScheme.secondary,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/profile',
                                      arguments: _matches[_currentIndex],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 👤 User Identity Section inside the Card
                          Semantics(
                            header: true, // Identify name as a header
                            child: Text(
                              (_matches[_currentIndex].firstName.isEmpty)
                                  ? _matches[_currentIndex].username
                                  : _matches[_currentIndex].fullName,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _matches[_currentIndex].userBio.isEmpty
                                ? "New to SkillSync! Tapping into new skills."
                                : _matches[_currentIndex].userBio,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 📊 Skills Exchange Interface
                          _isSkillLoading
                              ? Semantics(
                                  label: "Loading skills",
                                  child: const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Header Row
                                    Row(
                                      children: [
                                        _buildHeaderLabel('TEACHES'),
                                        _buildHeaderLabel('LEARNS'),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Divider(
                                        color: Color(0xFFF5F5F7),
                                        thickness: 1.5,
                                      ),
                                    ),
                                    // Dynamic Skill Rows
                                    if (_currentTeaches.isEmpty && _currentLearns.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          "Skills loading...",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    else
                                      ...List.generate(
                                        (_currentTeaches.length > _currentLearns.length
                                            ? _currentTeaches.length
                                            : _currentLearns.length),
                                        (index) {
                                          final left = index < _currentTeaches.length
                                              ? _currentTeaches[index]
                                              : '';
                                          final right = index < _currentLearns.length
                                              ? _currentLearns[index]
                                              : '';
                                          return _CompactSkillRow(
                                            left: left,
                                            right: right,
                                          );
                                        },
                                      ),
                                  ],
                                ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ✅ ACTION BUTTONS
                    PrimaryButton(
                      label: 'ACCEPT MATCH',
                      onPressed: _handleAccept,
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      // Ensure minimum touch target size (48x48)
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: _nextCard, 
                      child: Text(
                        'NOT RIGHT NOW',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          final routes = [
            '/home',
            '/notifications',
            '/explore',
            '/community',
            '/user_profile',
          ];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative icon, exclude from semantics
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search_rounded,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                "No Matches Yet",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't find any mentors matching your learning skills right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: "GO BACK HOME",
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String text) {
    return Expanded(
      // Mark as header so users can jump to the list
      child: Semantics(
        header: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _CompactSkillRow extends StatelessWidget {
  final String left;
  final String right;

  const _CompactSkillRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Explicit semantics for the row to clarify relationship
    // "Teaches [Left], Learns [Right]"
    final String semanticLabel = 
        (left.isNotEmpty ? "Teaches $left, " : "") + 
        (right.isNotEmpty ? "Learns $right" : "");

    return Semantics(
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                left,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Exclude arrow icon from semantics, the context is provided by the row label
            ExcludeSemantics(
              child: const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.black12),
            ),
            Expanded(
              child: Text(
                right,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}