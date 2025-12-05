import 'package:flutter/material.dart';

class TextSizeSheet extends StatefulWidget {
  final double currentSize;
  final Function(double size) onSizeChanged;

  const TextSizeSheet({
    super.key,
    required this.currentSize,
    required this.onSizeChanged,
  });

  @override
  State<TextSizeSheet> createState() => _TextSizeSheetState();
}

class _TextSizeSheetState extends State<TextSizeSheet> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final sheetColor = isDark 
        ? const Color(0xFF23201E) 
        : theme.colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Text Size',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 32),
          
          // Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Text(
              'The quick brown fox jumps over the lazy dog.',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: _fontSize,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SizeButton(
                icon: Icons.text_decrease_rounded,
                onTap: () {
                  if (_fontSize > 12) {
                    setState(() => _fontSize -= 1);
                    widget.onSizeChanged(_fontSize);
                  }
                },
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_fontSize.toInt()}',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _SizeButton(
                icon: Icons.text_increase_rounded,
                onTap: () {
                  if (_fontSize < 32) {
                    setState(() => _fontSize += 1);
                    widget.onSizeChanged(_fontSize);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.colorScheme.secondary,
              inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
              thumbColor: theme.colorScheme.secondary,
              overlayColor: theme.colorScheme.secondary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _fontSize,
              min: 12,
              max: 32,
              divisions: 20,
              onChanged: (value) {
                setState(() => _fontSize = value);
                widget.onSizeChanged(value);
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Small',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Large',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () {
              setState(() => _fontSize = 16);
              widget.onSizeChanged(16);
            },
            child: Text(
              'Reset to Default',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SizeButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
      ),
    );
  }
}