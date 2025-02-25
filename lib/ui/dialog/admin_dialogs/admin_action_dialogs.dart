import 'package:flutter/material.dart';
import 'package:navsu/ui/dialog/admin_dialogs/confirmation_dialog.dart';

class AdminActionDialogs {
  static Future<bool> showLandmarkStatusConfirmation(
    BuildContext context,
    String status,
    String landmarkName,
  ) {
    final colors = {
      'approved': Colors.green,
      'rejected': Colors.red,
      'delete': Colors.grey,
    };

    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: '${status.capitalize} Landmark',
        message: 'Are you sure you want to ${status.toLowerCase()} "$landmarkName"?',
        confirmText: status.capitalize,
        confirmColor: colors[status],
        onConfirm: () => Navigator.pop(context, true),
      ),
    ).then((value) => value ?? false);
  }

  static Future<bool> showUserRoleConfirmation(
    BuildContext context,
    String newRole,
    String userName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Change User Role',
        message: 'Change role for "$userName" to ${newRole.toUpperCase()}?',
        confirmText: 'Change Role',
        confirmColor: Colors.green,
        onConfirm: () => Navigator.pop(context, true),
      ),
    ).then((value) => value ?? false);
  }

  static Future<bool> showDeleteRewardConfirmation(
    BuildContext context,
    String rewardName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Reward',
        message: 'Are you sure you want to delete "$rewardName"?\nThis action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () => Navigator.pop(context, true),
      ),
    ).then((value) => value ?? false);
  }
}

extension StringExtension on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
}
