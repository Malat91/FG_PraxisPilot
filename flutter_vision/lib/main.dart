import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:flutter_vision/image_detail.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_vision/CameraToPdfPage.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_vision/PdfViewPage.dart';

// Global variable for storing the list of
// cameras available
List<CameraDescription> cameras = [];
List<File> files = [];

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
  static var pdf;//=pw.Document();

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
    print('helloooooooooooooooooooooooooooooooooooooooo');
    pdf=pw.Document();
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

  Future savePdf() async{
    Directory documentDirectory = await getApplicationDocumentsDirectory();

    String documentPath = documentDirectory.path;

    File file = File("$documentPath/example.pdf");
    //File file=File(imagePath);
    file.writeAsBytesSync(pdf.save());
    print('hellooooooo save pdf');
    print(file);
  }



  writeOnPdf() async{
    print('hellooooooo write pdf');
    for (var i = 0; i < files.length; i++) {
      // added this
      var image = PdfImage.file(
        pdf.document,
        bytes: File(files[i].path).readAsBytesSync(),
      );

      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image));
          }));

    }
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
                  Directory documentDirectory = await getApplicationDocumentsDirectory();

                  String documentPath = documentDirectory.path;

                  String fullPath = "$documentPath/example.pdf";
                  await _takePicture().then((String path) {
                    print('hello');

                    if (path != null) {
                      // _buildCroppingImage(File(path));
                      //print('hello crop');
                      cameraFile=File(path);
                      List<File> temp = files;
                      temp.add(cameraFile);
                      setState(() {
                        files = temp;
                      });

                      writeOnPdf();
                      savePdf();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewPage(path: fullPath,),
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