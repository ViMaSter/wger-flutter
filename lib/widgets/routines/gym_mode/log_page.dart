/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart' as provider;
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wger/exceptions/http_exception.dart';
import 'package:wger/helpers/consts.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/models/workouts/log.dart';
import 'package:wger/models/workouts/set_config_data.dart';
import 'package:wger/models/workouts/slot_entry.dart';
import 'package:wger/providers/gym_state.dart';
import 'package:wger/providers/plate_weights.dart';
import 'package:wger/providers/routines.dart';
import 'package:wger/screens/configure_plates_screen.dart';
import 'package:wger/widgets/core/core.dart';
import 'package:wger/widgets/core/progress_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:wger/widgets/routines/forms/reps_unit.dart';
import 'package:wger/widgets/routines/forms/rir.dart';
import 'package:wger/widgets/routines/forms/weight_unit.dart';
import 'package:wger/widgets/routines/gym_mode/navigation.dart';
import 'package:wger/widgets/routines/plate_calculator.dart';

class LogPage extends ConsumerStatefulWidget {
  final _logger = Logger('LogPage');

  final PageController _controller;

  LogPage(this._controller);

  @override
  _LogPageState createState() => _LogPageState();
}

/// A small, local linkify widget that underlines links and makes them tappable.
/// This avoids adding an external dependency. It recognizes http(s) URLs.
class LinkifyText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const LinkifyText(
    this.text, {
    super.key,
    this.textAlign,
    this.style,
    this.linkStyle,
  });

  static final _urlRegExp = RegExp(r"(https?:\/\/[^\s]+)", caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegExp.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(
        text,
        textAlign: textAlign,
        style: style,
      );
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: style));
      }

      final url = text.substring(m.start, m.end);
      spans.add(TextSpan(
        text: url,
        style: linkStyle ?? style?.copyWith(decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open $url.')),
                  );
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open $url.')),
                );
              }
            }
          },
      ));

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(children: spans, style: style),
    );
  }
}

