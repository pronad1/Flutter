import 'package:flutter/material.dart';
import 'chatbot_dialog.dart';

/// Draggable floating chatbot button that appears on all screens
/// Shows a chat icon that opens the AI assistant when tapped
/// Can be dragged to any position on the screen
class FloatingChatbotButton extends StatefulWidget {
  const FloatingChatbotButton({super.key});

  @override
  State<FloatingChatbotButton> createState() => _FloatingChatbotButtonState();
}

class _FloatingChatbotButtonState extends State<FloatingChatbotButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  
  // Position tracking for dragging
  double _xPosition = 0;
  double _yPosition = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize position to bottom-right on first build
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      _xPosition = size.width - 72; // 56 (button width) + 16 (padding)
      _yPosition = size.height - 136; // Position above bottom nav
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openChatbot() {
    setState(() => _isExpanded = true);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ChatbotDialog(),
    ).then((_) {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: Draggable(
        feedback: _buildButton(isDragging: true),
        childWhenDragging: Container(), // Hide original while dragging
        onDragEnd: (details) {
          setState(() {
            // Update position, keeping button within screen bounds
            _xPosition = (details.offset.dx).clamp(0.0, size.width - 56);
            _yPosition = (details.offset.dy).clamp(0.0, size.height - 56);
          });
        },
        child: GestureDetector(
          onTap: _openChatbot,
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton({bool isDragging = false}) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.5 : 0.3),
              blurRadius: isDragging ? 16 : 12,
              offset: Offset(0, isDragging ? 6 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                _isExpanded ? Icons.close : Icons.chat_bubble_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            // Online indicator
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
