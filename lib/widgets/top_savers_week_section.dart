import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../screens/user_profile_screen.dart';
import 'user_avatar.dart';

/// Seção com 5 slots dos perfis que mais salvaram produtos na semana.
class TopSaversWeekSection extends StatefulWidget {
  const TopSaversWeekSection({super.key});

  @override
  State<TopSaversWeekSection> createState() => _TopSaversWeekSectionState();
}

class _TopSaversWeekSectionState extends State<TopSaversWeekSection> {
  static const int _slotCount = 5;

  final FirebaseService _firebaseService = FirebaseService();
  List<UserModel?> _slots = List<UserModel?>.filled(_slotCount, null);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopSavers();
  }

  Future<void> _loadTopSavers() async {
    try {
      final users =
          await _firebaseService.getTopSaversOfWeek(limit: _slotCount);
      if (!mounted) return;
      setState(() {
        _slots = List<UserModel?>.generate(
          _slotCount,
          (index) => index < users.length ? users[index] : null,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slots = List<UserModel?>.filled(_slotCount, null);
        _isLoading = false;
      });
    }
  }

  Future<void> _openProfile(UserModel user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Top da semana',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF6B2C5C),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Quem mais salvou produtos',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          Row(
            children: List.generate(_slotCount, (index) {
              final user = _slots[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == _slotCount - 1 ? 0 : 4,
                  ),
                  child: _SaverSlot(
                    rank: index + 1,
                    user: user,
                    onTap: user == null ? null : () => _openProfile(user),
                  ),
                ),
              );
            }),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SaverSlot extends StatelessWidget {
  final int rank;
  final UserModel? user;
  final VoidCallback? onTap;

  const _SaverSlot({
    required this.rank,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUser = user != null;
    final displayName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : (user?.username ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUser
                            ? const Color(0xFF8B7FB8)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: hasUser
                        ? UserAvatar(
                            name: displayName.isNotEmpty
                                ? displayName
                                : '?',
                            photoUrl: user!.photoUrl,
                            radius: 26,
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.grey.shade400,
                              size: 28,
                            ),
                          ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasUser
                            ? const Color(0xFF6B2C5C)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasUser
                    ? '@${user!.username}'
                    : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: hasUser ? FontWeight.w600 : FontWeight.w400,
                  color: hasUser
                      ? const Color(0xFF6B2C5C)
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
