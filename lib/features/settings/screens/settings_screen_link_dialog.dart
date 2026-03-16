part of 'settings_screen.dart';

class _TerminalLinkInputDialog extends StatefulWidget {
  const _TerminalLinkInputDialog();

  @override
  State<_TerminalLinkInputDialog> createState() =>
      _TerminalLinkInputDialogState();
}

class _TerminalLinkInputDialogState extends State<_TerminalLinkInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = '请输入终端链接';
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(trimmed);
  }

  void _cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入终端链接'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_errorText == null) {
            return;
          }
          setState(() {
            _errorText = null;
          });
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'happy://terminal?BASE64URL_PUBLIC_KEY',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('连接')),
      ],
    );
  }
}
