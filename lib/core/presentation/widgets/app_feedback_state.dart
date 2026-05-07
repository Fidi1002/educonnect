import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    this.message = 'Memuat data...',
    this.fullScreen = true,
    super.key,
  });

  final String message;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.8),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF716A7D)),
          ),
        ],
      ),
    );
    return fullScreen ? Scaffold(body: child) : child;
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.message,
    this.hint,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.fullScreen = false,
    super.key,
  });

  final String message;
  final String? hint;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6FB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8E1F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF7D758A)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF241A33),
                ),
              ),
              if (hint != null && hint!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7D758A),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return fullScreen ? Scaffold(body: child) : child;
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    this.detail,
    this.onRetry,
    this.retryLabel = 'Coba lagi',
    this.fullScreen = false,
    super.key,
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF2D9D9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFB42318),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6A1B1B),
                ),
              ),
              if (detail != null && detail!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8B6F6F),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return fullScreen ? Scaffold(body: child) : child;
  }
}
