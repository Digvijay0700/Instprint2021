import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMembersPage extends StatelessWidget {
  final String groupId;
  const GroupMembersPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Members')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          Map<String, dynamic> members = Map<String, dynamic>.from(data['members'] ?? {});

          return ListView(
            padding: const EdgeInsets.all(16),
            children: members.entries.map((e) {
              return ListTile(
                title: Text(e.value['name'] ?? 'No Name'),
                subtitle: Text('UID: ${e.key}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
