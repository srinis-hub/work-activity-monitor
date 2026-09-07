import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/models/work_session.dart';

class WorkSessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveWorkSession(WorkSession workSession) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final uid = user.uid;
    final userRef = _firestore.collection('users').doc(uid);

    final workDayRef = userRef.collection('workDays').doc(workSession.workDate);

    final sessionRef = workDayRef
        .collection('sessions')
        .doc(workSession.sessionId);

    final now = FieldValue.serverTimestamp();

    await userRef.set({
      'email': user.email,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await workDayRef.set({
      'workDate': workSession.workDate,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await sessionRef.set({
      ...workSession.toMap(),
      'userId': uid,
      'createdAt': now,
    });

    await workDayRef.set({
      'sessionCount': FieldValue.increment(1),
      'totalDurationSeconds': FieldValue.increment(
        workSession.totalDurationSeconds,
      ),
      'updatedAt': now,
    }, SetOptions(merge: true));
  }
}
