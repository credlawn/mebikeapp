import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppButtons {
  static Widget primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    double height = 50, // More compact
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0, // Flat design for professional look
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
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
    double height = 50,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
