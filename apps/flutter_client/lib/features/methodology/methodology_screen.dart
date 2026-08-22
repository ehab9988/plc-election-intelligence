import 'package:flutter/material.dart';

/// Section 30 "Methodology" screen — plain-language explanation of every
/// number the app shows. Full technical detail lives in docs/*.md; this
/// screen is the in-app summary a non-technical user can read.
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  static const _sections = [
    (
      title: 'Polling Average',
      body: 'A weighted average of polls that ask the same "if elections were held today" question. '
          'Weight = recency × sample size × population type × pollster quality. We never average '
          'polls that asked differently-worded questions, and we never count the same poll twice.',
    ),
    (
      title: 'Election-Day Forecast',
      body: 'A Monte Carlo simulation built on the polling average, adding modeled uncertainty from '
          'house effects, turnout, and undecided voters. It reports a median and 50/80/95% ranges — '
          'never a single number presented as fact.',
    ),
    (
      title: 'Seat Allocation',
      body: 'Seats are allocated using the Sainte-Laguë method against the current, officially verified '
          'election rules (132 seats, 1% national threshold). The majority line is always computed as '
          'floor(total seats / 2) + 1 — for 132 seats, that is 67.',
    ),
    (
      title: 'Candidate Seat Probability',
      body: 'Because this is a closed-list election, voters vote for a list, not an individual candidate. '
          'A candidate\'s probability of winning a seat is the probability that their list wins at least '
          'as many seats as their position on the list, from the same simulations used for the seat forecast. '
          'We never calculate or display an individual candidate vote share.',
    ),
    (
      title: 'Coalition Lab',
      body: 'Mathematical feasibility (the probability a set of lists reaches a majority) is computed '
          'directly from simulation data. Political compatibility — whether parties are willing to '
          'cooperate — is a separate, evidence-sourced assessment and is never presented as a '
          'calibrated probability unless the underlying methodology supports one.',
    ),
    (
      title: 'Uncertainty & Model Health',
      body: 'If the most recent high-quality poll is old, the forecast\'s uncertainty widens rather than '
          'staying artificially narrow. Every forecast carries a model version, dataset version, and data '
          'cutoff timestamp so it can be reproduced and audited.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Methodology')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(s.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          Text(
            'This product applies the same methodology to every party or list. It does not recommend how '
            'to vote and does not adjust results to favor any political outcome.',
            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
