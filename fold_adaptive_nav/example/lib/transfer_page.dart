import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// A non-scrolling screen with [CoverActionRow], and the entry to a
/// three-step flow built on [PinnedActionBody].
class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: CoverActionRow(
        actions: [
          FlowActionButton.secondary(
            label: 'Request',
            icon: Icons.call_received,
            onPressed: () {},
          ),
          FlowActionButton(
            label: 'Send money',
            icon: Icons.send,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _AmountStep()),
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance', style: theme.textTheme.titleMedium),
              Text('€ 2,450.00', style: theme.textTheme.displaySmall),
              const SizedBox(height: 16),
              Text(
                'The actions below sit in a row on phones and tablets, and '
                'in a thumb column on the right of a cover display.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _stepCount = 3;

class _AmountStep extends StatefulWidget {
  const _AmountStep();

  @override
  State<_AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<_AmountStep> {
  String _amount = '25';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amount')),
      body: PinnedActionBody(
        step: 1,
        stepCount: _stepCount,
        action: FlowActionButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _RecipientStep(_amount)),
          ),
        ),
        // Too wide for the thumb column: moves to the content side on cover.
        footer: Wrap(
          spacing: 8,
          children: [
            for (final preset in ['10', '25', '50', '100'])
              ChoiceChip(
                label: Text('€ $preset'),
                selected: _amount == preset,
                onSelected: (_) => setState(() => _amount = preset),
              ),
          ],
        ),
        child: Center(
          child: Text(
            '€ $_amount',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
    );
  }
}

class _RecipientStep extends StatefulWidget {
  const _RecipientStep(this.amount);

  final String amount;

  @override
  State<_RecipientStep> createState() => _RecipientStepState();
}

class _RecipientStepState extends State<_RecipientStep> {
  static const _people = [
    'Amira', 'Bilal', 'Chen', 'Dana', 'Eitan', 'Farah', 'Goran', 'Hana', //
    'Ines', 'Jonas', 'Kofi', 'Lena',
  ];
  String _recipient = _people.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipient')),
      body: PinnedActionBody(
        step: 2,
        stepCount: _stepCount,
        action: FlowActionButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _ReviewStep(widget.amount, _recipient),
            ),
          ),
        ),
        child: RadioGroup<String>(
          groupValue: _recipient,
          onChanged: (v) => setState(() => _recipient = v!),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final p in _people)
                RadioListTile<String>(
                  value: p,
                  title: Text(p),
                  secondary: CircleAvatar(child: Text(p[0])),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewStep extends StatefulWidget {
  const _ReviewStep(this.amount, this.recipient);

  final String amount;
  final String recipient;

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You send', style: theme.textTheme.titleSmall),
        Text('€ ${widget.amount}', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('to ${widget.recipient}', style: theme.textTheme.titleMedium),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: PinnedActionBody(
        step: 3,
        stepCount: _stepCount,
        panelHeader: summary,
        footer: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v ?? false),
          title: const Text('I checked the details'),
        ),
        // Side by side normally, stacked in the thumb column.
        action: ActionGroup(
          children: [
            FlowActionButton.secondary(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).pop(),
            ),
            FlowActionButton(
              label: 'Send',
              icon: Icons.check,
              onPressed: _confirmed
                  ? () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          'Sent € ${widget.amount} to ${widget.recipient}',
                        ),
                      ));
                    }
                  : null,
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary,
            const SizedBox(height: 24),
            Text(
              'On a phone the buttons are pinned to the bottom. On a cover '
              'display they stack in the thumb column on the right. On a wide '
              'tablet they move into a side panel.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
