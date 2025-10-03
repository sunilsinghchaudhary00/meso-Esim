import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../views/navbarModule/bloc/navbar_bloc.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

final localNotifications = FlutterLocalNotificationsPlugin();

Future<void> setupLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final initializationSettings = InitializationSettings(
    android: android,
    iOS: ios,
  );

  await localNotifications.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      if (details.payload != null) {
        _onSelectNotification(details.payload!);
      }
    },
  );
}

// Move this outside the class for proper initialization callback
void _onSelectNotification(String payload) {
  try {
    final messageData = json.decode(payload);
    if (messageData['type'] == '3') {
      Get.find<BottomNavController>().navigateToTab(2);
    } else if (messageData['type'] == '9') {
      Get.find<BottomNavController>().navigateToTab(3);
    }
  } catch (e) {
    log('Error processing notification payload: $e');
  }
}

class NotificationUtils {
  Future<void> showCustomSoundNotification(RemoteMessage payload) async {
    log('Custom sound notification called');

    const androidDetails = AndroidNotificationDetails(
      'channel_id_17',
      'Channel Name',
      importance: Importance.max,
      priority: Priority.high,
      icon: "@mipmap/ic_launcher",
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('app_sound'),
    );

    const iOSDetails = DarwinNotificationDetails(sound: 'app_sound.wav');

    final platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      payload.notification?.title,
      payload.notification?.body,
      platformChannelSpecifics,
      payload: json.encode(payload.data),
    );
  }

  Future<void> showNotification(RemoteMessage payload) async {
    log('--- Notification Received ---');
    log("Data: ${payload.data}");
    log("Title: ${payload.notification?.title}");
    log("Body: ${payload.notification?.body}");
    log('-----------------------------');

    try {
      // Get image URL from your backend's data field
      String? imageUrl;
      if (Platform.isAndroid) {
        imageUrl =
            payload.data['image'] ?? payload.notification?.android?.imageUrl;
      } else if (Platform.isIOS) {
        imageUrl =
            payload.data['image'] ?? payload.notification?.apple?.imageUrl;
      } else {
        imageUrl = payload.data['image'];
      }
     log('image is $imageUrl');
      // Create notification details
      final notificationDetails = await _createNotificationDetails(
        payload.notification?.title,
        payload.notification?.body,
        imageUrl,
      );

      await localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        payload.notification?.title ?? "New Notification",
        payload.notification?.body ?? "",
        notificationDetails,
        payload: json.encode(payload.data),
      );

      log('Notification shown successfully');
    } catch (e) {
      log('Error showing notification: $e');
    }
  }

  Future<NotificationDetails> _createNotificationDetails(
    String? title,
    String? body,
    String? imageUrl,
  ) async {
    // Android configuration
    final AndroidNotificationDetails androidDetails;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imagePath = await _downloadAndSaveFile(imageUrl, 'notif_img');
      if (imagePath.isNotEmpty) {
        final bigPicture = BigPictureStyleInformation(
          FilePathAndroidBitmap(imagePath),
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: body,
          htmlFormatSummaryText: true,
        );

        androidDetails = AndroidNotificationDetails(
          'channel_id_image',
          'Image Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: "@mipmap/ic_launcher",
          styleInformation: bigPicture,
          playSound: true,
          enableVibration: true,
        );
      } else {
        androidDetails = _createBasicAndroidDetails();
      }
    } else {
      androidDetails = _createBasicAndroidDetails();
    }

    // iOS configuration
    DarwinNotificationDetails? iOSDetails;
    if (Platform.isIOS && imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final imagePath = await _downloadAndSaveFile(imageUrl, 'ios_notif_img');
        if (imagePath.isNotEmpty) {
          iOSDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments: [
              DarwinNotificationAttachment(
                imagePath,
                identifier: 'image',
                hideThumbnail: false,
              ),
            ],
          );
        } else {
          iOSDetails = _createBasicIOSDetails();
        }
      } catch (e) {
        log('Error downloading image for iOS: $e');
        // iOSDetails = _createBasicIOSDetails();
      }
    } else {
      iOSDetails = _createBasicIOSDetails();
    }

    return NotificationDetails(android: androidDetails, iOS: iOSDetails);
  }

  AndroidNotificationDetails _createBasicAndroidDetails() {
    return const AndroidNotificationDetails(
      'channel_id_basic',
      'Basic Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: "@mipmap/ic_launcher",
      playSound: true,
      enableVibration: true,
    );
  }

  DarwinNotificationDetails _createBasicIOSDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();

    // Extract extension from URL
    String extension = url.split('.').last;
    if (extension.contains('?')) {
      extension = extension.split('?').first; // remove query params if any
    }

    final filePath = '${directory.path}/$fileName.$extension';

    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final file = File(filePath);
    await file.writeAsBytes(response.data!);
    return filePath;
  } catch (e) {
    log('Error downloading file: $e');
    return "";
  }
}


  Future<void> checkNotificationPermissions() async {
    if (Platform.isIOS) {
      final NotificationSettings firebaseSettings = await FirebaseMessaging
          .instance
          .getNotificationSettings();

      log(
        'Firebase Permission Status: ${firebaseSettings.authorizationStatus}',
      );
    }
  }

  Future<void> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final NotificationSettings firebaseSettings = await FirebaseMessaging
          .instance
          .requestPermission(alert: true, badge: true, sound: true);

      log(
        'Firebase permission result: ${firebaseSettings.authorizationStatus}',
      );
    }
  }

  void printPayload(RemoteMessage message) {
    log('--- FCM Payload ---');
    log("Data: ${json.encode(message.data)}");

    if (message.notification != null) {
      log("Title: ${message.notification!.title}");
      log("Body: ${message.notification!.body}");
    }

    log('-------------------');
  }
}
