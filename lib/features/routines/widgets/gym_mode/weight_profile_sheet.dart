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
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/widgets/decimal_input.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Opens the equipment weights of [exerciseId]: how to set up [weight] with the
/// assigned equipment (plate math), which equipment the exercise uses, and an
/// editor for it
Future<void> showWeightProfileSheet(
  BuildContext context, {
  required int exerciseId,
  num? weight,
  String? unit,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => WeightProfileSheet(exerciseId: exerciseId, weight: weight, unit: unit),
);

/// The lines describing how to set up [loadout], e.g. "Bar 10", "Per side: 5 + 1.25"
List<String> describeLoadout(AppLocalizations i18n, Loadout loadout, NumberFormat format) {
  String join(List<num> weights) => weights.map(format.format).join(' + ');
  return switch (loadout.kind) {
    WeightProfileKind.fixed =>
      loadout.pair
          ? [i18n.loadoutFixedPair(format.format((loadout.fixed ?? loadout.total) / 2))]
          : [i18n.loadoutFixed(format.format(loadout.fixed ?? loadout.total))],
    WeightProfileKind.plates => [
      i18n.loadoutBar(format.format(loadout.base)),
      if (loadout.perSide.isNotEmpty) i18n.loadoutPerSide(join(loadout.perSide)),
    ],
    WeightProfileKind.linear => [
      i18n.loadoutPin(format.format(loadout.pin ?? loadout.base)),
      if (loadout.addOns.isNotEmpty) i18n.loadoutAddOn(join(loadout.addOns)),
    ],
  };
}

class WeightProfileSheet extends ConsumerWidget {
  final int exerciseId;

  /// The weight of the row the sheet was opened from, null to only configure
  final num? weight;
  final String? unit;

  const WeightProfileSheet({required this.exerciseId, this.weight, this.unit, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final format = localizedNumberFormat(context);
    final unitSuffix = unit == null ? '' : ' $unit';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: switch (ref.watch(weightProfilesProvider)) {
          AsyncData(:final value) => _content(context, ref, i18n, theme, format, unitSuffix, value),
          AsyncError(:final error) => Text(error.toString()),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations i18n,
    ThemeData theme,
    NumberFormat format,
    String unitSuffix,
    WeightProfilesState state,
  ) {
    final profile = state.profileFor(exerciseId);
    final notifier = ref.read(weightProfilesProvider.notifier);
    final rowWeight = weight;
    final loadout = (profile == null || rowWeight == null) ? null : loadoutFor(profile, rowWeight);

    Future<void> edit(WeightProfile? initial) async {
      final saved = await showDialog<WeightProfile>(
        context: context,
        builder: (_) => WeightProfileEditor(initial: initial, unit: unit),
      );
      if (saved == null) {
        return;
      }
      await notifier.upsertProfile(saved);
      await notifier.assign(exerciseId, saved.id);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(i18n.weightProfile, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (rowWeight != null) ...[
            Text(
              i18n.weightProfileSetup('${format.format(rowWeight)}$unitSuffix'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            if (profile == null)
              Text(i18n.weightProfileNone, key: const ValueKey('weight-profile-none'))
            else if (loadout == null)
              Text(
                i18n.weightProfileUnreachable('${format.format(rowWeight)}$unitSuffix'),
                key: const ValueKey('weight-profile-unreachable'),
                style: TextStyle(color: theme.colorScheme.error),
              )
            else
              for (final line in describeLoadout(i18n, loadout, format))
                Text(line, key: ValueKey('loadout-$line'), style: theme.textTheme.bodyLarge),
            const Divider(height: 24),
          ],
          DropdownButtonFormField<String?>(
            key: const ValueKey('weight-profile-select'),
            initialValue: profile?.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: i18n.weightProfileAssign),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('–')),
              for (final p in state.profiles)
                DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
            ],
            onChanged: (id) => notifier.assign(exerciseId, id),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (profile != null)
                OutlinedButton.icon(
                  key: const ValueKey('weight-profile-edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(i18n.weightProfileEdit),
                  onPressed: () => edit(profile),
                ),
              OutlinedButton.icon(
                key: const ValueKey('weight-profile-create'),
                icon: const Icon(Icons.add),
                label: Text(i18n.weightProfileCreate),
                onPressed: () => edit(null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Creates or edits a [WeightProfile], pops with the result
class WeightProfileEditor extends StatefulWidget {
  final WeightProfile? initial;
  final String? unit;

  const WeightProfileEditor({this.initial, this.unit, super.key});

  @override
  State<WeightProfileEditor> createState() => _WeightProfileEditorState();
}

class _WeightProfileEditorState extends State<WeightProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late WeightProfile _draft;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.initial ??
        WeightProfile.defaultPlates(
          id: 'profile-${DateTime.now().microsecondsSinceEpoch}',
          name: '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    Widget number(String key, String label, num? value, ValueChanged<num?> onChanged) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecimalInputWidget(
        key: ValueKey('weight-profile-$key-${_draft.kind.name}'),
        value: value,
        labelText: label,
        suffixText: widget.unit,
        maxDecimalPlaces: 3,
        onChanged: onChanged,
      ),
    );

    return AlertDialog(
      title: Text(widget.initial == null ? i18n.weightProfileCreate : i18n.weightProfileEdit),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const ValueKey('weight-profile-name'),
                initialValue: _draft.name,
                decoration: InputDecoration(labelText: i18n.weightProfileName),
                validator: (v) => (v == null || v.trim().isEmpty) ? i18n.enterValue : null,
                onSaved: (v) => _draft = _draft.copyWith(name: v!.trim()),
              ),
              const SizedBox(height: 12),
              Text(i18n.weightProfileKind),
              const SizedBox(height: 4),
              SegmentedButton<WeightProfileKind>(
                key: const ValueKey('weight-profile-kind'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: WeightProfileKind.plates,
                    label: Text(i18n.weightProfileKindPlates),
                  ),
                  ButtonSegment(
                    value: WeightProfileKind.fixed,
                    label: Text(i18n.weightProfileKindFixed),
                  ),
                  ButtonSegment(
                    value: WeightProfileKind.linear,
                    label: Text(i18n.weightProfileKindLinear),
                  ),
                ],
                selected: {_draft.kind},
                onSelectionChanged: (s) => setState(() => _draft = _draft.copyWith(kind: s.first)),
              ),
              ...switch (_draft.kind) {
                WeightProfileKind.plates => [
                  number(
                    'base',
                    i18n.weightProfileBar,
                    _draft.base,
                    (v) => _draft = _draft.copyWith(base: v ?? 0),
                  ),
                  _WeightListEditor(
                    key: const ValueKey('weight-profile-plates'),
                    label: i18n.weightProfilePlates,
                    weights: _draft.plates,
                    unit: widget.unit,
                    onChanged: (w) => setState(() => _draft = _draft.copyWith(plates: w)),
                  ),
                ],
                WeightProfileKind.fixed => [
                  SwitchListTile(
                    key: const ValueKey('weight-profile-pair'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(i18n.weightProfilePair),
                    subtitle: Text(i18n.weightProfilePairHint),
                    value: _draft.pair,
                    onChanged: (v) => setState(() => _draft = _draft.copyWith(pair: v)),
                  ),
                  _WeightListEditor(
                    key: const ValueKey('weight-profile-fixed'),
                    label: i18n.weightProfileFixedWeights,
                    weights: _draft.fixed,
                    unit: widget.unit,
                    onChanged: (w) => setState(() => _draft = _draft.copyWith(fixed: w)),
                  ),
                ],
                WeightProfileKind.linear => [
                  number(
                    'base',
                    i18n.weightProfileStart,
                    _draft.base,
                    (v) => _draft = _draft.copyWith(base: v ?? 0),
                  ),
                  number(
                    'step',
                    i18n.weightProfileStep,
                    _draft.step,
                    (v) => _draft = _draft.copyWith(step: v),
                  ),
                  number(
                    'max',
                    i18n.weightProfileMax,
                    _draft.max,
                    (v) => _draft = _draft.copyWith(max: v),
                  ),
                  _WeightListEditor(
                    key: const ValueKey('weight-profile-bonus'),
                    label: i18n.weightProfileBonus,
                    weights: _draft.bonus,
                    unit: widget.unit,
                    // Add-ons can repeat, e.g. two 0.625 weights
                    allowDuplicates: true,
                    onChanged: (w) => setState(() => _draft = _draft.copyWith(bonus: w)),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          key: const ValueKey('weight-profile-save'),
          onPressed: () {
            final form = _formKey.currentState!;
            if (!form.validate()) {
              return;
            }
            form.save();
            Navigator.of(context).pop(_draft);
          },
          child: Text(i18n.save),
        ),
      ],
    );
  }
}

/// A list of weights as deletable chips plus an input to add one
class _WeightListEditor extends StatefulWidget {
  final String label;
  final List<num> weights;
  final String? unit;
  final bool allowDuplicates;
  final ValueChanged<List<num>> onChanged;

  const _WeightListEditor({
    required this.label,
    required this.weights,
    required this.onChanged,
    this.unit,
    this.allowDuplicates = false,
    super.key,
  });

  @override
  State<_WeightListEditor> createState() => _WeightListEditorState();
}

class _WeightListEditorState extends State<_WeightListEditor> {
  /// The value in the input field, not yet added
  num? _pending;

  /// Bumped on every add, so the input field starts over empty
  int _inputGeneration = 0;

  void _add() {
    final value = _pending;
    if (value == null || value <= 0) {
      return;
    }
    final next = widget.allowDuplicates
        ? ([...widget.weights, value]..sort())
        : ({...widget.weights, value}.toList()..sort());
    widget.onChanged(next);
    setState(() {
      _pending = null;
      _inputGeneration++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final format = localizedNumberFormat(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (index, weight) in widget.weights.indexed)
                InputChip(
                  key: ValueKey('weight-chip-$index-$weight'),
                  label: Text(format.format(weight)),
                  onDeleted: () => widget.onChanged([...widget.weights]..removeAt(index)),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DecimalInputWidget(
                  key: ValueKey('weight-input-$_inputGeneration'),
                  value: null,
                  labelText: i18n.weight,
                  suffixText: widget.unit,
                  maxDecimalPlaces: 3,
                  onChanged: (value) => _pending = value,
                ),
              ),
              IconButton(
                key: const ValueKey('weight-add'),
                icon: const Icon(Icons.add),
                tooltip: i18n.add,
                onPressed: _add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
