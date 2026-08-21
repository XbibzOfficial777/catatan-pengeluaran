import 'package:flutter/material.dart';

import '../core/format.dart';

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expression = '';
  String _result = '0';

  void _tap(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty)
          _expression = _expression.substring(0, _expression.length - 1);
      } else if (value == '=') {
        final calculated = calculateExpression(_expression);
        if (calculated != null) _result = formatNumber(calculated);
      } else {
        _expression += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const keys = [
      'C',
      '⌫',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '−',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '00',
      '0',
      '.',
      '',
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kalkulator cepat',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _expression.isEmpty ? 'Masukkan angka' : _expression,
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.55),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _result,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: keys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final label = keys[index];
                    if (label.isEmpty) return const SizedBox.shrink();
                    final isAction = [
                      'C',
                      '⌫',
                      '÷',
                      '×',
                      '−',
                      '+',
                      '=',
                    ].contains(label);
                    return FilledButton(
                      onPressed: () => _tap(label),
                      style: FilledButton.styleFrom(
                        backgroundColor: label == '='
                            ? colors.primary
                            : isAction
                            ? colors.primary.withValues(alpha: 0.13)
                            : colors.surfaceContainerHighest,
                        foregroundColor: label == '='
                            ? Colors.white
                            : colors.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: label == '⌫' ? 18 : 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double? calculateExpression(String expression) {
  if (expression.isEmpty) return null;
  final tokens = RegExp(r'\d+(?:\.\d+)?|[+\-×÷]')
      .allMatches(expression)
      .map((match) => match.group(0)!)
      .toList();
  if (tokens.isEmpty ||
      tokens.first.length == 1 && '+−×÷'.contains(tokens.first))
    return null;
  try {
    final values = <double>[double.parse(tokens.first)];
    final lowOperators = <String>[];
    for (var index = 1; index < tokens.length - 1; index += 2) {
      final operator = tokens[index];
      final number = double.parse(tokens[index + 1]);
      if (operator == '×' || operator == '÷') {
        if (operator == '÷' && number == 0) return null;
        values[values.length - 1] = operator == '×'
            ? values.last * number
            : values.last / number;
      } else {
        values.add(number);
        lowOperators.add(operator);
      }
    }
    var result = values.first;
    for (var index = 0; index < lowOperators.length; index++) {
      result = lowOperators[index] == '+'
          ? result + values[index + 1]
          : result - values[index + 1];
    }
    return result.isFinite ? result : null;
  } catch (_) {
    return null;
  }
}
