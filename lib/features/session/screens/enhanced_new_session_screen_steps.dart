part of 'enhanced_new_session_screen.dart';

Widget _buildEnhancedNewSessionScreen(_EnhancedNewSessionScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('新建会话'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => state.context.pop(),
      ),
    ),
    body: Column(
      children: [
        _buildEnhancedSteps(state),
        Expanded(
          child: IndexedStack(
            index: state._currentStep,
            children: [
              _buildEnhancedStep1Content(state),
              _buildEnhancedStep2Content(state),
              _buildEnhancedStep3Content(state),
            ],
          ),
        ),
        _buildEnhancedBottomActions(state),
      ],
    ),
  );
}

Widget _buildEnhancedSteps(_EnhancedNewSessionScreenState state) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    color: AppTheme.surface,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isCompleted = index < state._currentStep;
        final isCurrent = index == state._currentStep;
        return Row(
          children: [
            if (index > 0)
              Container(
                width: 40,
                height: 2,
                color: isCompleted ? AppTheme.brandColor : AppTheme.neutral300,
              ),
            _StepIndicator(
              step: index + 1,
              isActive: isCurrent,
              isCompleted: isCompleted,
            ),
          ],
        );
      }),
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.isActive,
    required this.isCompleted,
  });

  final int step;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isCompleted || isActive ? AppTheme.brandColor : AppTheme.neutral300,
        border: Border.all(color: AppTheme.brandColor, width: 2),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.brandColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _StepDescription extends StatelessWidget {
  const _StepDescription(this.description);

  final String description;

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

InputDecoration _enhancedInputDecoration({
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: AppTheme.neutral500),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.neutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.brandColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