class _LogPageState extends ConsumerState<LogPage> {
  final GlobalKey<_LogFormWidgetState> _logFormKey = GlobalKey<_LogFormWidgetState>();

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      updateWatch();
    });
  }

  void _sendWatchContext() async {
    if (!mounted) {
      return;
    }
    final watch = WatchConnectivity();
    final receivedContexts = await watch.receivedApplicationContexts;

  if (!mounted) {
    return;
  }
    final mergedContext = <String, dynamic>{
      ...receivedContexts.fold<Map<String, dynamic>>({}, (acc, map) => {...acc, ...map}),
      'exercise': {
        'exerciseName': _logFormKey.currentState?._log.exercise.getTranslation(
          Localizations.localeOf(context).languageCode,
        ).name,
        'weight': _logFormKey.currentState?._weightController.text,
        'repetitions': _logFormKey.currentState?._repetitionsController.text,
        'currentSetCount': _logFormKey.currentState != null
            ? (ref
                    .read(gymStateProvider)
                    .getSlotEntryPageByIndex()!
                    .setIndex +
                1)
            : null,
        'totalSetCount': _logFormKey.currentState != null
            ? ref
                .read(gymStateProvider)
                .getPageByIndex()!
                .slotPages
                .where((e) => e.type == SlotPageType.log)
                .length
            : null,
      },
    };

    await watch.sendMessage(mergedContext);
    if (!mounted) {
      return;
    }
    print('[WATCH CONNECTIVITY] Sent merged exercise context: $mergedContext');
  }

  void updateWatch() {
    final state = _logFormKey.currentState;
    if (state == null) {
      return;
    }

    state._repetitionsController
      ..removeListener(_sendWatchContext)
      ..addListener(_sendWatchContext);
    state._weightController
      ..removeListener(_sendWatchContext)
      ..addListener(_sendWatchContext);

    _sendWatchContext();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(gymStateProvider);

    final page = state.getPageByIndex();
    if (page == null) {
      widget._logger.info(
        'getPageByIndex for ${state.currentPage} returned null, showing empty container.',
      );
      return Container();
    }

    final slotEntryPage = state.getSlotEntryPageByIndex();
    if (slotEntryPage == null) {
      widget._logger.info(
        'getSlotPageByIndex for ${state.currentPage} returned null, showing empty container',
      );
      return Container();
    }

    final setConfigData = slotEntryPage.setConfigData!;

    final log = Log.fromSetConfigData(setConfigData)
      ..routineId = state.routine.id!
      ..iteration = state.iteration;

    // Mark done sets
    final decorationStyle = slotEntryPage.logDone
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    return Column(
      children: [
        NavigationHeader(
          log.exercise.getTranslation(Localizations.localeOf(context).languageCode).name,
          widget._controller,
        ),

        Container(
          color: theme.colorScheme.onInverseSurface,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Column(
              children: [
                Column(
                  children: [
                    Text(
                      setConfigData.textRepr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: decorationStyle,
                      ),
                    ),
                    if (setConfigData.type != SlotEntryType.normal)
                      Text(
                        setConfigData.type.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: decorationStyle,
                        ),
                      ),
                  ],
                ),
                Text(
                  '${slotEntryPage.setIndex + 1} / ${page.slotPages.where((e) => e.type == SlotPageType.log).length}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (log.exercise.showPlateCalculator) const LogsPlatesWidget(),
        if (slotEntryPage.setConfigData!.comment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: LinkifyText(
              slotEntryPage.setConfigData!.comment,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
              linkStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: (state.routine.filterLogsByExercise(log.exercise.id!).isNotEmpty)
              ? LogsPastLogsWidget(
                  log: log,
                  pastLogs: state.routine.filterLogsByExercise(log.exercise.id!),
                  onCopy: (pastLog) {
                    _logFormKey.currentState?.copyFromPastLog(pastLog);
                    updateWatch();
                  },
                  setStateCallback: (fn) {
                    setState(fn);
                  },
                )
              : Container(),
        ),

        Padding(
          padding: const EdgeInsets.all(10),
          child: Card(
            color: Theme.of(context).colorScheme.inversePrimary,
            // color: Theme.of(context).secondaryHeaderColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: LogFormWidget(
                key: _logFormKey,
                controller: widget._controller,
                configData: setConfigData,
                log: log,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
        NavigationFooter(widget._controller),
      ],
    );
  }
}

class LogsPlatesWidget extends ConsumerWidget {
  const LogsPlatesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plateWeightsState = ref.watch(plateCalculatorProvider);

    return Container(
      color: Theme.of(context).colorScheme.onInverseSurface,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(ConfigurePlatesScreen.routeName);
            },
            child: SizedBox(
              child: plateWeightsState.hasPlates
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...plateWeightsState.calculatePlates.entries.map(
                          (entry) => Row(
                            children: [
                              Text(entry.value.toString()),
                              const Text('×'),
                              PlateWeight(
                                value: entry.key,
                                size: 37,
                                padding: 2,
                                margin: 0,
                                color: ref.read(plateCalculatorProvider).getColor(entry.key),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: MutedText(
                        AppLocalizations.of(context).plateCalculatorNotDivisible,
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 3),
        ],
      ),
    );
  }
}

class LogsRepsWidget extends StatelessWidget {
  final TextEditingController controller;
  final SetConfigData configData;
  final FocusNode focusNode;
  final Log log;
  final void Function(VoidCallback fn) setStateCallback;

  final _logger = Logger('LogsRepsWidget');

  LogsRepsWidget({
    super.key,
    required this.controller,
    required this.configData,
    required this.focusNode,
    required this.log,
    required this.setStateCallback,
  });

  @override
  Widget build(BuildContext context) {
    final repsValueChange = configData.repetitionsRounding ?? 1;
    final numberFormat = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

    final i18n = AppLocalizations.of(context);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.black),
          onPressed: () {
            final currentValue = numberFormat.tryParse(controller.text) ?? 0;
            final newValue = currentValue - repsValueChange;
            if (newValue >= 0) {
              setStateCallback(() {
                log.repetitions = newValue;
                controller.text = numberFormat.format(newValue);
              });
            }
          },
        ),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(labelText: i18n.repetitions),
            enabled: true,
            controller: controller,
            keyboardType: textInputTypeDecimal,
            focusNode: focusNode,
            onChanged: (value) {
              try {
                final newValue = numberFormat.parse(value);
                setStateCallback(() {
                  log.repetitions = newValue;
                });
              } on FormatException catch (error) {
                _logger.fine('Error parsing repetitions: $error');
              }
            },
            onSaved: (newValue) {
              _logger.info('Saving new reps value: $newValue');
              setStateCallback(() {
                log.repetitions = numberFormat.parse(newValue!);
              });
            },
            validator: (value) {
              if (numberFormat.tryParse(value ?? '') == null) {
                return i18n.enterValidNumber;
              }
              return null;
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: () {
            final value = controller.text.isNotEmpty ? controller.text : '0';

            try {
              final newValue = numberFormat.parse(value) + repsValueChange;
              setStateCallback(() {
                log.repetitions = newValue;
                controller.text = numberFormat.format(newValue);
              });
            } on FormatException catch (error) {
              _logger.fine('Error parsing reps during quick-add: $error');
            }
          },
        ),
      ],
    );
  }
}

class LogsWeightWidget extends ConsumerWidget {
  final TextEditingController controller;
  final SetConfigData configData;
  final FocusNode focusNode;
  final Log log;
  final void Function(VoidCallback fn) setStateCallback;

  final _logger = Logger('LogsWeightWidget');

  LogsWeightWidget({
    super.key,
    required this.controller,
    required this.configData,
    required this.focusNode,
    required this.log,
    required this.setStateCallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightValueChange = configData.weightRounding ?? 1.25;
    final numberFormat = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final i18n = AppLocalizations.of(context);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.black),
          onPressed: () {
            try {
              final newValue = numberFormat.parse(controller.text) - weightValueChange;
              if (newValue > 0) {
                setStateCallback(() {
                  log.weight = newValue;
                  controller.text = numberFormat.format(newValue);
                  ref
                      .read(plateCalculatorProvider.notifier)
                      .setWeight(
                        controller.text == '' ? 0 : newValue,
                      );
                });
              }
            } on FormatException catch (error) {
              _logger.fine('Error parsing weight during quick-remove: $error');
            }
          },
        ),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(labelText: i18n.weight),
            controller: controller,
            keyboardType: textInputTypeDecimal,
            onChanged: (value) {
              try {
                final newValue = numberFormat.parse(value);
                setStateCallback(() {
                  log.weight = newValue;
                  ref
                      .read(plateCalculatorProvider.notifier)
                      .setWeight(
                        controller.text == '' ? 0 : numberFormat.parse(controller.text),
                      );
                });
              } on FormatException catch (error) {
                _logger.fine('Error parsing weight: $error');
              }
            },
            onSaved: (newValue) {
              setStateCallback(() {
                log.weight = numberFormat.parse(newValue!);
              });
            },
            validator: (value) {
              if (numberFormat.tryParse(value ?? '') == null) {
                return i18n.enterValidNumber;
              }
              return null;
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: () {
            final value = controller.text.isNotEmpty ? controller.text : '0';

            try {
              final newValue = numberFormat.parse(value) + weightValueChange;
              setStateCallback(() {
                log.weight = newValue;
                controller.text = numberFormat.format(newValue);
                ref
                    .read(plateCalculatorProvider.notifier)
                    .setWeight(
                      controller.text == '' ? 0 : newValue,
                    );
              });
            } on FormatException catch (error) {
              _logger.fine('Error parsing weight during quick-add: $error');
            }
          },
        ),
      ],
    );
  }
}

