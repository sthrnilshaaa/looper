part of 'settings_view.dart';

class _PremiumMaintainerSection extends StatelessWidget {
  const _PremiumMaintainerSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.maintainersAndDesigners,
      children: [
        _PremiumMaintainerRow(
          name: 'Nilesh Suthar',
          role: l10n.creatorAndMaintainer,
          avatar: 'assets/about/maintainer_avatar.png',
          github: 'https://github.com/SthrNilshaaa',
          telegram: 'https://t.me/neelshy',
          isLast: false,
        ),
        _PremiumMaintainerRow(
          name: 'Karan Suthar',
          role: l10n.designerAndMaintainer,
          avatar: 'assets/about/designer_avatar.png',
          github: 'https://github.com/sthrkaran',
          telegram: 'https://t.me/karanwhy',
          isLast: true,
        ),
      ],
    );
  }
}

class _PremiumMaintainerRow extends StatelessWidget {
  final String name;
  final String role;
  final String avatar;
  final String github;
  final String telegram;
  final bool isLast;

  const _PremiumMaintainerRow({
    required this.name,
    required this.role,
    required this.avatar,
    required this.github,
    required this.telegram,
    this.isLast = false,
  });

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white10,
                  backgroundImage: AssetImage(avatar),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/about/github_icon.svg',
                      width: 18,
                      height: 18,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _launchUrl(github);
                    },
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/about/telegram_icon.svg',
                      width: 18,
                      height: 18,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _launchUrl(telegram);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.8,
            color: Colors.white.withValues(alpha: 0.04),
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}
