import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_vision/image_detail.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';


// Global variable for storing the list of
// cameras available
List<CameraDescription> cameras = [];

//Future<void> main() async {
 // try {
 //   WidgetsFlutterBinding.ensureInitialized();
    // Retrieve the device cameras
 //   cameras = await availableCameras();
 // } on CameraException catch (e) {
 //   print(e);
  //}
 // runApp(MyApp());
//}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Vision',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraScreen(),
    );
  }
}

class RectanglePainter extends CustomPainter {
  List<Offset> points;
  bool clear;
  final ui.Image image;

  RectanglePainter(
      {@required this.points, @required this.clear, @required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final outputRect =
    Rect.fromPoints(ui.Offset.zero, ui.Offset(size.width, size.height));
    final Size imageSize =
    Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes =
    applyBoxFit(BoxFit.contain, imageSize, outputRect.size);
    final Rect inputSubrect =
    Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubrect =
    Alignment.center.inscribe(sizes.destination, outputRect);
    canvas.drawImageRect(image, inputSubrect, outputSubrect, paint);
    if (!clear) {
      final circlePaint = Paint()
        ..color = Colors.red
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.multiply
        ..strokeWidth = 2;

      for (int i = 0; i < points.length; i++) {
        if (i + 1 == points.length) {
          canvas.drawLine(points[i], points[0], paint);
        } else {
          canvas.drawLine(points[i], points[i + 1], paint);
        }
        canvas.drawCircle(points[i], 10, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(RectanglePainter oldPainter) =>
      oldPainter.points != points || clear;
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _inProcess = false;
  CameraController _controller;


  ui.Image _image;
  Image _imageWidget;
  List<ui.Offset> _points = [ui.Offset(90, 120), ui.Offset(90, 370), ui.Offset(320, 370), ui.Offset(320, 120)];
  bool _clear = false;
  int _currentlyDraggedIndex = -1;




  @override
  void initState() {
    super.initState();

    _controller = CameraController(cameras[0], ResolutionPreset.veryHigh);
    _controller.initialize().then((_) {
      if (!mounted) {
        print('hello not mounted');
        return;
      }
      setState(() {});
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<ui.Image> loadUiImage(String imageAssetPath) async {
    //final ByteData data = await rootBundle.load(imageAssetPath);
    final ByteData data= File(imageAssetPath).readAsBytesSync().buffer.asByteData();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });

  }

  Future<String> _takePicture() async {
    this.setState((){
      _inProcess = true;
    });
    // Checking whether the controller is initialized
    if (!_controller.value.isInitialized) {
      print("Controller is not initialized");
      return null;
    }

    // Formatting Date and Time
    String dateTime = DateFormat.yMMMd()
        .addPattern('-')
        .add_Hms()
        .format(DateTime.now())
        .toString();

    String formattedDateTime = dateTime.replaceAll(' ', '');
    print("Formatted: $formattedDateTime");

    // Retrieving the path for saving an image
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String visionDir = '${appDocDir.path}/Photos/Vision\ Images';
    await Directory(visionDir).create(recursive: true);
    String imagePath = '$visionDir/image_$formattedDateTime.jpg';

    // Checking whether the picture is being taken
    // to prevent execution of the function again
    // if previous execution has not ended
    if (_controller.value.isTakingPicture) {
      print("Processing is in progress...");
      return null;
    }

    try {
      // Captures the image and saves it to the
      // provided path
      print ('hello in take pic');
      await _controller.takePicture(imagePath);
      print(imagePath);
      //File image=File(imagePath);
      if(imagePath != null){
        //File imageFile = File(imagePath);
        ui.Image finalImg = await loadUiImage(imagePath);
        _image = finalImg;   //Image.file( File(imagePath));
        print(_image);
      } else {
        this.setState((){
          _inProcess = false;
        });
      }

    } on CameraException catch (e) {
      print("Camera Exception: $e");
      return null;
    }

    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text("ML Camera Vision"),
    );
    return Scaffold(
      appBar: appBar,
      body: _controller.value.isInitialized
          ? Stack(
        children: <Widget>[
          CameraPreview(_controller),


          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              alignment: Alignment.bottomCenter,

              child: FittedBox(
                fit: BoxFit.fill,
                child: GestureDetector(
                  onPanStart: (DragStartDetails details) {
                    // get distance from points to check if is in circle
                    int indexMatch = -1;
                    for (int i = 0; i < _points.length; i++) {
                      double distance = sqrt(
                          pow(details.localPosition.dx - _points[i].dx, 2) +
                              pow(details.localPosition.dy - _points[i].dy, 2));
                      if (distance <= 30) {
                        indexMatch = i;
                        break;
                      }
                    }
                    if (indexMatch != -1) {
                      _currentlyDraggedIndex = indexMatch;
                    }
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    if (_currentlyDraggedIndex != -1) {
                      setState(() {
                        _points = List.from(_points);
                        _points[_currentlyDraggedIndex] = details.localPosition;
                      });
                    }
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _currentlyDraggedIndex = -1;
                    });
                  },
                  child: SizedBox(
                    // width: _image.width.toDouble(),
                    //  height: _image.height.toDouble(),
                    child: CustomPaint(
                      size: Size.fromHeight(MediaQuery.of(context).size.height - appBar.preferredSize.height),
                      painter: RectanglePainter(
                          points: _points, clear: _clear, image: ),
                    ),
                  ),
                ),
              ),
              //Raised Button
            ),
          ),


        ],

      )
          : Container(

        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

}