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

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/number_input.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/progressive_overload.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/linkified_comment.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/features/routines/widgets/gym_mode/progressive_overload_card.dart';
import 'package:wger/features/routines/widgets/gym_mode/weight_profile_sheet.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Background of a cell that beats the same set of last time
Color progressionHighlight(BuildContext context) => Color.alphaBlend(
  Colors.green.withValues(alpha: 0.35),
  Theme.of(context).colorScheme.surface,
);

/// The whole workout on one page: per exercise a table of its sets with what
/// was done last time, pre-filled with the smallest progressive overload and
/// the values that beat last time highlighted
class WorkoutListPage extends ConsumerStatefulWidget {
  final PageController _controller;

  const WorkoutListPage(this._controller, {super.key});

  @override
  ConsumerState<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends ConsumerState<WorkoutListPage> {
  final _scrollController = ScrollController();

  /// On the first planned set that isn't logged yet, to continue there
  final _resumeKey = GlobalKey();

  /// The page key of the row the list scrolls to, chosen once when the sets
  /// are first there and kept, so the key doesn't move between rows
  String? _resumeRowKey;
  bool _resumeChosen = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Picks the row to continue on the first time there are sets, and scrolls
  /// it to the middle after that frame when an earlier set is logged already
  void _chooseResumeRow(GymModeState state, List<List<SlotPageEntry>> blocks) {
    if (_resumeChosen || blocks.isEmpty) {
      return;
    }
    _resumeChosen = true;

    final planned = state.requiredLogPages;
    if (!planned.any((p) => state.progressOf(p.key).done)) {
      return;
    }
    _resumeRowKey = blocks
        .expand((block) => block)
        .firstWhereOrNull((p) => isRequiredLogKey(p.key) && !state.progressOf(p.key).done)
        ?.key;
    if (_resumeRowKey == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resumeKey.currentContext;
      if (mounted && target != null && target.mounted) {
        Scrollable.ensureVisible(target, alignment: 0.5);
      }
    });
  }

  Future<void> _finish() async {
    final missing = ref.read(gymStateProvider).missingRequired;
    if (missing.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => FinishWorkoutDialog(missing),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    // The session page next to the list still saves the session: finishing
    // keeps the routine, day and start it reads and only resets the sets, so
    // the page doesn't depend on whether the state is cleared before or after
    // it is reached. The summary clears the rest as before.
    await ref.read(gymStateProvider.notifier).finishWorkout();
    if (!mounted) {
      return;
    }
    await widget._controller.nextPage(
      duration: DEFAULT_ANIMATION_DURATION,
      curve: DEFAULT_ANIMATION_CURVE,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final blocks = ref.watch(gymStateProvider.select((s) => s.logPagesBySlotEntry));
    final progressiveOverload = ref.watch(gymStateProvider.select((s) => s.progressiveOverload));

    // The overload options add a row of chips to their block once loaded,
    // which would push the row down again after it was scrolled to
    final settled =
        !progressiveOverload ||
        blocks.every(
          (block) => !watchOverloadSuggestions(ref, block.first.setConfigData!).isLoading,
        );
    if (settled) {
      _chooseResumeRow(ref.read(gymStateProvider), blocks);
    }

    return Column(
      children: [
        NavigationHeader(i18n.todaysWorkout, widget._controller),
        Expanded(
          // Not lazy, so the row to continue on is built and can be scrolled to
          child: SingleChildScrollView(
            key: const ValueKey('workout-list'),
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final logPages in blocks)
                  ExerciseSetsBlock(
                    logPages,
                    resumeRowKey: _resumeRowKey,
                    resumeKey: _resumeKey,
                    key: ValueKey('exercise-block-${logPages.first.setConfigData!.slotEntryId}'),
                  ),
              ],
            ),
          ),
        ),
        const RestBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: FilledButton(
            key: const ValueKey('finish-workout'),
            onPressed: _finish,
            child: Text(i18n.finishWorkout),
          ),
        ),
        NavigationFooter(widget._controller),
      ],
    );
  }
}

/// Asks before finishing with planned sets left, listing per exercise the
/// planned and the logged sets. Pops true to finish.
class FinishWorkoutDialog extends StatelessWidget {
  final List<({int slotEntryId, Exercise exercise, int planned, int logged})> missing;

