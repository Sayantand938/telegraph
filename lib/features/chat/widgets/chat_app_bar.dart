import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();

    return AppBar(
      titleSpacing: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF202C33),
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
          const SizedBox(width: 10),
          _StatusText(controller: controller),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.videocam)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          onSelected: (value) {
            if (value == 'ai_toggle') {
              controller.toggleAi(!controller.isAiEnabled);
            }
          },
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ai_toggle',
              child: Row(
                children: [
                  Icon(
                    controller.isAiEnabled
                        ? Icons.auto_awesome
                        : Icons.auto_awesome_outlined,
                    color: controller.isAiEnabled
                        ? const Color(0xFF00A884)
                        : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    controller.isAiEnabled
                        ? "AI Analysis: ON"
                        : "AI Analysis: OFF",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _StatusText extends StatelessWidget {
  final ChatController controller;
  const _StatusText({required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusText = controller.isReady
        ? (controller.initError != null
              ? 'degraded'
              : (controller.isTyping ? 'thinking...' : 'online'))
        : 'initializing...';

    final statusColor = controller.isReady
        ? (controller.initError != null
              ? Colors.orange
              : (controller.isTyping
                    ? Colors.white70
                    : const Color(0xFF00A884)))
        : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Alison',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (controller.isAiEnabled)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFF00A884),
                ),
              ),
          ],
        ),
        Text(statusText, style: TextStyle(fontSize: 12, color: statusColor)),
      ],
    );
  }
}
