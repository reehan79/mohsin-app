import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../services/attempt_service.dart';
import '../services/upload_retry_service.dart';

class ParentReviewScreen extends StatefulWidget {
  const ParentReviewScreen({super.key});

  @override
  State<ParentReviewScreen> createState() => _ParentReviewScreenState();
}

class _ParentReviewScreenState extends State<ParentReviewScreen> {
  final AttemptService _attemptService = AttemptService();
  final UploadRetryService _uploadRetryService = UploadRetryService();
  late Future<List<Attempt>> _attemptsFuture;
  bool _retryBusy = false;

  @override
  void initState() {
    super.initState();
    _attemptsFuture = _attemptService.queryTodayAttempts();
  }

  void _reloadAttempts() {
    setState(() {
      _attemptsFuture = _attemptService.queryTodayAttempts();
    });
  }

  Future<void> _retryPendingUploads() async {
    setState(() {
      _retryBusy = true;
    });
    try {
      await _uploadRetryService.retryPendingUploads();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retrying pending uploads in the background.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        _reloadAttempts();
      }
    } finally {
      if (mounted) {
        setState(() {
          _retryBusy = false;
        });
      }
    }
  }

  String _uploadLabel(String raw) {
    final String s = raw.toLowerCase().trim();
    if (s == 'uploaded') {
      return 'Uploaded';
    }
    if (s == 'pending') {
      return 'Pending';
    }
    return raw.isEmpty ? 'Unknown' : raw;
  }

  Color _uploadColor(String raw, ColorScheme scheme) {
    final String s = raw.toLowerCase().trim();
    if (s == 'uploaded') {
      return scheme.primary;
    }
    if (s == 'pending') {
      return scheme.tertiary;
    }
    return scheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent review'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reloadAttempts,
          ),
        ],
      ),
      body: FutureBuilder<List<Attempt>>(
        future: _attemptsFuture,
        builder:
            (BuildContext context, AsyncSnapshot<List<Attempt>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load attempts.'));
          }

          final List<Attempt> attempts = snapshot.data ?? <Attempt>[];
          if (attempts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No attempts recorded today.'),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _retryBusy ? null : _retryPendingUploads,
                      icon: _retryBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Retry pending uploads'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                '${attempts.length} attempt${attempts.length == 1 ? '' : 's'} today',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retryBusy ? null : _retryPendingUploads,
                  icon: _retryBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Retry pending uploads'),
                ),
              ),
              const SizedBox(height: 16),
              ...attempts.map((Attempt attempt) {
                final String createdAtText =
                    DateFormat('yyyy-MM-dd HH:mm').format(attempt.createdAt);
                final String uploadLabel = _uploadLabel(attempt.uploadStatus);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            attempt.taskText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Repetition ${attempt.repetitionNumber}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(uploadLabel),
                            side: BorderSide(
                              color: _uploadColor(
                                attempt.uploadStatus,
                                theme.colorScheme,
                              ),
                            ),
                            backgroundColor: _uploadColor(
                              attempt.uploadStatus,
                              theme.colorScheme,
                            ).withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                              color: _uploadColor(
                                attempt.uploadStatus,
                                theme.colorScheme,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            createdAtText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
