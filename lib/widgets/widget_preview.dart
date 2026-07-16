import 'package:flutter/material.dart';
import '../theme/app_chrome.dart';

class WidgetPreview extends StatelessWidget {
  final String gifPath;

  const WidgetPreview({
    super.key,
    required this.gifPath,
  });

  /// Convert Firebase Storage URL to Cloud Function proxy URL
  /// This bypasses corporate firewall restrictions
  String _getProxyUrl(String firebaseUrl) {
    if (!firebaseUrl.startsWith('http')) return firebaseUrl;
    
    try {
      // Check if it's a Firebase Storage URL
      if (firebaseUrl.contains('firebasestorage.googleapis.com')) {
        // Extract the file path from Firebase Storage URL
        // Format: https://firebasestorage.googleapis.com/v0/b/BUCKET/o/PATH?alt=media&token=...
        final uri = Uri.parse(firebaseUrl);
        final pathMatch = RegExp(r'/o/(.+?)\?').firstMatch(firebaseUrl);
        
        if (pathMatch != null) {
          final encodedPath = pathMatch.group(1);
          final decodedPath = Uri.decodeComponent(encodedPath!);
          
          // Return Cloud Function proxy URL
          return 'https://us-central1-arkuibuilder.cloudfunctions.net/proxyImage?path=$decodedPath';
        }
      }
    } catch (e) {
      print('Proxy URL parse error: $e');
    }
    
    // Fallback to original URL
    return firebaseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final proxyUrl = _getProxyUrl(gifPath);
    
    // Debug: Print the URLs to console
    print('WidgetPreview original: $gifPath');
    print('WidgetPreview proxy: $proxyUrl');
    print('Is HTTP URL: ${gifPath.startsWith('http')}');
    
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        maxHeight: 600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildDot(Colors.red),
                const SizedBox(width: 6),
                _buildDot(Colors.yellow),
                const SizedBox(width: 6),
                _buildDot(Colors.green),
                const Spacer(),
                Text(
                  'Preview',
                  style: AppChrome.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppChrome.muted,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: proxyUrl.startsWith('http')
                    ? Image.network(
                        proxyUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 400,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppChrome.ink,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Image.network error: $error');
                        print('Original URL: $gifPath');
                        print('Proxy URL: $proxyUrl');
                        return Container(
                          height: 400,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppChrome.ink.withOpacity(0.1),
                                AppChrome.accent.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                  color: AppChrome.ink.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Image Load Error',
                                  style: AppChrome.body(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppChrome.ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Could not load image',
                                  style: AppChrome.body(
                                    fontSize: 14,
                                    color: AppChrome.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: AppChrome.body(
                                    fontSize: 10,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      proxyUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 400,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppChrome.ink.withOpacity(0.1),
                                AppChrome.accent.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: AppChrome.ink.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Preview Coming Soon',
                                  style: AppChrome.body(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppChrome.ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your image here',
                                  style: AppChrome.body(
                                    fontSize: 14,
                                    color: AppChrome.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
