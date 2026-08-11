import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SpeedDialOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const SpeedDialOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialOption> options;
  final IconData mainIcon;
  final Color mainColor;

  const SpeedDialFab({
    super.key,
    required this.options,
    this.mainIcon = Icons.add,
    this.mainColor = AppColors.accent,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          for (int i = 0; i < widget.options.length; i++)
            _buildOptionItem(widget.options[i], i),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          backgroundColor: _isOpen ? AppColors.surfaceElevated : widget.mainColor,
          elevation: 4,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isOpen ? Icons.close : widget.mainIcon,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(SpeedDialOption option, int index) {
    final color = option.color ?? AppColors.accent;
    return FadeTransition(
      opacity: _expandAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_expandAnimation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  option.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'speed_dial_${option.label}_$index',
                backgroundColor: color,
                elevation: 3,
                onPressed: () {
                  _toggle();
                  option.onTap();
                },
                child: Icon(option.icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
