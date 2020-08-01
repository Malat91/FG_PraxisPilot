import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_vision/image_detail.dart';
import 'package:image_cropper/image_cropper.dart';

// Global variable for storing the list of
// cameras available
List<CameraDescription> cameras = [];
List<File> _files = [];
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Retrieve the device cameras
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print(e);
  }
  runApp(MyApp());
}

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

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _inProcess = false;
  CameraController _controller;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(cameras[0], ResolutionPreset.veryHigh);
    _controller.initialize().then((_) {
      if (!mounted) {
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
      await _controller.takePicture(imagePath);
      //File image=File(imagePath);
      if(imagePath != null){
        File cropped = await ImageCropper.cropImage(
          sourcePath: imagePath,
          cropStyle: CropStyle.rectangle,
          aspectRatio: CropAspectRatio(ratioX: MediaQuery.of(context).size.width * 0.9
              , ratioY: MediaQuery.of(context).size.width * 0.9 / 0.7),
          androidUiSettings: AndroidUiSettings(
              hideBottomControls: true,
              //initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
        );
        print('After crop $cropped');
        this.setState((){
          //_selectedFile =cropped;

          imagePath=cropped.path;
          _inProcess = false;
        });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('ML Camera Vision'),
      ),
      body: _controller.value.isInitialized
          ? Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CameraPreview(_controller),

          Container(

            padding: const EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9 / 0.7,
            decoration: new BoxDecoration(
                border: Border.all(
                    color: Colors.white,
                    width: 2,
                    style: BorderStyle.solid),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(4.0))),
            //child: CameraPreview(_controller),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              alignment: Alignment.bottomCenter,
              child: RaisedButton.icon(
                icon: Icon(Icons.camera),
                label: Text("Click"),
                onPressed: () async {
                  File cameraFile;
                  await _takePicture().then((String path) {
                    print('hello');

                    if (path != null) {
                      // _buildCroppingImage(File(path));
                      //print('hello crop');
                      cameraFile=File(path);
                      List<File> temp = _files;
                      temp.add(cameraFile);
                      setState(() {
                        _files = temp;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(path,_files),
                        ),
                      );
                    }
                  });
                },
              ),
            ),
          )
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