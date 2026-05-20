import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:overlay/constant.dart';

import 'package:overlay/over_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
 // Uint8List? imageBytes;
  // Convert the overlayListener to a broadcast stream once.
  sendContextToNative();


  runApp(MyApp());
}

/// Sends the context to the native side.
void sendContextToNative() async {
  const MethodChannel channel = MethodChannel('com.example.overlay/main');
  try {
    await channel.invokeMethod('sendContext');
    print("Context sent to native side");
  } on PlatformException catch (e) {
    print("Error sending context: ${e.message}");
  }
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(

    MaterialApp(

      debugShowCheckedModeBanner: false,
      home: WidOver(),
    ),// Your custom overlay widget
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLargeOverlay = false;
  StreamSubscription? overlaySubscription;
  @override
  void initState() {
    super.initState();
    // Listen to overlay events



  }

  @override
  void dispose() {
    // Cancel the stream subscription when the app is closed
    overlaySubscription?.cancel();
    super.dispose();
    print("dispose");
  }






  // Dispose the StreamSubscription when the app is closed


  @override
  Widget build(BuildContext context) {
    DeviceSize.init(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("Flutter Overlay Example")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async{
                  await FlutterOverlayWindow.showOverlay(
                    enableDrag: true,
                    overlayTitle: "Overlay Example",
                    overlayContent: "Main",
                    height: 600, // Overlay height
                    width: 400, // Overlay width
                    alignment: OverlayAlignment.centerLeft, // Center alignment
                    flag: OverlayFlag.defaultFlag, // Default overlay flag
                    visibility: NotificationVisibility.visibilityPublic, // Notification visibility
                  );
                },
                child: Text("Show Overlay"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Close the overlay
                  await FlutterOverlayWindow.closeOverlay();
                  overlaySubscription?.cancel(); // Cancel the subscription when overlay is closed
                  overlaySubscription = null; // Reset to allow reinitialization
                  print("Overlay closed");
                },
                child: Text("Close Overlay"),
              ),
              ElevatedButton(onPressed: ()async{
                await FlutterOverlayWindow.requestPermission();
              },
                  child: Text("Ask Permission")),

            ],
          ),
        ),
      ),
    );
  }
}
