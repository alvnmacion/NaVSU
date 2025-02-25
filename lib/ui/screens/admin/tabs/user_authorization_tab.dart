import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui';
import 'package:navsu/ui/dialog/admin_dialogs/admin_action_dialogs.dart';

class UserAuthorizationTab extends StatefulWidget {
  const UserAuthorizationTab({super.key});

  @override
  State<UserAuthorizationTab> createState() => _UserAuthorizationTabState();
}

// ... Copy the entire _UserAuthorizationTabState class here ...
class _UserAuthorizationTabState extends State<UserAuthorizationTab> {
  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final width = constraints.maxWidth;
            
            // Responsive sizing
            final double cardPadding = width < 360 ? 8 : (width < 600 ? 12 : 16);
            final double avatarSize = width < 360 ? 40 : (width < 600 ? 50 : 60);
            final double fontSize = width < 360 ? 12 : (width < 600 ? 14 : 16);
            
            return Padding(
              padding: EdgeInsets.all(cardPadding),
              child: isLandscape
                  ? _buildGrid(snapshot.data!.docs, cardPadding, avatarSize, fontSize)
                  : _buildList(snapshot.data!.docs, cardPadding, avatarSize, fontSize),
            );
          },
        );
      },
    );
  }

  Widget _buildGrid(List<QueryDocumentSnapshot> users, double padding, double avatarSize, double fontSize) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(
        users[index],
        padding,
        avatarSize,
        fontSize,
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> users, double padding, double avatarSize, double fontSize) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: padding),
        child: _buildUserCard(
          users[index],
          padding,
          avatarSize,
          fontSize,
        ),
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot userDoc, double padding, double avatarSize, double fontSize) {
    final user = userDoc.data() as Map<String, dynamic>;
    final isAdmin = (user['role'] ?? 'user') == 'admin';
    final points = _formatNumber(user['points']);

    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  _buildAvatar(user, avatarSize),
                  SizedBox(width: padding),
                  Expanded(
                    child: _buildInfo(user, points, fontSize),
                  ),
                  _buildRoleButton(context, userDoc, isAdmin, fontSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user, double size) {
    return Hero(
      tag: 'user-avatar-${user['email']}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
          child: user['photoUrl'] == null
              ? Icon(Icons.person, size: size * 0.6, color: Colors.grey)
              : null,
        ),
      ),
    );
  }

  Widget _buildInfo(Map<String, dynamic> user, String points, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AutoSizeText(
          user['name'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 2,
          ),
          maxLines: 1,
          minFontSize: 12,
        ),
        const SizedBox(height: 4),
        AutoSizeText(
          user['email'] ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: fontSize - 2,
          ),
          maxLines: 1,
          minFontSize: 10,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars_rounded, size: fontSize, color: Colors.amber),
            const SizedBox(width: 4),
            AutoSizeText(
              '$points points',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: fontSize - 2,
              ),
              maxLines: 1,
              minFontSize: 10,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButton(BuildContext context, DocumentSnapshot userDoc, bool isAdmin, double fontSize) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showRoleMenu(context, userDoc, isAdmin),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAdmin ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isAdmin ? Colors.green : Colors.grey),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (userDoc['role'] ?? 'user').toString(),
                style: TextStyle(
                  color: isAdmin ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: isAdmin ? Colors.green : Colors.grey,
                size: fontSize + 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoleMenu(BuildContext context, DocumentSnapshot userDoc, bool isAdmin) async {
    final String? selectedRole = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Change User Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const Divider(),
            for (String role in ['user', 'admin'])
              ListTile(
                leading: Icon(
                  role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                  color: role == 'admin' ? Colors.green : Colors.grey[700],
                ),
                title: Text(
                  role,
                  style: TextStyle(
                    color: role == 'admin' ? Colors.green : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => Navigator.pop(context, role),
                tileColor: userDoc['role'] == role 
                    ? (role == 'admin' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1))
                    : null,
              ),
          ],
        ),
      ),
    );

    if (selectedRole != null && mounted && selectedRole != userDoc['role']) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Role Change'),
          content: Text(
            'Change role for "${userDoc['name'] ?? 'Unknown User'}" to ${selectedRole.toUpperCase()}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await userDoc.reference.update({'role': selectedRole});
      }
    }
  }
}
