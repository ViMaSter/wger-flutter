/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2025 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/routines/providers/gym_rest_timer_provider.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class TimerWidget extends ConsumerStatefulWidget {
  final PageController _controller;

  const TimerWidget(this._controller);

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  late Timer _uiTimer;

  @override
  void initState() {
    super.initState();
    ref.read(gymRestTimerProvider).startElapsed();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // ignore: no-empty-block, avoid-empty-setstate
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = ref.watch(gymRestTimerProvider).elapsedSeconds;
    final displayTime = DateTime(2000, 1, 1, 0, 0, 0).add(Duration(seconds: displaySeconds));

    return Column(
      children: [
        NavigationHeader(
          AppLocalizations.of(context).pause,
          widget._controller,
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('m:ss').format(displayTime),
              style: Theme.of(
                context,
              ).textTheme.displayLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        NavigationFooter(widget._controller),
      ],
    );
  }
}

class TimerCountdownWidget extends ConsumerStatefulWidget {
  final PageController _controller;
  final int _seconds;

  const TimerCountdownWidget(
    this._controller,
    this._seconds,
  );

  @override
  _TimerCountdownWidgetState createState() => _TimerCountdownWidgetState();
}

class _TimerCountdownWidgetState extends ConsumerState<TimerCountdownWidget> {
  late Timer _uiTimer;
  int? _enteredPage;

  @override
  void initState() {
    super.initState();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // ignore: no-empty-block, avoid-empty-setstate
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(gymRestTimerProvider);
    final gymState = ref.watch(gymStateProvider);
    final page = gymState.getSlotEntryPageByIndex();
    final config = page?.setConfigData;
    final minimum =
        config?.restTime?.toInt() ??
        (gymState.useCountdownBetweenSets ? gymState.countdownDuration.inSeconds : null);
    final maximum = config?.maxRestTime?.toInt();
    if (page?.type != SlotPageType.timer) {
      _enteredPage = null;
    } else if (_enteredPage != gymState.currentPage) {
      _enteredPage = gymState.currentPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(gymStateProvider).currentPage == _enteredPage) {
          timer.ensureStarted(minimum ?? widget._seconds);
        }
      });
    }

    return ListenableBuilder(
      listenable: timer,
      builder: (context, child) {
        final displayTime = DateTime(2000, 1, 1).add(Duration(seconds: timer.remainingSeconds));
        return Column(
          children: [
            NavigationHeader(
              AppLocalizations.of(context).pause,
              widget._controller,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('m:ss').format(displayTime),
                    style:
                        Theme.of(
                          context,
                        ).textTheme.displayLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      IconButton(
                        key: const ValueKey('rest-timer-minus'),
                        tooltip: '-15s',
                        onPressed: timer.endTime == null ? null : () => timer.adjust(-15),
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton(
                        key: const ValueKey('rest-timer-plus'),
                        tooltip: '+15s',
                        onPressed: timer.endTime == null ? null : () => timer.adjust(15),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        key: const ValueKey('rest-timer-min'),
                        tooltip: minimum == null ? 'Reset to min' : 'Reset to ${minimum}s (min)',
                        onPressed: minimum == null ? null : () => timer.resetTo(minimum),
                        icon: const Icon(Icons.timer),
                      ),
                      IconButton(
                        key: const ValueKey('rest-timer-max'),
                        tooltip: maximum == null ? 'Reset to max' : 'Reset to ${maximum}s (max)',
                        onPressed: maximum == null ? null : () => timer.resetTo(maximum),
                        icon: const Icon(Icons.timer_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            NavigationFooter(widget._controller),
          ],
        );
      },
    );
  }
}
