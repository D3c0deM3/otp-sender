import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

const smsChannel = MethodChannel('com.example.otp_sender/sms');

// Background handler for FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Initialize MethodChannel
  await smsChannel
      .invokeMethod('sendSms', {'phoneNumber': '', 'message': ''})
      .catchError((e) => null);

  String phoneNumber = message.data['phone_number'];
  String otp = message.data['otp'];
  await sendSms(phoneNumber, otp, isBackground: true);
}

Future<void> sendSms(
  String phoneNumber,
  String otp, {
  bool isBackground = false,
}) async {
  // Normalize phone number: remove spaces, dashes, parentheses
  String normalizedPhoneNumber = phoneNumber.replaceAll(
    RegExp(r'[\s\-\(\)]'),
    '',
  );
  // Ensure it starts with +
  if (!normalizedPhoneNumber.startsWith('+')) {
    normalizedPhoneNumber = '+$normalizedPhoneNumber';
  }
  print("Normalized phone number: $normalizedPhoneNumber");

  bool hasPermission =
      isBackground
          ? await Permission.sms.status.isGranted
          : await Permission.sms.request().isGranted;

  if (hasPermission) {
    try {
      final message = "Your OTP is $otp";
      final bool success = await smsChannel.invokeMethod('sendSms', {
        'phoneNumber': normalizedPhoneNumber,
        'message': message,
      });
      print("SMS sent to $normalizedPhoneNumber: $success");
    } catch (e) {
      print("SMS failed: $e");
    }
  } else {
    print("SMS permission denied${isBackground ? ' in background' : ''}");
    if (!isBackground && await Permission.sms.isPermanentlyDenied) {
      print("Prompting user to enable SMS permission in settings");
      await openAppSettings();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request permission on app start
  if (await Permission.sms.status.isDenied) {
    await Permission.sms.request();
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Get and print FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  print("Your FCM token: $token");

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    String phoneNumber = message.data['phone_number'];
    String otp = message.data['otp'];
    sendSms(phoneNumber, otp, isBackground: false);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("OTP Sender")),
        body: Center(
          child: FutureBuilder<bool>(
            future: Permission.sms.status.isGranted,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasData && !snapshot.data!) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("SMS permission required for OTP sending"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (await Permission.sms.request().isGranted) {
                          print("Permission granted");
                        } else if (await Permission.sms.isPermanentlyDenied) {
                          await openAppSettings();
                        }
                      },
                      child: const Text("Grant Permission"),
                    ),
                  ],
                );
              }
              return const Text("Running in background...");
            },
          ),
        ),
      ),
    );
  }
}
