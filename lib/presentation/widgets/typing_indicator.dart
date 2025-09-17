import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _Dot(),
              SizedBox(width: 4),
              _Dot(delay: Duration(milliseconds: 200)),
              SizedBox(width: 4),
              _Dot(delay: Duration(milliseconds: 400)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  final Duration delay;
  const _Dot({this.delay = Duration.zero});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: const CircleAvatar(radius: 4, backgroundColor: Colors.black54),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
