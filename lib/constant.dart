import 'package:flutter/material.dart';

class DeviceSize {
  static double width = 0;
  static double height = 0;

  // Call this once (e.g., from your main widget's build or initState) to store device dimensions.
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
    print(width);
    print(height);
  }
}
