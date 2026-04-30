import 'package:flutter/material.dart';

import '../models/daily_plan.dart';
import '../models/session_plan.dart';
import '../services/auth_service.dart';
import '../services/plan_service.dart';
import '../widgets/session_card.dart';
import 'parent_review_screen.dart';
import 'practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final PlanService _planService = PlanService();
  late Future<DailyPlan?> _planFuture;

  @override
  void initState() {
    super.initState();
    _planFuture = _loadPlan();
  }

  Future<DailyPlan?> _loadPlan() async {
    await _authService.signInAnonymously();
    return _planService.loadTodayPlan();
  }

  Future<void> _refreshPlan() async {
    setState(() {
      _planFuture = _loadPlan();
    });
    await _planFuture;
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
      body: FutureBuilder<DailyPlan?>(
        future: _planFuture,
        builder: (BuildContext context, AsyncSnapshot<DailyPlan?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load plan. Please try again.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final DailyPlan? plan = snapshot.data;
          if (plan == null || plan.sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No practice plan found for today.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshPlan,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plan.sessions.length,
              itemBuilder: (BuildContext context, int index) {
                final SessionPlan session = plan.sessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SessionCard(
                    session: session,
                    onStart: () => _openPractice(session),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
