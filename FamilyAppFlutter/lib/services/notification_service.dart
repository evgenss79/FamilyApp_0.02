import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../providers/family_data.dart';
import '../models/family_member.dart';

class NotificationService {
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  static BuildContext? _attachedContext;

  static Future<void> init({GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey}) async {
    _scaffoldMessengerKey = scaffoldMessengerKey;
    // Additional initialization can be placed here.
  }

  static void attachContext(BuildContext context) {
    _attachedContext = context;
  }
}
