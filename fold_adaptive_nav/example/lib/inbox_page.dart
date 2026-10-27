import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// [AdaptiveListDetail]: messages beside the open one on an opened foldable
/// or a wide tablet, one at a time on phones and the cover display.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  int? _open;

  static final _messages = [
    for (var i = 0; i < 24; i++)
      (
        from: const ['Maya', 'Omar', 'Lena', 'Yusuf', 'Sara', 'Karim'][i % 6],
        subject: const [
          'Lunch on Friday?',
          'Invoice #2041',
          'Photos from the trip',
          'Your parcel is on its way',
          'Re: the fold demo',
          'Weekly report',
        ][i % 6],
        unread: i < 3,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return SafeArea(
      bottom: false,
      child: AdaptiveListDetail(
        list: _list(context),
        detail: open == null
            ? null
            : _Detail(
                key: ValueKey(open),
                from: _messages[open].from,
                subject: _messages[open].subject,
                onClose: () => setState(() => _open = null),
              ),
        emptyDetail: const Center(child: Text('Pick a message')),
        onCloseDetail: () => setState(() => _open = null),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: _messages.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Inbox', style: theme.textTheme.headlineSmall),
          );
        }
        final index = i - 1;
        final m = _messages[index];
        return ListTile(
          selected: index == _open,
          leading: CircleAvatar(child: Text(m.from[0])),
          title: Text(
            m.subject,
            style:
                m.unread ? const TextStyle(fontWeight: FontWeight.w600) : null,
          ),
          subtitle: Text(m.from),
          onTap: () => setState(() => _open = index),
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    super.key,
    required this.from,
    required this.subject,
    required this.onClose,
  });

  final String from;
  final String subject;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Alone, the detail needs its own way back; beside the list it doesn't.
    final alone = !FoldSplitView.isSplitOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Row(
          children: [
            if (alone)
              IconButton(
                tooltip: 'Back',
                icon: const BackButtonIcon(),
                onPressed: onClose,
              ),
            Expanded(
              child: Text(subject, style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('From $from', style: theme.textTheme.titleSmall),
        const SizedBox(height: 16),
        const Text(
          'Open a message on the cover display, then unfold: it stays open, '
          'now beside the list. On a phone, back closes it and the list is '
          'still scrolled where you left it.',
        ),
        const SizedBox(height: 24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            icon: const Icon(Icons.reply),
            label: const Text('Reply'),
            // A sheet on phones and the cover, a dialog on tablets.
            onPressed: () => showAdaptiveSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Reply to $from', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    const TextField(
                      autofocus: true,
                      maxLines: 4,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
