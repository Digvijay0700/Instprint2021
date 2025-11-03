import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:math';

class GroupFeaturePage extends StatefulWidget {
  const GroupFeaturePage({super.key});

  @override
  State<GroupFeaturePage> createState() => _GroupFeaturePageState();
}

class _GroupFeaturePageState extends State<GroupFeaturePage> {
  final _groupNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  int _memberCount = 2;

  String _generatedGroupCode = '';
  List<String> _joinedUsers = [];

  Future<void> _createGroup(String uid) async {
    final groupCode = _generateGroupCode();

    await FirebaseFirestore.instance.collection('groups').doc(groupCode).set({
      'groupName': _groupNameController.text.trim(),
      'leader': uid,
      'members': [uid],
      'maxMembers': _memberCount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _generatedGroupCode = groupCode;
    });
  }

  Future<void> _joinGroup(String uid) async {
    final code = _joinCodeController.text.trim();

    final doc = await FirebaseFirestore.instance.collection('groups').doc(code).get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Group not found!')));
      return;
    }

    final data = doc.data()!;
    List members = data['members'];
    int maxMembers = data['maxMembers'];

    if (members.contains(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already in group!')));
      return;
    }

    if (members.length >= maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Group is full!')));
      return;
    }

    members.add(uid);
    await FirebaseFirestore.instance.collection('groups').doc(code).update({'members': members});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined successfully!')));
  }

  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context, listen: false).uid ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: Text('Create or Join Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👥 Create Group", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _memberCount,
              decoration: InputDecoration(labelText: 'Select number of members'),
              items: [2, 3, 4]
                  .map((num) => DropdownMenuItem(value: num, child: Text('$num')))
                  .toList(),
              onChanged: (val) => setState(() => _memberCount = val!),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _createGroup(uid),
              child: Text('Create Group'),
            ),
            if (_generatedGroupCode.isNotEmpty)
              Column(
                children: [
                  SizedBox(height: 12),
                  Text('Group Created! Share this code:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(_generatedGroupCode, style: TextStyle(fontSize: 20, color: Colors.blue)),
                ],
              ),
            Divider(height: 40),
            Text("➕ Join Group", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _joinCodeController,
              decoration: InputDecoration(labelText: 'Enter Group Code'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _joinGroup(uid),
              child: Text('Join Group'),
            ),
          ],
        ),
      ),
    );
  }
}
