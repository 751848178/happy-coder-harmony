import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

part 'display_settings_editor_options.dart';
part 'display_settings_model.dart';
part 'display_settings_session_options.dart';
part 'display_settings_support.dart';
part 'display_settings_ui_options.dart';

final compactViewProvider = StateProvider<bool>((ref) => false);
final inlineToolCallsProvider = StateProvider<bool>((ref) => true);
final expandTodoListProvider = StateProvider<bool>((ref) => true);
final showLineNumbersProvider = StateProvider<bool>((ref) => true);
final autoWrapProvider = StateProvider<bool>((ref) => false);
final alwaysShowContextSizeProvider = StateProvider<bool>((ref) => false);
final avatarStyleOptionProvider = StateProvider<String>((ref) => 'gradient');
final showFlavorIconProvider = StateProvider<bool>((ref) => true);

class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('显示设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DisplaySectionHeader('会话视图'),
          SizedBox(height: 8),
          _CompactViewOption(),
          SizedBox(height: 8),
          _InlineToolCallsOption(),
          SizedBox(height: 8),
          _ExpandTodoListOption(),
          SizedBox(height: 24),
          _DisplaySectionHeader('代码编辑'),
          SizedBox(height: 8),
          _ShowLineNumbersOption(),
          SizedBox(height: 8),
          _AutoWrapOption(),
          SizedBox(height: 8),
          _AlwaysShowContextSizeOption(),
          SizedBox(height: 24),
          _DisplaySectionHeader('用户界面'),
          SizedBox(height: 8),
          _AvatarStyleOption(),
          SizedBox(height: 8),
          _ShowFlavorIconOption(),
        ],
      ),
    );
  }
}
