import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/matching_service.dart';
import 'package:skillsync/services/database_service.dart'; // Needed for skill lookups
import 'package:skillsync/widgets/bottom_nav.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/primary_button.dart';
import 'package:skillsync/widgets/rating_row.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final MatchingService _matchingService = MatchingService();
  final DatabaseService _dbService = DatabaseService();
  String?
  _pendingMatchId; // 🟢 Add this to track if we came from a notification
  // State Variables
  List<UserModel> _matches = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSkillLoading = false;

  // Cache for the current card's skills
  List<String> _currentTeaches = [];
  List<String> _currentLearns = [];

  @override
  void initState() {
    super.initState();
    // We don't call _loadMatches here anymore, we do it in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🟢 Check if a Match ID was passed from the Notifications screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _pendingMatchId == null) {
      _pendingMatchId = args;
      _loadSpecificMatch(args); // Load only the requester
    } else if (_matches.isEmpty && _isLoading) {
      _loadMatches(); // Load discovery list as normal
    }
  }

  // 🟢 New method to load the person who requested YOU
  Future<void> _loadSpecificMatch(String matchId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      debugPrint("!!! Loading Match Document: $matchId !!!");
      final matchDoc = await FirebaseFirestore.instance.collection('Match').doc(matchId).get();
      
      if (!matchDoc.exists) {
        debugPrint("!!! Match document does not exist !!!");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Identify the other user (User 1 is usually the requester)
      final data = matchDoc.data() as Map<String, dynamic>;
      final requesterRef = data['user_1_id'] as DocumentReference;

      final requesterProfile = await _dbService.getUserProfile(requesterRef.id);

      if (requesterProfile != null && mounted) {
        setState(() {
          _matches = [requesterProfile];
          _currentIndex = 0;
          _isLoading = false;
        });
        // Now load the skill names for this specific user
        await _loadSkillsForCurrentMatch();
      }
    } catch (e) {
      debugPrint("!!! Error in _loadSpecificMatch: $e !!!");
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // 1. Fetch matches and filter out "Empty" users
  Future<void> _loadMatches() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentUid = context.read<UserProvider>().user?.id;

    if (currentUid != null) {
      // Find potential matches
      final results = await _matchingService.findMatchesForUser(
        currentUid,
        findTeachers: true,
      );

      if (mounted) {
        setState(() {
          // 🟢 SENIOR FIX: Only show users who have at least a First Name or Username
          // This eliminates "Ghost Cards" from users who just registered but didn't onboard.
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

  // 2. Fetch skill names (Resolving ID -> Name)
  Future<void> _loadSkillsForCurrentMatch() async {
    if (_currentIndex >= _matches.length) return;

    setState(() => _isSkillLoading = true);
    final targetUser = _matches[_currentIndex];

    try {
      // Get the bridge documents between the user and the skills
      final userSkillDocs = await _dbService.getUserSkills(targetUser.id);

      List<String> teaches = [];
      List<String> learns = [];

      // Senior Tip: Fetch all skill names in parallel for speed
      for (var s in userSkillDocs) {
        // Resolve the Skill Name from the 'Skill' collection
        final skillDoc = await FirebaseFirestore.instance
            .collection('Skill')
            .doc(s.skillId)
            .get();

        // Extract the name, fallback to the ID if the name is missing
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

  // 3. Handle Accept
  Future<void> _handleAccept() async {
    final currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;

    final targetUser = _matches[_currentIndex];

    // 🟢 LOGIC: If we have a _pendingMatchId, we are RESPONDING to a request
    if (_pendingMatchId != null) {
      setState(() => _isLoading = true);

      // 1. Update Match to 'matched' and create Conversation
      await _matchingService.acceptExistingMatch(_pendingMatchId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("It's a Match! Conversation created.")),
        );
        // Clear history and go home (where the new chat will appear)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      return;
    }

    // 🔵 LOGIC: If no _pendingMatchId, we are STARTING a new request (Discovery)
    final commonSkillId = await _matchingService.getCommonSkill(
      currentUser.id,
      targetUser.id,
      true,
    );

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

  // 4. Handle Skip
  void _nextCard() {
    setState(() {
      _currentIndex++;
      _currentTeaches = [];
      _currentLearns = [];
    });
    // Load skills for the NEW card
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
      appBar: const AppAppBar(title: 'Discover Matches', showBack: true),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasMatches
            ? _buildEmptyState()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              const RatingRow(rating: 5), // Placeholder rating
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline_rounded,
                                  color: colorScheme.secondary,
                                ),
                                onPressed: () {
                                  // Pass the user object to the profile screen if needed
                                  Navigator.pushNamed(
                                    context,
                                    '/profile',
                                    arguments: _matches[_currentIndex],
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 👤 User Identity Section inside the Card
                          Text(
                            // 🟢 FALLBACK: If firstName is empty, use username.
                            // If that's empty, use "SkillSync User"
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
                          const SizedBox(height: 4),
                          Text(
                            // 🟢 FALLBACK: Bio
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
                              ? const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Column(
                                  children: [
                                    Row(
                                      children: [
                                        _buildHeaderLabel('TEACHES'),
                                        _buildHeaderLabel('LEARNS'),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Divider(
                                        color: Color(0xFFF5F5F7),
                                        thickness: 1.5,
                                      ),
                                    ),
                                    // Dynamic Skill Rows
                                    if (_currentTeaches.isEmpty &&
                                        _currentLearns.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          "Skills loading...",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    else
                                      ...List.generate(
                                        (_currentTeaches.length >
                                                _currentLearns.length
                                            ? _currentTeaches.length
                                            : _currentLearns.length),
                                        (index) {
                                          final left =
                                              index < _currentTeaches.length
                                              ? _currentTeaches[index]
                                              : '';
                                          final right =
                                              index < _currentLearns.length
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
                      onPressed: _nextCard, // Skip logic
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
            Container(
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
            const SizedBox(height: 24),
            Text(
              "No Matches Yet",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
    return Padding(
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
          const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.black12),
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
    );
  }
}
