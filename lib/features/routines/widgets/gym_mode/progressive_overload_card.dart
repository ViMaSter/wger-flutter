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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/progressive_overload_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/weight_profile_sheet.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// The progressive overload suggestions for the set of [setConfig] in the
/// running workout
AsyncValue<OverloadSuggestions> watchOverloadSuggestions(
  WidgetRef ref,
  SetConfigData setConfig,
) {
  final workoutStart = ref.watch(gymStateProvider.select((s) => s.workoutStart));
  // Last time's extra sets don't raise the bar, only as many sets as planned
  final plannedSets = ref.watch(
    gymStateProvider.select(
      (s) => s.requiredLogPages
          .where((p) => p.setConfigData?.slotEntryId == setConfig.slotEntryId)
          .length,
    ),
  );
  return ref.watch(
    overloadSuggestionsProvider(
      exerciseId: setConfig.exerciseId,
      before: workoutStart,
      minReps: setConfig.repetitions,
      maxReps: setConfig.maxRepetitions,
      plannedSets: plannedSets == 0 ? null : plannedSets,
    ),
  );
}

/// [sets] as text, e.g. "10 / 10 / 9 × 20 kg" or, with different weights,
/// "10 × 20 kg, 8 × 22.5 kg"
String formatOverloadSets(BuildContext context, List<OverloadSet> sets, String? unit) {
  final numberFormat = localizedNumberFormat(context);
  String weightText(num weight) => [numberFormat.format(weight), ?unit].join(' ');
  bool hasWeight(OverloadSet set) => set.weight != null && set.weight != 0;

  final weights = sets.map((s) => hasWeight(s) ? s.weight : null).toSet();
  if (weights.length == 1) {
    final reps = sets.map((s) => numberFormat.format(s.repetitions)).join(' / ');
    final weight = weights.single;
    return weight == null ? reps : '$reps × ${weightText(weight)}';
  }

  return sets
      .map(
        (s) => hasWeight(s)
            ? '${numberFormat.format(s.repetitions)} × ${weightText(s.weight!)}'
            : numberFormat.format(s.repetitions),
      )
      .join(', ');
}

bool _hasWeight(OverloadSet set) => set.weight != null && set.weight != 0;

/// How the volume of [sets] adds up, repeated sets in a row grouped, e.g.
/// "3 × (5 × 30 kg) + 5 × 35 kg" or, without weight, "2 × 15 + 12"
String formatVolumeCalculation(BuildContext context, List<OverloadSet> sets, String? unit) {
  final numberFormat = localizedNumberFormat(context);
  String setText(OverloadSet set) => _hasWeight(set)
      ? '${numberFormat.format(set.repetitions)} × '
            '${[numberFormat.format(set.weight), ?unit].join(' ')}'
      : numberFormat.format(set.repetitions);

  final parts = <String>[];
  var i = 0;
  while (i < sets.length) {
    var count = 1;
    while (i + count < sets.length && sets[i + count] == sets[i]) {
      count++;
    }
    final text = setText(sets[i]);
    parts.add(
      count == 1
          ? text
          : _hasWeight(sets[i])
          ? '$count × ($text)'
          : '$count × $text',
    );
    i += count;
  }
  return parts.join(' + ');
}

/// The volume of [sets] with the weight unit, or as plain repetitions when
/// no set has a weight
String formatVolume(BuildContext context, List<OverloadSet> sets, String? unit) {
  final volume = localizedNumberFormat(context).format(overloadVolume(sets));
  return sets.any(_hasWeight) ? [volume, ?unit].join(' ') : volume;
}

/// e.g. "775 ÷ 32.5 = 23.8", the volume of [lastSets] over the weight of the
/// heavier [option]
String formatRequiredCalculation(
  BuildContext context,
  List<OverloadSet> lastSets,
  OverloadOption option,
) {
  final numberFormat = localizedNumberFormat(context);
  final volume = overloadVolume(lastSets);
  final weight = option.sets.first.weight!;
  final ratio = (localizedNumberFormat(context)..maximumFractionDigits = 1).format(
    volume / weight,
  );
  return '${numberFormat.format(volume)} ÷ ${numberFormat.format(weight)} = $ratio';
}

/// Shows what was done in the last session of an exercise and lets the user
/// choose a way to do at least as much today
class ProgressiveOverloadCard extends ConsumerWidget {
  final SetConfigData setConfig;

