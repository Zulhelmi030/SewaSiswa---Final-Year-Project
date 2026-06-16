import 'package:flutter/material.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool useGradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        gradient: (isOutlined || !useGradient)
            ? null
            : context.appColors.primaryGradient,
        color: isOutlined ? Colors.transparent : (!useGradient ? context.appColors.primary : null),
        border: isOutlined
            ? Border.all(color: context.appColors.primary.withValues(alpha: 0.15), width: 1.5)
            : null,
        boxShadow: isOutlined
            ? []
            : [
                BoxShadow(
                  color: context.appColors.primary.withValues(alpha: 0.04),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(9999),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isOutlined ? context.appColors.primary : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