  const FinishWorkoutDialog(this.missing, {super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final header = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    const cellPadding = EdgeInsets.symmetric(vertical: 4, horizontal: 4);

    return AlertDialog(
      title: Text(i18n.finishWorkoutConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i18n.finishWorkoutConfirmBody),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    Padding(
                      padding: cellPadding,
                      child: Text(i18n.finishWorkoutPlannedSets, style: header),
                    ),
                    Padding(
                      padding: cellPadding,
                      child: Text(i18n.finishWorkoutLoggedSets, style: header),
                    ),
                  ],
                ),
                for (final entry in missing)
                  TableRow(
                    key: ValueKey('finish-missing-${entry.slotEntryId}'),
                    children: [
                      Padding(
                        padding: cellPadding,
                        child: Text(entry.exercise.getTranslation(languageCode).name),
                      ),
                      Padding(
                        padding: cellPadding,
                        child: Text(
                          '${entry.planned}',
                          key: ValueKey('finish-planned-${entry.slotEntryId}'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: cellPadding,
                        child: Text(
                          '${entry.logged}',
                          key: ValueKey('finish-logged-${entry.slotEntryId}'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('finish-workout-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('finish-workout-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(i18n.finishWorkoutConfirm),
        ),
      ],
    );
  }
}

/// Width of the plate math column between last time and the weight
const double _plateColumnWidth = 36;

/// The values a set row starts with when it isn't logged yet
typedef _RowValues = ({num? weight, num? repetitions});

/// One exercise of the list layout: name, comments, last time, the overload
/// options as chips and the table of sets
class ExerciseSetsBlock extends ConsumerStatefulWidget {
  /// The planned sets of the exercise, all of the same slot entry
  final List<SlotPageEntry> logPages;

  /// The page key of the row to continue on, which gets [resumeKey]
  final String? resumeRowKey;
  final GlobalKey? resumeKey;

  const ExerciseSetsBlock(this.logPages, {this.resumeRowKey, this.resumeKey, super.key});

  @override
  ConsumerState<ExerciseSetsBlock> createState() => _ExerciseSetsBlockState();
}

class _ExerciseSetsBlockState extends ConsumerState<ExerciseSetsBlock> {
  /// Rows added with "add set" that are not logged yet
  int _addedRows = 0;

  SetConfigData get _config => widget.logPages.first.setConfigData!;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gymState = ref.watch(gymStateProvider);
    final notifier = ref.read(gymStateProvider.notifier);
    final slotEntryId = _config.slotEntryId;

    final suggestions = gymState.progressiveOverload
        ? watchOverloadSuggestions(ref, _config).value
        : null;
    final options = suggestions?.options ?? const <OverloadOption>[];
    final lastSets = [
      for (final log in suggestions?.lastSession ?? const [])
        OverloadSet(weight: log.weight, repetitions: log.repetitions!),
    ];
    final unit =
        suggestions?.lastSession.lastOrNull?.weightUnitObj?.name ?? _config.weightUnit?.name;

    // Pre-select the smallest step beyond last time, once
    final smallest = smallestOverloadOption(options);
    if (smallest != null && !gymState.overloadDecided.contains(slotEntryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.applyDefaultOverload(slotEntryId, smallest);
        }
      });
    }
    final selected = gymState.selectedOverload[slotEntryId];

    // Last time's sets as they were, the alternative to the overload options
    final asBefore = OverloadOption(type: OverloadType.asBefore, sets: lastSets);

    // Rows: the planned sets, the extra sets logged so far, then the extra
    // sets of the chosen option and the added ones still to do
    final extraLogged = gymState.extraLogs[slotEntryId] ?? const [];
    final plannedCount = widget.logPages.length;
    final optionExtras = selected == null
        ? 0
        : (selected.sets.length - plannedCount - extraLogged.length).clamp(0, 99);
    final pendingExtras = optionExtras + _addedRows;
    final profile = ref.watch(weightProfilesProvider).value?.profileFor(_config.exerciseId);

    Log? loggedAt(SlotPageEntry page) =>
        gymState.progressOf(page.key).done ? gymState.progressOf(page.key).loggedEntry : null;
    String rowKeyAt(int row) => row < plannedCount
        ? widget.logPages[row].key
        : 'pending:$slotEntryId:${row - plannedCount}';

    // What was logged so far by row: the planned sets, then the extra ones
    final loggedByRow = <int, OverloadSet>{
      for (final (index, page) in widget.logPages.indexed)
        if (loggedAt(page) case final log?)
          index: OverloadSet(weight: log.weight, repetitions: log.repetitions ?? 0),
      for (final (index, log) in extraLogged.indexed)
        plannedCount + index: OverloadSet(weight: log.weight, repetitions: log.repetitions ?? 0),
    };

    // Once a set is logged or a weight changed, the sets still to do shrink to
    // what is needed to still beat last time, or fall short (fatigue)
    final baselineVolume = suggestions?.baselineVolume ?? 0;
    final adapts =
        selected != null &&
        gymState.progressiveOverload &&
        selected.type != OverloadType.asBefore &&
        baselineVolume > 0;
    final targets = !adapts
        ? const <OverloadSet>[]
        : [
            for (final (index, set) in selected.sets.indexed)
              if (loggedByRow.containsKey(index))
                set
              else
                set.copyWith(weight: gymState.rowDrafts[rowKeyAt(index)]?.weight ?? set.weight),
          ];
    final weightChanged = [
      for (final (index, set) in targets.indexed) set.weight != selected?.sets[index].weight,
    ].any((changed) => changed);
    final rebalance = adapts && (loggedByRow.isNotEmpty || weightChanged)
        ? rebalanceRemaining(
            baselineVolume: baselineVolume,
            targets: targets,
            logged: loggedByRow,
            minReps: _config.repetitions,
            maxReps: _config.maxRepetitions,
          )
        : null;
    final rebalanced = rebalance is RebalanceFeasible ? rebalance.sets : null;

    // Short of last time even at the top of the range: offer extra sets with
    // one or two lighter weights
    final deficit = rebalance is RebalanceInfeasible ? rebalance.deficit : null;
    var lowerWeights = const <num>[];
    var fills = const <OverloadOption>[];
    if (deficit != null) {
      final current = [
        ...loggedByRow.values.map((s) => s.weight),
        ...targets.map((s) => s.weight),
      ].nonNulls.fold<num?>(null, (low, w) => low == null || w < low ? w : low);
      if (current != null) {
        lowerWeights =
            (suggestions?.knownWeights ?? const <num>[])
                .where((w) => w > 0 && w < current - weightTolerance)
                .toList()
              ..sort((a, b) => b.compareTo(a));
        lowerWeights = lowerWeights.take(2).toList();
      }
      fills = fillWithLowerWeight(
        deficit: deficit,
        lowerWeights: lowerWeights,
        minReps: _config.repetitions,
        maxReps: _config.maxRepetitions,
      );
    }

    // The chosen fill joins what was done, the rest at the top of the range
    // and the lighter sets into one option, so it is kept like any other
    void chooseFill(OverloadOption fill) {
      final maxReps = _config.maxRepetitions;
      final rows = [
        for (var row = 0; row < targets.length || loggedByRow.containsKey(row); row++)
          loggedByRow[row] ??
              (maxReps == null ? targets[row] : targets[row].copyWith(repetitions: maxReps)),
      ];
      notifier.selectOverloadOption(
        slotEntryId,
        OverloadOption(type: OverloadType.fill, sets: [...rows, ...fill.sets]),
      );
    }

    _RowValues defaultsAt(int row) {
      if (rebalanced != null && row < rebalanced.length && !loggedByRow.containsKey(row)) {
        final set = rebalanced[row];
        return (weight: set.weight, repetitions: set.repetitions);
      }
      // Beyond the option's sets its last one repeats, like in the page layout
      final optionSet = selected != null && gymState.progressiveOverload
          ? selected.sets[row.clamp(0, selected.sets.length - 1)]
          : null;
      if (optionSet != null) {
        return (weight: optionSet.weight, repetitions: optionSet.repetitions);
      }
      final page = widget.logPages.elementAtOrNull(row) ?? widget.logPages.last;
      final config = page.setConfigData!;
      return (weight: config.weight, repetitions: config.repetitions);
    }

    OverloadSet volumeSet(num? weight, num? repetitions) =>
        OverloadSet(weight: weight, repetitions: repetitions ?? 0);

    // Planned: the targets of the planned sets, what was logged, else entered,
    // else pre-filled. Actual: every set logged for the exercise so far.
    final plannedSets = [
      for (final (index, page) in widget.logPages.indexed)
        if (!isRequiredLogKey(page.key))
          null
        else if (loggedAt(page) case final log?)
          volumeSet(log.weight, log.repetitions)
        else if (gymState.rowDrafts[page.key] case final draft?)
          volumeSet(draft.weight, draft.repetitions)
        else
          volumeSet(defaultsAt(index).weight, defaultsAt(index).repetitions),
    ].nonNulls.toList();
    final actualSets = [
      for (final page in widget.logPages)
        if (loggedAt(page) case final log?) volumeSet(log.weight, log.repetitions),
      for (final log in extraLogged) volumeSet(log.weight, log.repetitions),
    ];
    final actualVolume = overloadVolume(actualSets);
    // Both with the unit once either has a weight, also "0 kg" before a set
    final weighted = [...plannedSets, ...actualSets].any((set) => (set.weight ?? 0) != 0);
    String volumeText(List<OverloadSet> sets) => [
      localizedNumberFormat(context).format(overloadVolume(sets)),
      if (weighted) ?unit,
    ].join(' ');

    final comments = _config.comment.trim();
    final languageCode = Localizations.localeOf(context).languageCode;
    final description = _config.exercise.getDescription(languageCode).trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _config.exercise
                      .getTranslation(Localizations.localeOf(context).languageCode)
                      .name,
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              if (gymState.progressiveOverload)
                IconButton(
                  key: ValueKey('available-weights-$slotEntryId'),
                  icon: const Icon(Icons.tune),
                  tooltip: i18n.weightProfile,
                  onPressed: () => _editWeights(unit),
                ),
            ],
          ),
          if (comments.isNotEmpty) LinkifiedComment(comments),
          if (description.isNotEmpty)
            Padding(
              key: ValueKey('exercise-description-$slotEntryId'),
              padding: const EdgeInsets.only(top: 4),
              child: HtmlWidget(
                description,
                onTapUrl: (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              ),
            ),
          if (_repRange(context) case final range?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                range,
                key: ValueKey('rep-range-$slotEntryId'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              i18n.gymModePlannedActualVolume(
                volumeText(plannedSets),
                volumeText(actualSets),
              ),
              key: ValueKey('volume-$slotEntryId'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: [
                ChoiceChip(
                  key: ValueKey('overload-chip-$slotEntryId-before'),
                  label: Text(i18n.progressiveOverloadAsBefore),
                  selected: selected == asBefore,
                  onSelected: (_) => notifier.selectOverloadOption(slotEntryId, asBefore),
                ),
                for (final (index, option) in options.indexed)
                  ChoiceChip(
                    key: ValueKey('overload-chip-$slotEntryId-$index'),
                    label: Text(_chipLabel(context, option, unit)),
                    selected: selected == option,
                    onSelected: (_) => notifier.selectOverloadOption(slotEntryId, option),
                  ),
              ],
            ),
          ],
          if (deficit != null) ...[
            const SizedBox(height: 4),
            Text(
              i18n.gymModeFillLowerWeightHelp,
              key: ValueKey('fill-help-$slotEntryId'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final (index, fill) in fills.indexed)
                  ActionChip(
                    key: ValueKey('fill-chip-$slotEntryId-$index'),
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(
                      '${_chipLabel(context, fill, unit)} · '
                      '${formatOverloadSets(context, fill.sets, unit)}',
                    ),
                    onPressed: () => chooseFill(fill),
                  ),
                if (lowerWeights.length < 2)
                  ActionChip(
                    key: ValueKey('fill-need-weights-$slotEntryId'),
                    avatar: const Icon(Icons.scale_outlined, size: 18),
                    label: Text(i18n.gymModeFillNeedWeights),
                    onPressed: () => _editWeights(unit),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _HeaderRow(unit: unit),
          _TotalsRow(
            slotEntryId: slotEntryId,
            previous: overloadVolume(lastSets),
            current: actualVolume,
          ),
          for (final (index, page) in widget.logPages.indexed)
            KeyedSubtree(
              key: page.key == widget.resumeRowKey ? widget.resumeKey : null,
              child: SetRow(
                key: ValueKey('set-row-${page.key}'),
                rowKey: page.key,
                previous: lastSets.elementAtOrNull(index),
                defaults: defaultsAt(index),
                logged: loggedAt(page),
                draft: gymState.rowDrafts[page.key],
                profile: profile,
                onPlateMath: (weight) => _plateMath(weight, unit),
                onDraft: (weight, reps) =>
                    notifier.setRowDraft(page.key, weight: weight, repetitions: reps),
                onLog: (reps, weight) =>
                    notifier.logSetAt(page.key, repetitions: reps, weight: weight),
                onUnlog: () => notifier.unlogSetAt(page.key),
              ),
            ),
          for (final (index, log) in extraLogged.indexed)
            SetRow(
              key: ValueKey('set-row-extra:$slotEntryId:$index'),
              rowKey: 'extra:$slotEntryId:$index',
              previous: lastSets.elementAtOrNull(plannedCount + index),
              defaults: (weight: log.weight, repetitions: log.repetitions),
              logged: log,
              profile: profile,
              onPlateMath: (weight) => _plateMath(weight, unit),
              onLog: (_, _) async {},
              onUnlog: () => notifier.removeExtraSet(slotEntryId, index),
            ),
          for (var i = 0; i < pendingExtras; i++)
            SetRow(
              key: ValueKey('set-row-pending:$slotEntryId:${extraLogged.length + i}'),
              rowKey: 'pending:$slotEntryId:${extraLogged.length + i}',
              previous: lastSets.elementAtOrNull(plannedCount + extraLogged.length + i),
              defaults: defaultsAt(plannedCount + extraLogged.length + i),
              logged: null,
              draft: gymState.rowDrafts['pending:$slotEntryId:${extraLogged.length + i}'],
              profile: profile,
              onPlateMath: (weight) => _plateMath(weight, unit),
              onDraft: (weight, reps) => notifier.setRowDraft(
                'pending:$slotEntryId:${extraLogged.length + i}',
                weight: weight,
                repetitions: reps,
              ),
              onLog: (reps, weight) async {
                await notifier.logExtraSet(
                  slotEntryId,
                  repetitions: reps,
                  weight: weight,
                  draftKey: 'pending:$slotEntryId:${extraLogged.length + i}',
                );
                if (i >= optionExtras && _addedRows > 0 && mounted) {
                  setState(() => _addedRows--);
                }
              },
              onUnlog: () async {},
            ),
          TextButton.icon(
            key: ValueKey('add-set-$slotEntryId'),
            icon: const Icon(Icons.add),
            label: Text(i18n.addSet),
            onPressed: () => setState(() => _addedRows++),
          ),
          const Divider(),
        ],
      ),
    );
  }

  /// The planned sets and repetitions, e.g. "3 sets of 3–5 reps", null
  /// without planned repetitions
  String? _repRange(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final min = _config.repetitions;
    final max = _config.maxRepetitions;
    if (min == null) {
      return null;
    }
    final reps = max == null || max == min
        ? i18n.gymModeRepCount(min)
        : i18n.gymModeRepRange(min, max);
    return i18n.gymModeSetsOfReps(i18n.gymModeSetCount(widget.logPages.length), reps);
  }

  String _chipLabel(BuildContext context, OverloadOption option, String? unit) {
    final i18n = AppLocalizations.of(context);
    return switch (option.type) {
      OverloadType.moreReps => i18n.progressiveOverloadMoreRepsShort,
      OverloadType.moreSets => i18n.progressiveOverloadMoreSetsShort,
      OverloadType.asBefore => i18n.progressiveOverloadAsBefore,
      OverloadType.heavier => [
        localizedNumberFormat(context).format(option.sets.first.weight),
        ?unit,
      ].join(' '),
      // The lighter weight of the extra sets
      OverloadType.fill => i18n.gymModeFillLowerWeight(
        [localizedNumberFormat(context).format(option.sets.last.weight), ?unit].join(' '),
      ),
    };
  }

  Future<void> _editWeights(String? unit) =>
      showWeightProfileSheet(context, exerciseId: _config.exerciseId, unit: unit);

  Future<void> _plateMath(num? weight, String? unit) =>
      showWeightProfileSheet(context, exerciseId: _config.exerciseId, weight: weight, unit: unit);
}

class _HeaderRow extends StatelessWidget {
  final String? unit;

  const _HeaderRow({this.unit});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        Expanded(flex: 3, child: Text(i18n.previous.toUpperCase(), style: style)),
        const SizedBox(width: _plateColumnWidth),
        Expanded(
          flex: 2,
          child: Text(
            [i18n.weight.toUpperCase(), if (unit != null) '($unit)'].join(' '),
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(i18n.reps.toUpperCase(), style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: 48, child: Icon(Icons.check, size: 18)),
      ],
    );
  }
}

/// The sums under the header: the volume of last time, the volume logged
/// today and how far today is ahead (green) or behind
class _TotalsRow extends StatelessWidget {
  final int slotEntryId;
  final num previous;
  final num current;

