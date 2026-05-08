import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/audio_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('AUDIO'),
                      _buildAudioSection(),
                      const SizedBox(height: 24),
                      _sectionLabel('GAME'),
                      _buildGameSection(context),
                      const SizedBox(height: 24),
                      _sectionLabel('SUPPORT'),
                      _buildSupportSection(context),
                      const SizedBox(height: 24),
                      _sectionLabel('ABOUT'),
                      _buildAboutSection(),
                      const SizedBox(height: 32),
                      _buildFooter(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'SETTINGS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: const Color(0xFF1E1E30))),
        ],
      ),
    );
  }

  // ── Audio section ─────────────────────────────────────────────────────────────
  Widget _buildAudioSection() {
    return _SettingsCard(
      children: [
        _ToggleRow(
          icon: Icons.music_note_rounded,
          iconColor: const Color(0xFF4CC9F0),
          title: 'Background Music',
          subtitle: 'Ambient puzzle music',
          value: AudioManager().musicEnabled,
          onChanged: (v) => setState(() => AudioManager().toggleMusic()),
        ),
        _divider(),
        _ToggleRow(
          icon: Icons.volume_up_rounded,
          iconColor: const Color(0xFF80FFDB),
          title: 'Sound Effects',
          subtitle: 'Slide, shake & complete sounds',
          value: AudioManager().soundEnabled,
          onChanged: (v) => setState(() => AudioManager().toggleSound()),
        ),
        _divider(),
        _ToggleRow(
          icon: Icons.vibration_rounded,
          iconColor: const Color(0xFFFFD166),
          title: 'Haptics',
          subtitle: 'Vibration on tap and completion',
          value: true, // wire up to prefs if needed
          onChanged: (v) {},
        ),
      ],
    );
  }

  // ── Game section ──────────────────────────────────────────────────────────────
  Widget _buildGameSection(BuildContext context) {
    return _SettingsCard(
      children: [
        _ActionRow(
          icon: Icons.share_rounded,
          iconColor: const Color(0xFFA29BFE),
          title: 'Share Game',
          subtitle: 'Invite friends to play Tap Away',
          onTap: () => _shareGame(),
        ),
        _divider(),
        _ActionRow(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFFD60A),
          title: 'Rate the Game',
          subtitle: 'Love it? Leave us a 5★ review',
          onTap: () => _rateGame(),
        ),
        _divider(),
        _ActionRow(
          icon: Icons.restore_rounded,
          iconColor: const Color(0xFFFF6B9D),
          title: 'Reset Progress',
          subtitle: 'Clear all levels and stars',
          onTap: () => _confirmReset(context),
        ),
      ],
    );
  }

  // ── Support section ───────────────────────────────────────────────────────────
  Widget _buildSupportSection(BuildContext context) {
    return _SettingsCard(
      children: [
        _ActionRow(
          icon: Icons.bug_report_rounded,
          iconColor: const Color(0xFFFF9F1C),
          title: 'Send Feedback',
          subtitle: 'Report bugs or suggest features',
          onTap: () => _sendFeedback(),
        ),
        _divider(),
        _ActionRow(
          icon: Icons.help_rounded,
          iconColor: const Color(0xFF2EC4B6),
          title: 'How to Play',
          subtitle: 'Learn the rules and mechanics',
          onTap: () => _showHowToPlay(context),
        ),
        _divider(),
        _ActionRow(
          icon: Icons.privacy_tip_rounded,
          iconColor: const Color(0xFF9B5DE5),
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          onTap: () => _openUrl('https://yourwebsite.com/privacy'),
        ),
        _divider(),
        _ActionRow(
          icon: Icons.gavel_rounded,
          iconColor: const Color(0xFF607D8B),
          title: 'Terms of Service',
          subtitle: 'Usage terms and conditions',
          onTap: () => _openUrl('https://yourwebsite.com/terms'),
        ),
      ],
    );
  }

  // ── About section ─────────────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return _SettingsCard(
      children: [
        _InfoRow(
          icon: Icons.apps_rounded,
          iconColor: const Color(0xFF4361EE),
          title: 'App Name',
          value: 'Tap Away — Arrow Puzzle',
        ),
        _divider(),
        _InfoRow(
          icon: Icons.tag_rounded,
          iconColor: const Color(0xFF4CC9F0),
          title: 'Version',
          value: '2.0.0 (build 1)',
        ),
        _divider(),
        _InfoRow(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF80FFDB),
          title: 'Developer',
          value: 'Your Studio Name',
        ),
        _divider(),
        _InfoRow(
          icon: Icons.mail_rounded,
          iconColor: const Color(0xFFFFD166),
          title: 'Contact',
          value: 'support@yourgame.com',
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4361EE), Color(0xFF7B2FBE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                '→',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'TAP AWAY',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Made with ❤️  •  v2.0.0',
            style: TextStyle(color: Color(0xFF3A3A5A), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFF1E1E30), indent: 52);

  // ── Actions ───────────────────────────────────────────────────────────────────
  void _shareGame() {
    // Use share_plus package in production:
    // Share.share('I\'m playing Tap Away! Download it here: https://yourlink.com');
    Clipboard.setData(
      const ClipboardData(
        text: 'Check out Tap Away — Arrow Puzzle! https://yourlink.com',
      ),
    );
    _toast('Link copied to clipboard!');
  }

  void _rateGame() {
    // Use url_launcher in production:
    // launchUrl(Uri.parse('market://details?id=your.package.name'));
    _toast('Opening store... (add url_launcher package)');
  }

  void _sendFeedback() {
    // Use url_launcher: launchUrl(Uri.parse('mailto:support@yourgame.com?subject=Feedback'));
    _toast('Opening email... (add url_launcher package)');
  }

  void _openUrl(String url) {
    _toast('Opening: $url\n(add url_launcher package)');
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Progress?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will delete all your levels, stars and progress. This cannot be undone.',
          style: TextStyle(color: Color(0xFF8B8FA8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toast('Progress reset!');
              // Call game.resetProgress() from provider here
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFFFF4D6D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HowToPlaySheet(),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1E1E38),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Reusable setting components ───────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4361EE),
            inactiveTrackColor: const Color(0xFF2A2A45),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF3A3A5A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ── How to Play bottom sheet ───────────────────────────────────────────────────
class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'HOW TO PLAY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _step('1', 'Tap an arrow block to slide it off the board.'),
          _step('2', 'A block can only move if nothing is blocking its path.'),
          _step(
            '3',
            'Tap a blocked block — it shakes to tell you it can\'t move.',
          ),
          _step('4', 'Clear all blocks to complete the level.'),
          _step('5', 'Use fewer moves to earn 3 stars ★★★'),
          _step('6', 'Spend 3 stars on a hint to highlight a movable block.'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4361EE).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4361EE).withOpacity(0.5),
              ),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Color(0xFF4CC9F0),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
