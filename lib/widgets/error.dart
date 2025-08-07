import 'package:flutter/material.dart';

class ErrorWidgetUniversal extends StatelessWidget {
  final String title;
  final String description;
  final String? imageAsset; // Asset path for image/icon
  final VoidCallback? onRetry;
  final String retryText;

  const ErrorWidgetUniversal({
    super.key,
    required this.title,
    required this.description,
    this.imageAsset,
    this.onRetry,
    this.retryText = "Retry",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                height: 150,
              )
            else
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.redAccent,
              ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              )
          ],
        ),
      ),
    );
  }
}
