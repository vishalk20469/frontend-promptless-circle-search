import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart';
import 'package:overlay/constant.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';


class WidOver extends StatefulWidget {
  const WidOver({super.key});

  @override
  State<WidOver> createState() => _WidOverState();
}

class _WidOverState extends State<WidOver> {
  Uint8List? _capturedImage;
  Uint8List? _croppedImageBytes;
  bool isDrawingEnabled = false; // Toggle state for drawing
  List<Offset> points = []; // Stores points for the path
  Path? freehandPath; // Finalized drawn path
  Rect? boundingBox; // Bounding box for the drawn path
  Offset? _currentPoint;
  String info = "";// Current touch point for glowing effect

  // GlobalKey for RenderRepaintBoundary.
  final GlobalKey _globalKey = GlobalKey();

  // Variables for overlay canvas size animation.
  double _canvasWidth = 150;
  double _canvasHeight = 300;

  // Generates a Path from points.
  Path _generatePath(List<Offset> points) {
    Path path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    return path;
  }

  // Calculates the bounding box for the given points.
  Rect _calculateBoundingBox(List<Offset> points) {
    double minX = points.first.dx;
    double minY = points.first.dy;
    double maxX = points.first.dx;
    double maxY = points.first.dy;
    for (var point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Uses RenderRepaintBoundary and the image package to capture and crop
  /// the drawing based on the calculated bounding box.
  void _cropBoundingBox() async {
    if (boundingBox == null) {
      print("No bounding box to crop!");
      return;
    }

    try {
      final Uint8List? capturedImage =
      await FlutterOverlayWindow.captureOverlayImage();
      if (capturedImage == null) {
        print("No image captured");
        return;
      }

      img.Image? fullImage = img.decodeImage(capturedImage);
      if (fullImage == null) {
        print("Error decoding captured image");
        return;
      }

      final double overlayTopOffset = 30.0;
      final Size overlaySize = Size(360, 800);
      double scaleX = fullImage.width / overlaySize.width;
      double scaleY = fullImage.height / overlaySize.height;
      int cropX = (boundingBox!.left * scaleX).toInt();
      int cropY = ((boundingBox!.top + overlayTopOffset) * scaleY).toInt();
      int cropWidth = (boundingBox!.width * scaleX).toInt();
      int cropHeight = (boundingBox!.height * scaleY).toInt();
      img.Image croppedImage = img.copyCrop(fullImage, cropX, cropY, cropWidth, cropHeight);
      final Uint8List croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));

      setState(() {
        _croppedImageBytes = croppedBytes;
      });

      print("Cropping completed!");

     /* showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Image.memory(croppedBytes),
            ),
          );
        },
      );*/
      // Upload the cropped image to the backend
      await _uploadCroppedImage(croppedBytes);
    } catch (e) {
      print("Error cropping image: $e");
    }
  }

