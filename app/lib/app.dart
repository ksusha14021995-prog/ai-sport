import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'domain/models/training_plan.dart';
import 'routing/router.dart';
import 'routing/routes.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/onboarding/view_models/onboarding_view_model.dart';

class AiSportApp extends StatefulWidget {
  const AiSportApp({
    super.key,
    required this.planBuilder,
    this.initialLocation = Routes.welcome,
  });

  final PlanBuilder planBuilder;
  final String initialLocation;

  @override
  State<AiSportApp> createState() => _AiSportAppState();
}

class _AiSportAppState extends State<AiSportApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PlanBuilder>.value(value: widget.planBuilder),
        ChangeNotifierProvider(
          create: (context) =>
              OnboardingViewModel(planBuilder: context.read<PlanBuilder>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'AI-sport',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
