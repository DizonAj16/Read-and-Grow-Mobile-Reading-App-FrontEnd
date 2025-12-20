import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  final String animation;
  final double animationSize;
  final Color? textColor;
  final bool showBackground;

  const LoadingState({
    super.key,
    this.message,
    this.animation = 'assets/animation/loading_rainbow.json',
    this.animationSize = 90,
    this.textColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: showBackground ? colorScheme.surface : Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle (optional)
                if (showBackground)
                  Container(
                    width: animationSize + 40,
                    height: animationSize + 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                
                // Lottie animation
                Lottie.asset(
                  animation,
                  width: animationSize,
                  height: animationSize,
                  frameRate: FrameRate.max,
                ),
              ],
            ),
            
            if (message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: showBackground ? colorScheme.surfaceVariant.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor ?? colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        minHeight: 2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String animation;
  final double animationSize;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onPressed;
  final bool showActionButton;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle = '',
    this.animation = 'assets/animation/empty_box.json',
    this.animationSize = 160,
    this.icon,
    this.buttonText,
    this.onPressed,
    this.showActionButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon or Lottie
              Container(
                width: animationSize,
                height: animationSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.05),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(
                          icon,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.4),
                        )
                      : Lottie.asset(
                          animation,
                          width: animationSize * 0.8,
                          height: animationSize * 0.8,
                          repeat: true,
                          frameRate: FrameRate(30),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              if (showActionButton && buttonText != null && onPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: colorScheme.primary.withOpacity(0.3),
                  ),
                  child: Text(buttonText!),
                ),
              ],
              
              // Optional decorative element
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final String animation;
  final double animationSize;
  final IconData? icon;
  final String retryText;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final bool showCancelButton;

  const ErrorState({
    super.key,
    required this.message,
    this.details,
    this.animation = 'assets/animation/error.json',
    this.animationSize = 140,
    this.icon,
    this.retryText = 'Try Again',
    this.onRetry,
    this.onCancel,
    this.showCancelButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error animation/icon with background
              Container(
                width: animationSize + 40,
                height: animationSize + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(
                          icon,
                          size: 72,
                          color: Colors.red.withOpacity(0.6),
                        )
                      : Lottie.asset(
                          animation,
                          width: animationSize,
                          height: animationSize,
                          frameRate: FrameRate.max,
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Oops!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (details != null && details!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          details!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'Monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              if (onRetry != null || onCancel != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showCancelButton && onCancel != null)
                      OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    
                    if (showCancelButton && onCancel != null)
                      const SizedBox(width: 12),
                    
                    if (onRetry != null)
                      ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 18),
                            const SizedBox(width: 8),
                            Text(retryText),
                          ],
                        ),
                      ),
                  ],
                ),
              
              // Help text
              if (onRetry == null && onCancel == null) ...[
                const SizedBox(height: 16),
                Text(
                  'Please check your connection and try again later',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// New: Success State
class SuccessState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String animation;
  final double animationSize;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onPressed;
  final bool autoDismiss;

  const SuccessState({
    super.key,
    required this.title,
    this.subtitle,
    this.animation = 'assets/animation/success.json',
    this.animationSize = 120,
    this.icon,
    this.buttonText,
    this.onPressed,
    this.autoDismiss = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Auto dismiss after 2 seconds if enabled
    if (autoDismiss && onPressed == null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success animation
              Container(
                width: animationSize + 40,
                height: animationSize + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(
                          icon,
                          size: 72,
                          color: Colors.green.withOpacity(0.6),
                        )
                      : Lottie.asset(
                          animation,
                          width: animationSize,
                          height: animationSize,
                          frameRate: FrameRate.max,
                          repeat: false,
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title with checkmark
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              if (buttonText != null && onPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(buttonText!),
                ),
              ],
              
              // Auto dismiss countdown indicator
              if (autoDismiss) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    color: Colors.green,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// New: Partial Loading State (for skeleton loading)
class SkeletonLoadingState extends StatelessWidget {
  final int itemCount;
  final bool showHeader;
  
  const SkeletonLoadingState({
    super.key,
    this.itemCount = 3,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount + (showHeader ? 1 : 0),
      itemBuilder: (context, index) {
        if (showHeader && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeleton(width: 150, height: 24),
                const SizedBox(height: 8),
                _buildSkeleton(width: 200, height: 16),
              ],
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              _buildSkeleton(width: 48, height: 48, isCircle: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeleton(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    _buildSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeleton({
    required double width,
    required double height,
    bool isCircle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: isCircle 
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(8),
      ),
    );
  }
}