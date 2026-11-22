/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/build_safety.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/errors.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/routines/notifications/workout_notification_content.dart';
import 'package:wger/features/routines/notifications/workout_notification_controller.dart';
import 'package:wger/features/routines/notifications/workout_notification_service.dart';
import 'package:wger/features/routines/providers/gym_rest_timer_provider.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

import 'exercise_overview.dart';
import 'log_page.dart';
import 'session_page.dart';
import 'start_page.dart';
import 'summary.dart';
import 'timer.dart';
import 'workout_list_page.dart';

class GymMode extends ConsumerStatefulWidget {
  final GymModeArguments _args;
  final _logger = Logger('GymMode');

  GymMode(this._args);

  @override
  ConsumerState<GymMode> createState() => _GymModeState();
}

class _GymModeState extends ConsumerState<GymMode> {
  late Future<int> _initData;
  bool _initialPageJumped = false;
  late final PageController _controller;
  late final GymModeVisibleNotifier _visibility;
  late final GymStateNotifier _gymState;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    _visibility = ref.read(gymModeVisibleProvider.notifier);
    _gymState = ref.read(gymStateProvider.notifier);
    // Follows the rest countdown for the paired watch and the end-of-rest alert
    ref.read(gymRestTimerProvider);
    _initData = _loadGymState();
  }

  @override
  void dispose() {
    _controller.dispose();
    // Providers can't change while the tree is being finalized
    final visibility = _visibility;
    scheduleMicrotask(() => visibility.set(false));
    // A session whose sets were all unchecked again isn't kept
    unawaited(_gymState.discardEmptySessions());
    super.dispose();
  }

  Future<int> _loadGymState() async {
    widget._logger.fine('Loading gym state');
    // This runs from initState. Yield once so the body never executes
    // synchronously inside the widget life-cycle: the offline branch reaches
    // gym-state mutations with no await in between, and modifying a provider
    // during a life-cycle is not allowed.
    await yieldPastBuild();
    _visibility.set(true);

    final notifier = ref.read(routinesRiverpodProvider.notifier);
    final routineId = widget._args.routineId;

    final routine = await serverWithLocalFallback(
      isOnline: ref.read(networkStatusProvider),
      server: () => notifier.fetchAndSetRoutineFull(routineId),
      local: () {
        // Reaching the gym mode requires an already-downloaded routine, so
        // the local data is normally present.
        final cached = ref
            .read(routinesRiverpodProvider)
            .value
            ?.routines
            .firstWhereOrNull((r) => r.id == routineId);
        if (cached == null || !cached.isHydrated) {
          throw StateError('Routine $routineId is not available offline');
        }
        return cached;
      },
      logger: widget._logger,
      fallbackLog: 'Server unreachable, starting from the local routine',
    );

    final initialPage = await ref
        .read(gymStateProvider.notifier)
        .open(routine, widget._args.dayId, widget._args.iteration);
    _requestNotificationPermissions();

    return initialPage;
  }

  /// Asked here rather than at app start, and only if a notification is wanted
  void _requestNotificationPermissions() {
    final gymState = ref.read(gymStateProvider);
    final service = ref.read(workoutNotificationServiceProvider);
    final wanted =
        gymState.alertOnCountdownEnd ||
        (service.supportsControls && gymState.showWorkoutNotification);
    if (wanted && mounted) {
      unawaited(
        service.requestPermissions(WorkoutNotificationLabels.of(AppLocalizations.of(context))),
      );
    }
  }

  /// In the list layout the PageView shows start, the workout list, session
  /// and summary, while the gym state keeps its page per set. These map
  /// between the two; in the default layout they are the same.
  int _viewIndexOf(GymModeState state, int statePage) {
    if (!state.listLayout) {
      return statePage;
    }
    final page = state.pages.firstWhereOrNull(
      (p) => p.type != PageType.set && p.pageIndex == statePage,
    );
    return switch (page?.type) {
      null => statePage == 0 ? 0 : 1,
      PageType.start => 0,
      PageType.set => 1,
      PageType.session => 2,
      PageType.workoutSummary => 3,
    };
  }

  int _statePageOf(GymModeState state, int viewIndex) {
    if (!state.listLayout) {
      return viewIndex;
    }
    int indexOf(PageType type) =>
        state.pages.firstWhereOrNull((p) => p.type == type)?.pageIndex ?? 0;
    switch (viewIndex) {
      case 0:
        return 0;
      case 1:
        // Stay on the set or rest the state is on, else the first open set
        if (state.getSlotEntryPageByIndex() != null) {
          return state.currentPage;
        }
        final open = state.pages
            .expand((p) => p.slotPages)
            .firstWhereOrNull(
              (p) => p.type == SlotPageType.log && !state.progressOf(p.key).done,
            );
        return open?.pageIndex ?? indexOf(PageType.session);
      case 2:
        return indexOf(PageType.session);
      default:
        return indexOf(PageType.workoutSummary);
    }
  }

  List<Widget> _getContent(GymModeState state) {
    final gymState = ref.watch(gymStateProvider);
    final List<Widget> out = [];

    if (state.listLayout) {
      return [
        StartPage(_controller),
        WorkoutListPage(_controller),
        SessionPage(_controller),
        WorkoutSummary(_controller),
      ];
    }

    // Workout overview
    out.add(StartPage(_controller));

    // Sets
    for (final page in state.pages) {
      for (final slotPage in page.slotPages) {
        if (slotPage.type == SlotPageType.exerciseOverview) {
          out.add(ExerciseOverview(_controller, slotPage.key));
        }

        if (slotPage.type == SlotPageType.log) {
          out.add(LogPage(_controller, slotPage.key));
        }

        if (slotPage.type == SlotPageType.timer) {
          final rest = gymState.restDurationFor(slotPage);
          out.add(
            rest != null
                ? TimerCountdownWidget(_controller, rest.inSeconds, slotPage.key)
                : TimerWidget(_controller, slotPage.key),
          );
        }
      }
    }

    // End
    out.add(SessionPage(_controller));
    out.add(WorkoutSummary(_controller));

    return out;
  }

  /// Shows [page] when the state moved without the PageView, e.g. after a
  /// notification action or a logged set
  void _followCurrentPage(int page) {
    final shown = _controller.hasClients ? _controller.page?.round() : null;
    if (shown == null || shown == page) {
      return;
    }

    final resumed = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (resumed && (page - shown).abs() == 1) {
      _controller.animateToPage(
        page,
        duration: DEFAULT_ANIMATION_DURATION,
        curve: DEFAULT_ANIMATION_CURVE,
      );
    } else {
      _controller.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gymStateProvider.select((s) => s.currentPage), (_, page) {
      // clear() also resets the page, but the summary has to stay visible
      final state = ref.read(gymStateProvider);
      if (state.isInitialized) {
        _followCurrentPage(_viewIndexOf(state, page));
      }
    });

    return FutureBuilder<int>(
      future: _initData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BoxedProgressIndicator();
        } else if (snapshot.hasError) {
          return Center(
            child: StreamErrorIndicator(snapshot.error!, stacktrace: snapshot.stackTrace),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          final initialPage = _viewIndexOf(ref.read(gymStateProvider), snapshot.data!);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_initialPageJumped && _controller.hasClients) {
              _controller.jumpToPage(initialPage);
              setState(() => _initialPageJumped = true);
            }
          });

          final state = ref.watch(gymStateProvider);
          final children = [
            ..._getContent(state),
          ];

          return PageView(
            controller: _controller,
            onPageChanged: (page) {
              final gymState = ref.read(gymStateProvider);
              final statePage = _statePageOf(gymState, page);
              // In the list layout the state may already be on a set of the list
              if (!gymState.listLayout || statePage != gymState.currentPage) {
                ref.read(gymStateProvider.notifier).setCurrentPage(statePage);
              }

              // Check if the last page is reached
              if (page == children.length - 1) {
                widget._logger.finer('Last page reached, clearing gym state');
                ref.read(gymStateProvider.notifier).clear();
              }
            },
            children: children,
          );
        }

        return const Center(child: Text('Unexpected state'));
      },
    );
  }
}
