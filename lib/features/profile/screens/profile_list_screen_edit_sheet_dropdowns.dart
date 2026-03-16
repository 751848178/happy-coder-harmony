part of 'profile_list_screen.dart';

Widget _buildProfilePermissionField(_ProfileEditSheetState state) {
  return _buildProfileDropdownField<PermissionMode>(
    label: '权限模式',
    value: state._permissionMode,
    items: PermissionMode.values
        .map((mode) =>
            DropdownMenuItem(value: mode, child: Text(mode.displayName)))
        .toList(),
    onChanged: (value) {
      state._updateView(() {
        state._permissionMode = value;
      });
    },
  );
}

Widget _buildProfileSessionTypeField(_ProfileEditSheetState state) {
  return _buildProfileDropdownField<SessionType>(
    label: '会话类型',
    value: state._sessionType,
    items: SessionType.values
        .map((type) =>
            DropdownMenuItem(value: type, child: Text(type.displayName)))
        .toList(),
    onChanged: (value) {
      state._updateView(() {
        state._sessionType = value;
      });
    },
  );
}

Widget _buildProfileDropdownField<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}
