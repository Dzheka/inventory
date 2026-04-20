import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final List<String> _digits = [];
  bool _error = false;

  void _addDigit(String d) {
    if (_digits.length >= AppConfig.pinLength) return;
    setState(() {
      _digits.add(d);
      _error = false;
    });
    if (_digits.length == AppConfig.pinLength) {
      _checkPin();
    }
  }

  void _removeDigit() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  Future<void> _checkPin() async {
    final pin = _digits.join();
    // TODO: validate against stored PIN hash in secure storage
    // For now route back to login
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _error = true;
      _digits.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход по PIN'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Введите PIN-код',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(AppConfig.pinLength, (i) {
              final filled = i < _digits.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _error
                      ? Colors.red
                      : filled
                          ? Colors.blue
                          : Colors.grey.shade300,
                  border: Border.all(color: Colors.blue.shade300),
                ),
              );
            }),
          ),
          if (_error)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Неверный PIN', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 48),

          // Numpad
          _NumPad(onDigit: _addDigit, onDelete: _removeDigit),
        ],
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 72);
              if (k == 'del') {
                return SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton(
                    icon: const Icon(Icons.backspace_outlined, size: 28),
                    onPressed: onDelete,
                  ),
                );
              }
              return SizedBox(
                width: 72,
                height: 72,
                child: TextButton(
                  onPressed: () => onDigit(k),
                  style: TextButton.styleFrom(
                    shape: const CircleBorder(),
                  ),
                  child: Text(k,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
