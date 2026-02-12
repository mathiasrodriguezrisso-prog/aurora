import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora_app/core/config/app_theme.dart';
import 'package:aurora_app/core/config/env_config.dart';

class GeneratingPlanScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> extra;
  const GeneratingPlanScreen({super.key, required this.extra});

  @override
  ConsumerState<GeneratingPlanScreen> createState() => _GeneratingPlanScreenState();
}

class _GeneratingPlanScreenState extends ConsumerState<GeneratingPlanScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  bool _usingFallback = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _generatePlan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFallbackPlan() {
    final strain = widget.extra['strain']?.toString() ?? 'Unknown Strain';
    final medium = widget.extra['medium']?.toString() ?? 'Soil';

    return {
      'estimated_days': 109,
      'ai_generated': false,
      'strain': strain,
      'medium': medium,
      'phases': [
        {
          'name': 'Germination',
          'duration': '5 days',
          'parameters': {'temp': '24-28°C', 'humidity': '70-80%', 'light': '18/6'},
          'events': [
            {'day': 1, 'action': 'Plant seed', 'detail': '1cm deep in moist medium'},
            {'day': 3, 'action': 'Check sprout', 'detail': 'Keep medium moist, not wet'},
          ],
        },
        {
          'name': 'Seedling',
          'duration': '10 days',
          'parameters': {'temp': '22-26°C', 'humidity': '65-70%', 'light': '18/6'},
          'events': [
            {'day': 6, 'action': 'First true leaves', 'detail': 'Begin light feeding'},
            {'day': 12, 'action': 'Transplant if needed', 'detail': 'Move to larger pot'},
          ],
        },
        {
          'name': 'Vegetative',
          'duration': '28 days',
          'parameters': {'temp': '22-28°C', 'humidity': '55-65%', 'light': '18/6'},
          'events': [
            {'day': 16, 'action': 'Start veg nutrients', 'detail': '1/4 strength, increase gradually'},
            {'day': 25, 'action': 'Begin training', 'detail': 'LST or topping as preferred'},
            {'day': 35, 'action': 'Full nutrients', 'detail': 'Full veg feeding schedule'},
          ],
        },
        {
          'name': 'Flowering',
          'duration': '56 days',
          'parameters': {'temp': '20-26°C', 'humidity': '40-50%', 'light': '12/12'},
          'events': [
            {'day': 44, 'action': 'Flip to 12/12', 'detail': 'Trigger flowering phase'},
            {'day': 50, 'action': 'Switch to bloom nutrients', 'detail': 'Reduce nitrogen, increase P/K'},
            {'day': 80, 'action': 'Start flushing check', 'detail': 'Check trichomes weekly'},
          ],
        },
        {
          'name': 'Flushing',
          'duration': '10 days',
          'parameters': {'temp': '18-24°C', 'humidity': '40-45%', 'light': '12/12'},
          'events': [
            {'day': 100, 'action': 'Begin flush', 'detail': 'Plain water only'},
            {'day': 107, 'action': 'Check harvest readiness', 'detail': 'Cloudy/amber trichomes'},
            {'day': 109, 'action': 'Harvest', 'detail': 'Cut, trim, hang to dry'},
          ],
        },
      ],
    };
  }

  Future<void> _generatePlan() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      final response = await dio.post('/grow/generate-plan', data: {
        'strain': widget.extra['strain'],
        'seed_type': widget.extra['seed_type'],
        'medium': widget.extra['medium'],
        'light_type': widget.extra['light_type'],
        'watts': widget.extra['watts'],
        'space': widget.extra['space'],
        'start_date': widget.extra['start_date'],
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      if (mounted) {
        final plan = response.data as Map<String, dynamic>;
        context.pushReplacement('/grow/summary', extra: {'plan': plan, 'config': widget.extra});
      }
    } catch (e) {
      // Backend unavailable — use fallback plan
      if (mounted) {
        final fallbackPlan = _buildFallbackPlan();
        setState(() {
          _usingFallback = true;
          _loading = false;
        });

        // Short delay to show the fallback message before navigating
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          context.pushReplacement('/grow/summary', extra: {
            'plan': fallbackPlan,
            'config': widget.extra,
            'is_fallback': true,
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: _usingFallback
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.amber),
                  const SizedBox(height: 24),
                  const Text(
                    "AI backend unavailable",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Generating a basic plan from templates...",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(color: Colors.amber, backgroundColor: AppTheme.surface),
                  ),
                ],
              )
            : _loading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.5 + (_pulseController.value * 0.5),
                            child: child,
                          );
                        },
                        child: const Icon(Icons.auto_awesome, size: 60, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Generating your grow plan...",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Aurora is analyzing your setup...",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(color: AppTheme.primary, backgroundColor: AppTheme.surface),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: AppTheme.error),
                      const SizedBox(height: 16),
                      const Text("Something went wrong", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _error ?? 'Unknown error',
                          style: const TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                            _usingFallback = false;
                          });
                          _generatePlan();
                        },
                        child: const Text("Retry"),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text("Go Back", style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
      ),
    );
  }
}
