import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_vision/pdf.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_vision/PdfPreviewScreen.dart';
import 'package:flutter_vision/main.dart';

class DetailScreen extends StatefulWidget {
  final String imagePath;
  List<File> _files;
  DetailScreen(this.imagePath,this._files);

    @override
  _DetailScreenState createState() => new _DetailScreenState(imagePath,_files);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this.path,this._files);
  List<File> _files;
  final String path;

  Size _imageSize;
  String recognizedText = "Loading ...";
  final pdf=pw.Document();



  void _initializeVision() async {
    // TODO: Initialize the text recognizer here
    final File imageFile = File(path);

    if (imageFile != null) {
      await _getImageSize(imageFile);
    }

    final FirebaseVisionImage visionImage =
    FirebaseVisionImage.fromFile(imageFile);

    final TextRecognizer textRecognizer =
    FirebaseVision.instance.textRecognizer();

    final VisionText visionText =
    await textRecognizer.processImage(visionImage);

    // Regular expression for verifying an email address
    String pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    RegExp regEx = RegExp(pattern);
    String mailAddress = "";

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        // Checking if the line contains an email address
        if (line.text.contains('@')) {
          mailAddress += line.text + '\n';
        }
      }
    }

    if (this.mounted) {
      setState(() {
        recognizedText = mailAddress;
      });
    }

  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    // Fetching image from path
    final Image image = Image.file(imageFile);

    // Retrieving its size
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });

  }


  Future savePdf() async{
    Directory documentDirectory = await getApplicationDocumentsDirectory();

    String documentPath = documentDirectory.path;

    File file = File("$documentPath/example.pdf");
    //File file=File(imagePath);
    file.writeAsBytesSync(pdf.save());
    print(file);
  }


  @override
  void initState() {
    _initializeVision();
    super.initState();
  }


  writeOnPdf() async{
    for (var i = 0; i < _files.length; i++) {
      // added this
      var image = PdfImage.file(
        pdf.document,
        bytes: File(_files[i].path).readAsBytesSync(),
      );

      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image));
          }));
      print('helloooooooooooo');
      print(pdf.document);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Details"),
      ),
      body: _imageSize != null
          ? Stack(
        children: <Widget>[
          Center(
            child: Container(
              width: double.maxFinite,
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: _imageSize.aspectRatio,
                child: Image.file(
                  File(path),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //Row(),
                   // Container(
                      //height: 60,
                      //child: SingleChildScrollView(
                 //       child: ListTile(
                          Row(
                            children: <Widget>[
                              Expanded(child: RaisedButton(onPressed: () {Navigator.push(context, MaterialPageRoute(
                                  builder: (context) =>CameraScreen()));},child: Text("Recapture"),color: Colors.black,textColor: Colors.white,)),
                              Expanded(child: RaisedButton(onPressed: () async{

                              Directory documentDirectory = await getApplicationDocumentsDirectory();

                              String documentPath = documentDirectory.path;

                              String fullPath = "$documentPath/example.pdf";

                              Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => PdfPreviewScreen(path: fullPath,)
                              ));},
                                child: Text("Export"),color: Colors.black,textColor: Colors.white,)),
                              Expanded(child: RaisedButton(onPressed: () async{writeOnPdf();
                              await savePdf();},child: Text("Add Page to pdf"),color: Colors.black,textColor: Colors.white,)),
                            ],
                          ),
                  //      )
                     // ),
                    //),
                  ],
                ),
              ),
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