class LogsPastLogsWidget extends StatelessWidget {
  final Log log;
  final List<Log> pastLogs;
  final void Function(Log pastLog) onCopy;
  final void Function(VoidCallback fn) setStateCallback;

  const LogsPastLogsWidget({
    super.key,
    required this.log,
    required this.pastLogs,
    required this.onCopy,
    required this.setStateCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        children: [
          Text(
            AppLocalizations.of(context).labelWorkoutLogs,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          ...pastLogs.map((pastLog) {
            return ListTile(
              key: ValueKey('past-log-${pastLog.id}'),
              title: Text(pastLog.repTextNoNl(context)),
              subtitle: Text(
                DateFormat.yMd(Localizations.localeOf(context).languageCode).format(pastLog.date),
              ),
              trailing: const Icon(Icons.copy),
              onTap: () {
                setStateCallback(() {
                  log.rir = pastLog.rir;
                  log.repetitionUnit = pastLog.repetitionsUnitObj;
                  log.weightUnit = pastLog.weightUnitObj;

                  onCopy(pastLog);

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).dataCopied),
                    ),
                  );
                });
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 40),
            );
          }),
        ],
      ),
    );
  }
}

class LogFormWidget extends ConsumerStatefulWidget {
  final _logger = Logger('LogFormWidget');

