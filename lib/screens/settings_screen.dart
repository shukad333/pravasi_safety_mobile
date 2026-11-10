import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_key_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _hasKey = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    context.read<ApiKeyStore>().read().then((k) {
      if (!mounted) return;
      setState(() {
        _hasKey = k != null && k.isNotEmpty;
        _controller.text = k ?? '';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<ApiKeyStore>();
    final value = _controller.text.trim();
    if (value.isEmpty) {
      await store.clear();
    } else {
      await store.write(value);
    }
    if (!mounted) return;
    setState(() => _hasKey = value.isNotEmpty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value.isEmpty ? 'API key removed' : 'API key saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Anthropic API key',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Used to look up customs guidance for new destinations. '
            'Results are cached on this device, so each country is only '
            'fetched once. The key is stored in the secure keychain.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'sk-ant-…',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(_hasKey ? Icons.check_circle : Icons.info_outline,
                  size: 18, color: _hasKey ? Colors.green : null),
              const SizedBox(width: 6),
              Text(_hasKey ? 'Key configured' : 'No key set'),
              const Spacer(),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
