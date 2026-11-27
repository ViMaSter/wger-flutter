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
import 'package:wger/features/routines/models/muscle_overload_plan.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/muscle_overload_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// The overload per muscle group of the running workout, null (as data)
/// unless it is the first session of its day after a programme switch or
/// with progressive overload turned off
AsyncValue<MuscleOverloadPlan?> watchMuscleOverloadPlan(WidgetRef ref) {
  final args = ref.watch(
    gymStateProvider.select((s) {
      if (!s.isInitialized || !s.progressiveOverload) {
        return null;
      }
      final planned = <int, int>{};
      for (final page in s.requiredLogPages) {
        final id = page.setConfigData!.slotEntryId;
        planned[id] = (planned[id] ?? 0) + 1;
      }
      return (
        routineId: s.routine.id!,
        routineStart: s.routine.start,
        before: s.workoutStart,
        entries: PlannedEntries([
          for (final block in s.logPagesBySlotEntry)
            if (planned[block.first.setConfigData!.slotEntryId] case final sets? when sets > 0)
              (config: block.first.setConfigData!, plannedSets: sets),
        ]),
      );
    }),
  );
  if (args == null) {
    return const AsyncData(null);
  }
  return ref.watch(
    muscleOverloadPlanProvider(
      routineId: args.routineId,
      routineStart: args.routineStart,
      before: args.before,
      entries: args.entries,
    ),
  );
}

/// Shown above the exercises on the first session of a day after a
/// programme switch: which session the muscle groups are compared with,
/// today's planned volume of each against it, and the ones that stay short
class ProgrammeSwitchCard extends StatelessWidget {
  final MuscleOverloadPlan plan;

  const ProgrammeSwitchCard(this.plan, {super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numberFormat = localizedNumberFormat(context);
    String volume(num value) => numberFormat.format(value.round());

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(i18n.muscleOverloadTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              i18n.muscleOverloadCompared(
                localizedDate(context).format(plan.baselineDate.toLocal()),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final target in plan.targets)
              Padding(
                key: ValueKey('muscle-target-${target.muscle}'),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      target.reached ? Icons.arrow_upward : Icons.warning_amber,
                      size: 16,
                      color: target.reached ? theme.colorScheme.primary : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        target.reached
                            ? i18n.muscleOverloadTarget(
                                target.muscle,
                                volume(target.planned),
                                volume(target.baseline),
                              )
                            : i18n.muscleOverloadGap(target.muscle, volume(target.gap)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