  final PageController controller;
  final SetConfigData configData;
  final Log log;
  final FocusNode focusNode;

  LogFormWidget({
    super.key,
    required this.controller,
    required this.configData,
    required this.log,
    required this.focusNode,
  });

  @override
  _LogFormWidgetState createState() => _LogFormWidgetState();
}

class _LogFormWidgetState extends ConsumerState<LogFormWidget> {
  final _form = GlobalKey<FormState>();
  var _detailed = false;
  bool _isSaving = false;
  late Log _log;

  late final TextEditingController _repetitionsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();

    _log = widget.log;
    _repetitionsController = TextEditingController();
    _weightController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locale = Localizations.localeOf(context).toString();
      final numberFormat = NumberFormat.decimalPattern(locale);

      if (widget.configData.repetitions != null) {
        _repetitionsController.text = numberFormat.format(widget.configData.repetitions);
      }

      if (widget.configData.weight != null) {
        _weightController.text = numberFormat.format(widget.configData.weight);
      }
    });
  }

  @override
  void dispose() {
    _repetitionsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void copyFromPastLog(Log pastLog) {
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);

    setState(() {
      _repetitionsController.text = pastLog.repetitions != null
          ? numberFormat.format(pastLog.repetitions)
          : '';
      widget._logger.finer('Setting log repetitions to ${_repetitionsController.text}');

      _weightController.text = pastLog.weight != null ? numberFormat.format(pastLog.weight) : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Form(
      key: _form,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            i18n.newEntry,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (!_detailed)
            Row(
              children: [
                Flexible(
                  child: LogsRepsWidget(
                    controller: _repetitionsController,
                    configData: widget.configData,
                    focusNode: widget.focusNode,
                    log: _log,
                    setStateCallback: (fn) {
                      setState(fn);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: LogsWeightWidget(
                    controller: _weightController,
                    configData: widget.configData,
                    focusNode: widget.focusNode,
                    log: _log,
                    setStateCallback: (fn) {
                      setState(fn);
                    },
                  ),
                ),
              ],
            ),
          if (_detailed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: LogsRepsWidget(
                    controller: _repetitionsController,
                    configData: widget.configData,
                    focusNode: widget.focusNode,
                    log: _log,
                    setStateCallback: (fn) {
                      setState(fn);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: RepetitionUnitInputWidget(
                    _log.repetitionsUnitId,
                    onChanged: (v) => {},
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          if (_detailed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: LogsWeightWidget(
                    controller: _weightController,
                    configData: widget.configData,
                    focusNode: widget.focusNode,
                    log: _log,
                    setStateCallback: (fn) {
                      setState(fn);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: WeightUnitInputWidget(_log.weightUnitId, onChanged: (v) => {}),
                ),
                const SizedBox(width: 8),
              ],
            ),
          if (_detailed)
            RiRInputWidget(
              _log.rir,
              onChanged: (value) {
                if (value == '') {
                  _log.rir = null;
                } else {
                  _log.rir = num.parse(value);
                }
              },
            ),
          SwitchListTile(
            dense: true,
            title: Text(i18n.setUnitsAndRir),
            value: _detailed,
            onChanged: (value) {
              setState(() {
                _detailed = !_detailed;
              });
            },
          ),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () async {
                    final isValid = _form.currentState!.validate();
                    if (!isValid) {
                      return;
                    }
                    _isSaving = true;
                    _form.currentState!.save();

                    try {
                      final gymState = ref.read(gymStateProvider);
                      final gymProvider = ref.read(gymStateProvider.notifier);

                      await provider.Provider.of<RoutinesProvider>(
                        context,
                        listen: false,
                      ).addLog(_log);
                      final page = gymState.getSlotEntryPageByIndex()!;
                      gymProvider.markSlotPageAsDone(page.uuid, isDone: true);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            content: Text(
                              i18n.successfullySaved,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      widget.controller.nextPage(
                        duration: DEFAULT_ANIMATION_DURATION,
                        curve: DEFAULT_ANIMATION_CURVE,
                      );
                      setState(() {
                        _isSaving = false;
                      });
                    } on WgerHttpException {
                      setState(() {
                        _isSaving = false;
                      });
                      rethrow;
                    } finally {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  },
            child: _isSaving ? const FormProgressIndicator() : Text(i18n.save),
          ),
        ],
      ),
    );
  }
}
