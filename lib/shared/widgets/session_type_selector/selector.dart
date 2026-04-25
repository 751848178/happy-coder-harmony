part of 'session_type_selector.dart';

extension _SessionTypeSelectorLayouts on SessionTypeSelector {
  Widget _buildListSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: BuiltInSessionTypes.all.map((info) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SessionTypeListTile(
            info: info,
            isSelected: info.type == selectedType,
            onTap: () => onTypeChanged(info.type),
            showDescription: showDescription,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSelector() {
    return SegmentedButton<SessionType>(
      segments: BuiltInSessionTypes.all.map((info) {
        return ButtonSegment(
          value: info.type,
          label: Text(info.label),
          icon: Icon(info.icon, size: 18),
        );
      }).toList(),
      selected: {selectedType},
      onSelectionChanged: (newSelection) => onTypeChanged(newSelection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color?>(AppTheme.neutral100),
        foregroundColor: WidgetStateProperty.all<Color?>(AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildGridSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: BuiltInSessionTypes.all.length,
      itemBuilder: (context, index) {
        final info = BuiltInSessionTypes.all[index];
        return _SessionTypeGridCard(
          info: info,
          isSelected: info.type == selectedType,
          onTap: () => onTypeChanged(info.type),
        );
      },
    );
  }
}
