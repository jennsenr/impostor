import 'package:flutter/material.dart';

import '../../../../../shared/presentation/theme/app_theme.dart';

class GameCornerBrackets extends StatelessWidget {
  const GameCornerBrackets({super.key});

  static const Color _color = AppTheme.neonCyan;
  static const double _size = 28;
  static const double _thickness = 2.5;

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: GameBracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: true,
            isLeft: true,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GameBracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: true,
            isLeft: false,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: GameBracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: false,
            isLeft: true,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GameBracket(
            color: _color,
            size: _size,
            thickness: _thickness,
            isTop: false,
            isLeft: false,
          ),
        ),
      ],
    );
  }
}

class GameBracket extends StatelessWidget {
  final Color color;
  final double size;
  final double thickness;
  final bool isTop;
  final bool isLeft;

  const GameBracket({
    super.key,
    required this.color,
    required this.size,
    required this.thickness,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: size, height: thickness, color: color),
          ),
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: thickness, height: size, color: color),
          ),
        ],
      ),
    );
  }
}
