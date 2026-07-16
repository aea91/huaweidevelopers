import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/github_demo.dart';
import '../theme/app_chrome.dart';

class GitHubDemoCard extends StatefulWidget {
  final GitHubDemo demo;

  const GitHubDemoCard({super.key, required this.demo});

  @override
  State<GitHubDemoCard> createState() => _GitHubDemoCardState();
}

class _GitHubDemoCardState extends State<GitHubDemoCard> {
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final images = demo.screenshotUrls;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppChrome.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: images.isEmpty
                  ? Container(
                      color: const Color(0xFFF1F5F9),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 42, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No screenshot in README',
                            style: AppChrome.body(fontSize: 12, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFFF1F5F9)),
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (index) => setState(() => _imageIndex = index),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.network(
                                images[index],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.broken_image_outlined, color: const Color(0xFF94A3B8)),
                                ),
                              ),
                            );
                          },
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (index) {
                                final active = index == _imageIndex;
                                return Container(
                                  width: active ? 8 : 6,
                                  height: active ? 8 : 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          demo.title,
                          style: AppChrome.body(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        '${demo.stars}',
                        style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      demo.displayDescription.isNotEmpty
                          ? demo.displayDescription
                          : 'No description available.',
                      style: AppChrome.body(
                        fontSize: 13,
                        height: 1.45,
                        color: AppChrome.muted,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (demo.kits.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: demo.kits.take(6).map((kit) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            kit,
                            style: AppChrome.body(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B21A8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openUrl(demo.htmlUrl),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View on GitHub'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppChrome.ink,
                        side: const BorderSide(color: Color(0xFFDDD6FE)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
