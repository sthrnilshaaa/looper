part of 'android_equalizer_screen.dart';

class _CustomFilterInput extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSubmitted;
  final Color accentColor;

  const _CustomFilterInput({
    required this.initialValue,
    required this.onSubmitted,
    required this.accentColor,
  });

  @override
  State<_CustomFilterInput> createState() => _CustomFilterInputState();
}

class _CustomFilterInputState extends State<_CustomFilterInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: AppFonts.jostStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.rawFilterParametersHint,
              hintStyle: AppFonts.jostStyle(
                fontSize: 13,
                color: Colors.white30,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: widget.onSubmitted,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onSubmitted(_controller.text);
          },
          icon: Icon(LucideIcons.check, color: widget.accentColor),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
