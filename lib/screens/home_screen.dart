import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/daily_plan.dart';
import '../models/session_plan.dart';
import '../services/auth_service.dart';
import '../services/plan_service.dart';
import '../widgets/session_card.dart';
import 'parent_review_screen.dart';
import 'practice_screen.dart';

enum _HomePhase {
  loading,
  creatingTestPlan,
  content,
  loadError,
  seedError,
  noSessions,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final PlanService _planService = PlanService();

  _HomePhase _phase = _HomePhase.loading;
  DailyPlan? _plan;

  @override
  void initState() {
    super.initState();
    _runLoadPipeline();
  }

  Future<void> _runLoadPipeline() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _phase = _HomePhase.loading;
      _plan = null;
    });

    try {
      await _authService.signInAnonymously();
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _HomePhase.loadError);
      }
      return;
    }

    DailyPlan? plan;
    try {
      plan = await _planService.loadTodayPlan();
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _HomePhase.loadError);
      }
      return;
    }

    if (plan == null) {
      if (!mounted) {
        return;
      }
      setState(() => _phase = _HomePhase.creatingTestPlan);

      try {
        await _planService.createDefaultPlanForTodayIfMissing();
      } catch (_) {
        if (mounted) {
          setState(() => _phase = _HomePhase.seedError);
        }
        return;
      }

      try {
        plan = await _planService.loadTodayPlan();
      } catch (_) {
        if (mounted) {
          setState(() => _phase = _HomePhase.loadError);
        }
        return;
      }
    }

    if (!mounted) {
      return;
    }

    if (plan == null) {
      setState(() => _phase = _HomePhase.seedError);
      return;
    }

    if (plan.sessions.isEmpty) {
      setState(() {
        _phase = _HomePhase.noSessions;
        _plan = plan;
      });
      return;
    }

    setState(() {
      _phase = _HomePhase.content;
      _plan = plan;
    });
  }

  Future<void> _refreshPlan() async {
    await _runLoadPipeline();
  }

  Future<void> _debugCreateTestPlan() async {
    if (!mounted) {
      return;
    }
    setState(() => _phase = _HomePhase.loading);

    try {
      await _authService.signInAnonymously();
      await _planService.createDefaultPlanForTodayIfMissing();
      final DailyPlan? plan = await _planService.loadTodayPlan();
      if (!mounted) {
        return;
      }
      if (plan == null) {
        setState(() => _phase = _HomePhase.seedError);
        return;
      }
      if (plan.sessions.isEmpty) {
        setState(() {
          _phase = _HomePhase.noSessions;
          _plan = plan;
        });
        return;
      }
      setState(() {
        _phase = _HomePhase.content;
        _plan = plan;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _HomePhase.seedError);
      }
    }
  }

  Widget _debugTestPlanButton() {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton(
        onPressed: _debugCreateTestPlan,
        child: const Text('Create Test Plan'),
      ),
    );
  }

  Widget _messageBody(String message, {bool showDebugButton = true}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (showDebugButton) _debugTestPlanButton(),
          ],
        ),
      ),
    );
  }

  void _openPractice(SessionPlan session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(session: session),
      ),
    );
  }

  void _openParentReview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ParentReviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mohsin Speech Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Parent review',
            onPressed: _openParentReview,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _HomePhase.loading:
        return const Center(child: CircularProgressIndicator());
      case _HomePhase.creatingTestPlan:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'No plan found. Creating test plan...',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        );
      case _HomePhase.loadError:
        return _messageBody(
          'Could not load plan. Please try again.',
        );
      case _HomePhase.seedError:
        return _messageBody(
          'Could not create test plan. Check Firestore rules and internet.',
        );
      case _HomePhase.noSessions:
        return _messageBody(
          'Today\'s plan has no sessions.',
        );
      case _HomePhase.content:
        final DailyPlan? plan = _plan;
        if (plan == null || plan.sessions.isEmpty) {
          return _messageBody(
            'Today\'s plan has no sessions.',
          );
        }
        return RefreshIndicator(
          onRefresh: _refreshPlan,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: plan.sessions.length,
            itemBuilder: (BuildContext context, int index) {
              final SessionPlan session = plan.sessions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SessionCard(
                  session: session,
                  onStart: () => _openPractice(session),
                ),
              );
            },
          ),
        );
    }
  }
}
