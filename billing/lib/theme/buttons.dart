import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppButtons {
  static Widget primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    double height = 56,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                text,
                style: AppTypography.button.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  static Widget outline({
    required String text,
    required VoidCallback onPressed,
    double? width,
    double height = 56,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: AppTypography.button.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
