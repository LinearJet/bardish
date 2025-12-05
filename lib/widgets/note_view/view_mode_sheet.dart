import 'package:flutter/material.dart';

enum ViewMode { vertical, horizontal, autoScroll, autoFlip }

class ViewModeSheet extends StatefulWidget {
  final ViewMode currentMode;
  final double autoScrollSpeed;
  final double autoFlipInterval;
  final Function(ViewMode mode) onModeChanged;
  final Function(double speed) onAutoScrollSpeedChanged;
  final Function(double interval) onAutoFlipIntervalChanged;

  const ViewModeSheet({
    super.key,
    required this.currentMode,
    required this.autoScrollSpeed,
    required this.autoFlipInterval,
    required this.onModeChanged,
    required this.onAutoScrollSpeedChanged,
    required this.onAutoFlipIntervalChanged,
  });

  @override
  State<ViewModeSheet> createState() => _ViewModeSheetState();
}

class _ViewModeSheetState extends State<ViewModeSheet> {
  late ViewMode _selectedMode;
  late double _scrollSpeed;
  late double _flipInterval;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
    _scrollSpeed = widget.autoScrollSpeed;
    _flipInterval = widget.autoFlipInterval;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'View Mode',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 20),
          
          _ModeOption(
            icon: Icons.swap_vert_rounded,
            title: 'Vertical Scroll',
            subtitle: 'Default reading mode',
            isSelected: _selectedMode == ViewMode.vertical,
            onTap: () {
              setState(() => _selectedMode = ViewMode.vertical);
              widget.onModeChanged(ViewMode.vertical);
            },
          ),
          
          _ModeOption(
            icon: Icons.swap_horiz_rounded,
            title: 'Horizontal Pages',
            subtitle: 'Swipe left/right to navigate',
            isSelected: _selectedMode == ViewMode.horizontal,
            onTap: () {
              setState(() => _selectedMode = ViewMode.horizontal);
              widget.onModeChanged(ViewMode.horizontal);
            },
          ),
          
          _ModeOption(
            icon: Icons.slow_motion_video_rounded,
            title: 'Auto Scroll',
            subtitle: 'Hands-free reading',
            isSelected: _selectedMode == ViewMode.autoScroll,
            onTap: () {
              setState(() => _selectedMode = ViewMode.autoScroll);
              widget.onModeChanged(ViewMode.autoScroll);
            },
          ),
          
          if (_selectedMode == ViewMode.autoScroll) ...[
            const SizedBox(height: 12),
            _SpeedSlider(
              label: 'Scroll Speed',
              value: _scrollSpeed,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              displayValue: '${_scrollSpeed.toStringAsFixed(1)}x',
              onChanged: (value) {
                setState(() => _scrollSpeed = value);
                widget.onAutoScrollSpeedChanged(value);
              },
            ),
          ],
          
          _ModeOption(
            icon: Icons.auto_stories_rounded,
            title: 'Auto Flip',
            subtitle: 'Automatic page turning',
            isSelected: _selectedMode == ViewMode.autoFlip,
            onTap: () {
              setState(() => _selectedMode = ViewMode.autoFlip);
              widget.onModeChanged(ViewMode.autoFlip);
            },
          ),
          
          if (_selectedMode == ViewMode.autoFlip) ...[
            const SizedBox(height: 12),
            _SpeedSlider(
              label: 'Flip Interval',
              value: _flipInterval,
              min: 2.0,
              max: 30.0,
              divisions: 14,
              displayValue: '${_flipInterval.toInt()}s',
              onChanged: (value) {
                setState(() => _flipInterval = value);
                widget.onAutoFlipIntervalChanged(value);
              },
            ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? selectedColor 
                    : theme.colorScheme.onSurface.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                  ? selectedColor.withOpacity(0.1) 
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? selectedColor : theme.iconTheme.color,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected 
                              ? selectedColor 
                              : theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: selectedColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final Function(double) onChanged;

  const _SpeedSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.colorScheme.secondary,
              inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
              thumbColor: theme.colorScheme.secondary,
              overlayColor: theme.colorScheme.secondary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}