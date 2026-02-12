/// 📁 lib/features/grow/presentation/screens/generating_plan_screen.dart
/// Pantalla 4 del onboarding: Animación mientras la IA genera el plan.
/// Usa GrowRepository (Dio/ApiClient) con JWT automático y retry.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_theme.dart';
import '../providers/grow_providers.dart';

class GeneratingPlanScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> growConfig;

  const GeneratingPlanScreen({
    super.key,
    required this.growConfig,
  });

  @override
  ConsumerState<GeneratingPlanScreen> createState() => _GeneratingPlanScreenState();
}

class _GeneratingPlanScreenState extends ConsumerState<GeneratingPlanScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  final List<String> _statusMessages = [
    'Analyzing your strain...',
    'Calculating optimal conditions...',
    'Generating nutrient schedule...',
    'Creating weekly tasks...',
    'Building your personalized plan...',
    'Almost ready...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  bool _isLoading = true;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();

    // Pulse animation for the main icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Rotation for the orbiting dots
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rotateController.repeat();

    // Cycle through status messages
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _statusMessages.length;
        });
      }
    });

    // Start generating the plan
    _generatePlan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  /// Get the currently authenticated user's ID from Supabase.
  String? _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  Future<void> _generatePlan() async {
    try {
      final config = widget.growConfig;

      // Verificar autenticación
      final userId = _getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'You must be logged in to generate a plan.';
            _isLoading = false;
          });
        }
        return;
      }

      // Usar el repositorio de Grow (inyectado via Riverpod)
      final repository = ref.read(growRepositoryProvider);

      // Generar plan con timeout
      final result = await repository.generatePlan(config).timeout(
        _requestTimeout,
        onTimeout: () {
          throw TimeoutException(
            'The AI is taking longer than expected. Please try again.',
            _requestTimeout,
          );
        },
      );

      result.fold(
        (failure) => _handleError(failure.message),
        (plan) async {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Navegar al resumen después de un breve delay
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              context.go(
                '/grow/summary',
                extra: {'plan': plan, 'config': config},
              );
            }
          }
        },
      );
    } on TimeoutException catch (e) {
      _handleError(e.message ?? 'Request timed out. Please try again.');
    } catch (e) {
      _handleError('Unable to connect to server. Please try again.');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;

    if (_retryCount < _maxRetries) {
      // Auto-retry with exponential backoff
      _retryCount++;
      final delay = Duration(seconds: 2 * _retryCount);
      setState(() {
        _currentMessageIndex = 0;
      });
      Future.delayed(delay, () {
        if (mounted && _isLoading) {
          _generatePlan();
        }
      });
    } else {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentMessageIndex = 0;
      _retryCount = 0;
    });
    _generatePlan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress
                _buildProgress(),
                const Spacer(),

                // Main animation or error
                if (_errorMessage != null)
                  _buildError()
                else
                  _buildAnimation(),

                const Spacer(),

                // Tip
                if (_isLoading) _buildTip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: index <= 3
                  ? AppTheme.primary
                  : AppTheme.glassBackground,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated icon with orbiting elements
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Orbiting dots
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        children: List.generate(6, (i) {
                          final angle = (i / 6) * 2 * math.pi;
                          return Positioned(
                            left: 90 + 80 * math.cos(angle) - 6,
                            top: 90 + 80 * math.sin(angle) - 6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(
                                  alpha: 0.3 + (i / 6) * 0.7,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),

              // Glowing background
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 120 * _pulseAnimation.value,
                    height: 120 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Main icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.9 + (_pulseAnimation.value - 0.8) * 0.25,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.neonGlow,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessages[_currentMessageIndex],
            key: ValueKey(_currentMessageIndex),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 12),
        Text(
          _retryCount > 0
              ? 'Retry attempt $_retryCount/$_maxRetries...'
              : 'Aurora AI is creating your personalized grow plan',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: AppTheme.error,
            size: 50,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Oops! Something went wrong',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Unknown error occurred',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'Go Back',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tip: Aurora learns from your grows to improve future recommendations.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
