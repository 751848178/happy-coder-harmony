part of 'display_settings.dart';

class DisplaySettings {
  const DisplaySettings({
    this.compactView = false,
    this.inlineToolCalls = true,
    this.expandTodoList = true,
    this.showLineNumbers = true,
    this.autoWrap = false,
    this.alwaysShowContextSize = false,
    this.avatarStyle = 'gradient',
    this.showFlavorIcon = true,
  });

  final bool compactView;
  final bool inlineToolCalls;
  final bool expandTodoList;
  final bool showLineNumbers;
  final bool autoWrap;
  final bool alwaysShowContextSize;
  final String avatarStyle;
  final bool showFlavorIcon;

  Map<String, dynamic> toJson() {
    return {
      'compactView': compactView,
      'inlineToolCalls': inlineToolCalls,
      'expandTodoList': expandTodoList,
      'showLineNumbers': showLineNumbers,
      'autoWrap': autoWrap,
      'alwaysShowContextSize': alwaysShowContextSize,
      'avatarStyle': avatarStyle,
      'showFlavorIcon': showFlavorIcon,
    };
  }

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    return DisplaySettings(
      compactView: json['compactView'] ?? false,
      inlineToolCalls: json['inlineToolCalls'] ?? true,
      expandTodoList: json['expandTodoList'] ?? true,
      showLineNumbers: json['showLineNumbers'] ?? true,
      autoWrap: json['autoWrap'] ?? false,
      alwaysShowContextSize: json['alwaysShowContextSize'] ?? false,
      avatarStyle: json['avatarStyle'] ?? 'gradient',
      showFlavorIcon: json['showFlavorIcon'] ?? true,
    );
  }

  DisplaySettings copyWith({
    bool? compactView,
    bool? inlineToolCalls,
    bool? expandTodoList,
    bool? showLineNumbers,
    bool? autoWrap,
    bool? alwaysShowContextSize,
    String? avatarStyle,
    bool? showFlavorIcon,
  }) {
    return DisplaySettings(
      compactView: compactView ?? this.compactView,
      inlineToolCalls: inlineToolCalls ?? this.inlineToolCalls,
      expandTodoList: expandTodoList ?? this.expandTodoList,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      autoWrap: autoWrap ?? this.autoWrap,
      alwaysShowContextSize:
          alwaysShowContextSize ?? this.alwaysShowContextSize,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      showFlavorIcon: showFlavorIcon ?? this.showFlavorIcon,
    );
  }
}
