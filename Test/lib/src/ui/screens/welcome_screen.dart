// lib/src/ui/screens/welcome_screen.dart
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(), // no back on the landing page
        title: Row(
          children: [
            const Icon(Icons.recycling, color: Colors.green),
            const SizedBox(width: 8),
            Text('ReuseHub', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            'Share, Reuse, Sustain:\nYour Community Reuse Platform',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reuse Hub connects donors and seekers to exchange reusable goods for free, '
                'promoting sustainability and reducing waste in your community.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Get Started'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/search'),
                child: const Text('Browse Categories'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // … you can add your category cards/hero art here
        ],
      ),
    );
  }
}