  const ProgressiveOverloadCard(this.setConfig, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final suggestions = watchOverloadSuggestions(ref, setConfig);
    final selected = ref.watch(
      gymStateProvider.select((s) => s.selectedOverload[setConfig.slotEntryId]),
    );

    return Card(
      key: const ValueKey('progressive-overload-card'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: switch (suggestions) {
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(i18n.progressiveOverload, style: theme.textTheme.titleMedium),
                subtitle: value.lastSession.isEmpty
                    ? Text(i18n.progressiveOverloadFirstTime)
                    : Text(
                        i18n.progressiveOverloadLastTime(
                          formatVolumeCalculation(context, _lastSets(value), _unitOf(value)),
                          formatVolume(context, _lastSets(value), _unitOf(value)),
                        ),
                      ),
                trailing: IconButton(
                  key: const ValueKey('progressive-overload-edit-weights'),
                  icon: const Icon(Icons.tune),
                  tooltip: i18n.availableWeights,
                  onPressed: () => _editWeights(context, ref, _unitOf(value)),
                ),
              ),
              if (value.options.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(i18n.progressiveOverloadIntro, style: theme.textTheme.bodySmall),
                ),
                _OptionTile(
                  key: const ValueKey('overload-option-planned'),
                  title: i18n.progressiveOverloadAsPlanned,
                  subtitle: setConfig.textReprShort ?? setConfig.textRepr,
                  selected: selected == null,
                  onTap: () => _select(ref, null),
                ),
                for (final (index, option) in value.options.indexed)
                  _OptionTile(
                    key: ValueKey('overload-option-$index'),
                    title: _typeLabel(i18n, option.type),
                    subtitle: [
                      [
                        formatOverloadSets(context, option.sets, _unitOf(value)),
                        i18n.progressiveOverloadVolume(
                          formatVolume(context, option.sets, _unitOf(value)),
                        ),
                      ].join(' · '),
                      if (option.requiredRepetitions != null)
                        i18n.progressiveOverloadRequiredReps(
                          option.requiredRepetitions!,
                          formatRequiredCalculation(context, _lastSets(value), option),
                        ),
                    ].join('\n'),
                    selected: selected == option,
                    onTap: () => _select(ref, option),
                  ),
                if (!value.options.any((o) => o.type == OverloadType.moreReps))
                  _Hint(i18n.progressiveOverloadAtMaxReps),
                if (!value.hasAvailableWeights) _Hint(i18n.progressiveOverloadNoWeights),
              ],
            ],
          ),
          AsyncError(:final error, :final stackTrace) => StreamErrorIndicator(
            error,
            stacktrace: stackTrace,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  static List<OverloadSet> _lastSets(OverloadSuggestions suggestions) => [
    for (final log in suggestions.lastSession)
      OverloadSet(weight: log.weight, repetitions: log.repetitions!),
  ];

  String? _unitOf(OverloadSuggestions suggestions) =>
      suggestions.lastSession.lastOrNull?.weightUnitObj?.name ?? setConfig.weightUnit?.name;

  void _select(WidgetRef ref, OverloadOption? option) {
    ref.read(gymStateProvider.notifier).selectOverloadOption(setConfig.slotEntryId, option);
  }

  Future<void> _editWeights(BuildContext context, WidgetRef ref, String? unit) =>
      showWeightProfileSheet(context, exerciseId: setConfig.exerciseId, unit: unit);

  static String _typeLabel(AppLocalizations i18n, OverloadType type) => switch (type) {
    OverloadType.moreReps => i18n.progressiveOverloadMoreReps,
    OverloadType.heavier => i18n.progressiveOverloadHeavier,
    OverloadType.moreSets => i18n.progressiveOverloadMoreSets,
    OverloadType.asBefore => i18n.progressiveOverloadAsBefore,
    // Only offered in the list layout, after a set fell short
    OverloadType.fill => i18n.gymModeFillLowerWeightHelp,
  };
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
      title: Text(title),
      subtitle: Text(subtitle),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Compact line on a log page: the target of the chosen progressive overload
/// option for this set, or a button to choose one. Opens the options in a
/// bottom sheet, so they're at hand without the exercise overview pages.
class ProgressiveOverloadHint extends ConsumerWidget {
  final SlotPageEntry slotPage;

  const ProgressiveOverloadHint(this.slotPage, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final gymState = ref.watch(gymStateProvider);
    final setConfig = slotPage.setConfigData!;
    final suggestions = watchOverloadSuggestions(ref, setConfig);

    // Nothing to suggest (yet): no hint, the log page stays as it is
    final value = suggestions.value;
    if (value == null || value.options.isEmpty) {
      return const SizedBox.shrink();
    }

    final target = gymState.overloadSetFor(slotPage);
    final option = gymState.selectedOverload[setConfig.slotEntryId];
    final logPages = gymState.logPagesOfEntry(slotPage);
    final hasExtraSet =
        option != null &&
        logPages.lastOrNull?.key == slotPage.key &&
        option.sets.length > logPages.length;
    final unit = value.lastSession.lastOrNull?.weightUnitObj?.name ?? setConfig.weightUnit?.name;

    final label = target == null
        ? i18n.progressiveOverloadChoose
        : [
            i18n.progressiveOverloadTarget(formatOverloadSets(context, [target], unit)),
            if (hasExtraSet) i18n.progressiveOverloadExtraSet,
          ].join(' · ');

    return TextButton.icon(
      key: const ValueKey('progressive-overload-hint'),
      icon: const Icon(Icons.trending_up),
      label: Text(label, textAlign: TextAlign.center),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: ProgressiveOverloadCard(setConfig),
          ),
        ),
      ),
    );
  }
}