  const _TotalsRow({required this.slotEntryId, required this.previous, required this.current});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final format = localizedNumberFormat(context);
    final style = theme.textTheme.labelLarge;
    final diff = current - previous;
    final diffText = switch (diff) {
      > 0 => '+${format.format(diff)}',
      < 0 => '\u2212${format.format(-diff)}',
      _ => format.format(0),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${i18n.gymModeTotal} ${format.format(previous)}',
              key: ValueKey('total-previous-$slotEntryId'),
              style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: _plateColumnWidth),
          Expanded(
            flex: 2,
            child: Text(
              format.format(current),
              key: ValueKey('total-current-$slotEntryId'),
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              key: ValueKey('total-diff-$slotEntryId'),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: diff > 0 ? progressionHighlight(context) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diffText,
                style: style?.copyWith(color: diff < 0 ? theme.colorScheme.error : null),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// One set: what was done in the same set last time, the weight and the
/// repetitions to do (green where they beat last time) and a check to log it
class SetRow extends StatefulWidget {
  /// Prefix of the keys of the fields, unique per row
  final String rowKey;

  /// The same set of last time, null for a set that wasn't done then
  final OverloadSet? previous;

  /// What the fields start with while the set isn't logged
  final _RowValues defaults;

  /// The saved set, null while it isn't logged
  final Log? logged;

  final Future<void> Function(num? repetitions, num? weight) onLog;
  final Future<void> Function() onUnlog;

  /// Values entered before for this set, they win over [defaults]
  final RowDraft? draft;

  /// Called with the entered values on every edit, so they can be kept
  final void Function(num? weight, num? repetitions)? onDraft;

  /// The equipment weights of the exercise, to flag a weight it can't be set to
  final WeightProfile? profile;

  /// Opens the plate math for the entered weight, no column without it
  final void Function(num? weight)? onPlateMath;

  const SetRow({
    required this.rowKey,
    required this.previous,
    required this.defaults,
    required this.logged,
    required this.onLog,
    required this.onUnlog,
    this.draft,
    this.onDraft,
    this.profile,
    this.onPlateMath,
    super.key,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  /// Controllers, since the values follow the chosen option until edited
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  bool _edited = false;
  bool _seeded = false;
  bool _busy = false;

  _RowValues get _source => widget.logged == null
      ? (widget.draft ?? widget.defaults)
      : (weight: widget.logged!.weight, repetitions: widget.logged!.repetitions);

  void _seed(NumberFormat format) {
    final source = _source;
    _weight.text = source.weight == null ? '' : format.format(source.weight);
    _reps.text = source.repetitions == null ? '' : format.format(source.repetitions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      _seeded = true;
      _edited = widget.draft != null;
      _seed(localizedNumberFormat(context));
    }
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loggedChanged = !identical(oldWidget.logged, widget.logged);
    final defaultsChanged = oldWidget.defaults != widget.defaults;
    if (loggedChanged || (!_edited && widget.logged == null && defaultsChanged)) {
      if (loggedChanged) {
        _edited = false;
      }
      _seed(localizedNumberFormat(context));
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  num? _parse(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : localizedNumberFormat(context).tryParse(text);
  }

  Future<void> _toggle() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.logged == null) {
        await widget.onLog(_parse(_reps), _parse(_weight));
      } else {
        await widget.onUnlog();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = localizedNumberFormat(context);
    final previous = widget.previous;
    final weight = _parse(_weight);
    final reps = _parse(_reps);
    final done = widget.logged != null;

    final heavier = weight != null && (previous == null || weight > (previous.weight ?? 0));
    final moreReps = reps != null && (previous == null || reps > previous.repetitions);
    final highlight = progressionHighlight(context);
    // For a weight the equipment weights can't be set to, the plate math icon
    // turns into a warning
    final profile = widget.profile;
    final reachable =
        weight == null || weight == 0 || profile == null || loadoutFor(profile, weight) != null;

    String previousText() {
      if (previous == null) {
        return '–';
      }
      final repsText = format.format(previous.repetitions);
      return previous.weight == null || previous.weight == 0
          ? repsText
          : '${format.format(previous.weight)} × $repsText';
    }

    Widget cell(TextEditingController controller, String suffix, {required bool green}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: TextField(
          key: ValueKey('${widget.rowKey}-$suffix'),
          controller: controller,
          enabled: !done,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [LocalizedDecimalInputFormatter(format.symbols.DECIMAL_SEP)],
          onChanged: (_) {
            setState(() => _edited = true);
            widget.onDraft?.call(_parse(_weight), _parse(_reps));
          },
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: green ? highlight : Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    }

    return Container(
      color: done ? theme.colorScheme.surfaceContainerHighest : null,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              previousText(),
              key: ValueKey('${widget.rowKey}-previous'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.onPlateMath case final onPlateMath?)
            SizedBox(
              width: _plateColumnWidth,
              child: IconButton(
                key: ValueKey('${widget.rowKey}-plates'),
                padding: EdgeInsets.zero,
                tooltip: AppLocalizations.of(context).weightProfile,
                onPressed: () => onPlateMath(weight),
                icon: Icon(
                  reachable ? Icons.fitness_center : Icons.warning_amber_rounded,
                  size: 20,
                  color: reachable ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
                ),
              ),
            )
          else
            const SizedBox(width: _plateColumnWidth),
          Expanded(flex: 2, child: cell(_weight, 'weight', green: heavier)),
          Expanded(flex: 2, child: cell(_reps, 'reps', green: moreReps)),
          SizedBox(
            width: 48,
            child: IconButton(
              key: ValueKey('${widget.rowKey}-done'),
              onPressed: _busy ? null : _toggle,
              icon: Icon(
                done ? Icons.check_box : Icons.check_box_outline_blank,
                color: done ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rest after a logged set, counting down (or up without a rest time),
/// with a button to end it
class RestBar extends ConsumerStatefulWidget {
  const RestBar({super.key});

  @override
  ConsumerState<RestBar> createState() => _RestBarState();
}

class _RestBarState extends ConsumerState<RestBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final gymState = ref.watch(gymStateProvider);
    final startedAt = gymState.restStartedAt;
    if (startedAt == null) {
      return const SizedBox.shrink();
    }

    final now = clock.now();
    final endsAt = gymState.restEndsAt;
    final shown = endsAt == null ? now.difference(startedAt) : endsAt.difference(now);
    final seconds = shown.isNegative ? 0 : shown.inSeconds;
    final time = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final notifier = ref.read(gymStateProvider.notifier);

    // Same adjustments as on the timer page, only for a countdown
    final slotPage = gymState.getSlotEntryPageByIndex();
    final minimum = slotPage == null ? null : gymState.restDurationFor(slotPage)?.inSeconds;
    final maximum = slotPage?.setConfigData?.maxRestTime?.toInt();
    const compact = VisualDensity.compact;

    return Material(
      key: const ValueKey('rest-bar'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(i18n.gymModeRest(time), style: Theme.of(context).textTheme.titleMedium),
            ),
            if (endsAt != null) ...[
              IconButton(
                key: const ValueKey('rest-bar-minus'),
                visualDensity: compact,
                tooltip: '-15s',
                onPressed: seconds == 0
                    ? null
                    : () => notifier.extendRest(const Duration(seconds: -15)),
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                key: const ValueKey('rest-bar-plus'),
                visualDensity: compact,
                tooltip: '+15s',
                onPressed: () => notifier.extendRest(const Duration(seconds: 15)),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                key: const ValueKey('rest-bar-min'),
                visualDensity: compact,
                tooltip: minimum == null ? 'Reset to min' : 'Reset to ${minimum}s (min)',
                onPressed: minimum == null
                    ? null
                    : () => notifier.resetRest(Duration(seconds: minimum)),
                icon: const Icon(Icons.timer),
              ),
              IconButton(
                key: const ValueKey('rest-bar-max'),
                visualDensity: compact,
                tooltip: maximum == null ? 'Reset to max' : 'Reset to ${maximum}s (max)',
                onPressed: maximum == null
                    ? null
                    : () => notifier.resetRest(Duration(seconds: maximum)),
                icon: const Icon(Icons.timer_outlined),
              ),
            ],
            TextButton(
              key: const ValueKey('rest-bar-skip'),
              onPressed: () => ref.read(gymStateProvider.notifier).skipRest(),
              child: Text(i18n.gymModeSkipRest),
            ),
          ],
        ),
      ),
    );
  }
}