  /// This function uploads the cropped image to the Flask backend
  Future<void> _uploadCroppedImage(Uint8List imageBytes) async {
    // Update the URL below with your computer's IP address that the device can reach.
    // For example: http://192.168.1.100:5000/predict
    final Uri url = Uri.parse('http://192.168.193.105:4000/predict');




    var request = http.MultipartRequest('POST', url);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image', // The key expected by the backend
        imageBytes,
        filename: 'cropped_image.png',
        contentType: MediaType('image', 'png'),
      ),
    );

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        print("Upload successful!");
        print("Fruit: ${jsonResponse['fruit']}");
        print("Info: ${jsonResponse['info']}");
        print("Extra: ${jsonResponse['gpt_extra']}");
        setState(() {
          info = jsonResponse['fruit'] + "\n" + jsonResponse['info'] + "\n" + jsonResponse['gpt_extra'];
        });


      } else {
        print("Error uploading image: ${response.statusCode} \n$responseBody");
      }
    } catch (e) {
      print("Upload error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Animated container for overlay resizing animation.
            AnimatedContainer(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              width: _canvasWidth,
              height: _canvasHeight,
              child: RepaintBoundary(
                key: _globalKey,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (isDrawingEnabled) {
                      setState(() {
                        points.add(details.localPosition);
                        _currentPoint = details.localPosition;
                      });
                    }
                  },
                  onPanEnd: (details) {
                    if (isDrawingEnabled) {
                      setState(() {
                        freehandPath = _generatePath(points);
                        boundingBox = _calculateBoundingBox(points);
                        points.clear();
                        _currentPoint = null;
                      });
                    }
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: DrawingPainter(points, freehandPath, boundingBox,
                        currentPoint: _currentPoint),
                  ),
                ),
              ),
            ),
            // Control buttons.
            Positioned(
              top: 50,
              right: 20,
              child: Column(
                children: [
                  // Brush icon toggles drawing.
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isDrawingEnabled = !isDrawingEnabled;
                        if (!isDrawingEnabled) {
                          freehandPath = null;
                          boundingBox = null;
                          points.clear();
                        }
                      });
                      print(isDrawingEnabled
                          ? "Drawing enabled"
                          : "Drawing disabled");
                    },
                    child: Container(
                      decoration: BoxDecoration(

                        border: Border.all(width: 2.0),
                        color: isDrawingEnabled
                            ? Colors.green
                            :  Color(0xCC4D4D4D),
                      ),
                      child: const Icon(Icons.brush, size: 35,color: Colors.white,),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Crop icon triggers cropping.
                  GestureDetector(
                    onTap: () {
                      if (freehandPath != null && boundingBox != null) {
                        print("Cropping initiated...");
                        _cropBoundingBox();
                      } else {
                        print("No drawing to crop!");
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xCC4D4D4D),
                        border: Border.all(width: 2.0),
                      ),
                      child: const Icon(Icons.crop, size: 35,color: Colors.white,),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Safety Check icon animates overlay to fullscreen.
                  GestureDetector(
                    onTap: () async {
                      print("Safety Check");
                      await FlutterOverlayWindow.moveOverlay(OverlayPosition(0.0, 30.0));
                      await FlutterOverlayWindow.resizeOverlay(360, 800, false);
                      setState(() {
                        _canvasWidth = 360;
                        _canvasHeight = 800;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xCC4D4D4D),
                        border: Border.all(width: 2.0),
                      ),
                      child: const Icon(Icons.open_with, size: 35,color: Colors.white,),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Cancel icon.
                  GestureDetector(
                    onTap: () async {
                      print("Cancel");
                      await FlutterOverlayWindow.resizeOverlay(150, 300, true);
                      setState(() {
                        points.clear();
                        freehandPath = null;
                        boundingBox = null;
                        _capturedImage = null;
                        _croppedImageBytes = null;
                        info = "";
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xCC4D4D4D),
                        border: Border.all(width: 2.0),
                      ),
                      child: const Icon(Icons.cancel_outlined, size: 35,color: Colors.white,),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            // Inside your build method's Stack, add a Positioned widget when info is not empty and boundingBox is not null
            if (boundingBox != null && info.isNotEmpty)
              Positioned(
                // Position the container below the bounding box with a small gap (e.g., 10 pixels)
                left: boundingBox!.left,
                top: boundingBox!.bottom + 10,
                child: Container(
                  width: boundingBox!.width, // You can adjust this as needed
                  height: 150, // Set a fixed height or make it dynamic
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      info,
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points; // Current points being drawn.
  final Path? path; // Finalized freehand path.
  final Rect? boundingBox; // Bounding box for the drawing.
  final Offset? currentPoint; // Current touch point for glowing effect.
  DrawingPainter(this.points, this.path, this.boundingBox, {this.currentPoint});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    if (points.isNotEmpty) {
      Path currentPath = Path();
      currentPath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        currentPath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(currentPath, paint);
    }

    if (path != null) {
      Paint pathPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path!, pathPaint);
    }

    if (boundingBox != null) {
      Paint boxPaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(boundingBox!, boxPaint);
    }

    // Glowing brush effect.
    if (currentPoint != null) {
      Paint glowPaint = Paint()
        ..color = Colors.blueAccent.withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(currentPoint!, 15, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
