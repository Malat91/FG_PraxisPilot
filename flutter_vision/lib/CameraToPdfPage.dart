//import 'dart:html';
import 'package:flutter/material.dart';
//import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:ui' as ui;
import 'package:share_extend/share_extend.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
//import 'package:flutter_vision/PdfPreviewScreen.dart';
import 'package:flutter_vision/main.dart';
//import 'package:flutter_vision/PdfViewPage.dart';


class CameraToPdfPage extends StatefulWidget {
  final String imagePath;
  List<File> _files;


  CameraToPdfPage(this.imagePath,this._files);

  @override
  _CameraToPdfPageState createState() => new _CameraToPdfPageState(imagePath,_files);
}

class _CameraToPdfPageState extends State<CameraToPdfPage> {
  _CameraToPdfPageState(this.path,this._files){
  }
  List<File> _files;
  final String path;
  int _totalPages = 0;
  int _currentPage = 0;
  bool pdfReady = false;
  PDFViewController _pdfViewController;
  String fullPath;

  final pdf=pw.Document();

  @override
  void initState() {
    writeOnPdf();
    savePdf().then((value){
      print('Async done');
    });
    super.initState();
  }

  Future savePdf() async{
    Directory documentDirectory = await getApplicationDocumentsDirectory();

    String documentPath = documentDirectory.path;

    File file = File("$documentPath/example.pdf");
    //File file=File(imagePath);
    file.writeAsBytesSync(pdf.save());

    fullPath = "$documentPath/example.pdf";
    print(file);
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

    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Document"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                ShareExtend.share(fullPath, "file");
              }
            // SimpleShare.share(uri: ,msg: "My message", subject: "subject example");},
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          PDFView(
            filePath: fullPath,
            autoSpacing: true,
            enableSwipe: true,
            pageSnap: true,
            swipeHorizontal: true,
            nightMode: false,

            onError: (e) {
              print(e);
            },
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages;
                pdfReady = true;
              });
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int page, int total) {
              setState(() {});
            },
            onPageError: (page, e) {},
          ),
          !pdfReady
              ? Center(
            child: CircularProgressIndicator(),
          )
              : Offstage(),
          Text('Seite ${_currentPage+1}',
              style: TextStyle(fontSize: 10)),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _currentPage > 0
              ? FloatingActionButton.extended(
            backgroundColor: Colors.red,
            label: Text("<"),
            onPressed: () {
              _currentPage -= 1;
              _pdfViewController.setPage(_currentPage);
            },
          )
              : Offstage(),
          _currentPage+1 < _totalPages
              ? FloatingActionButton.extended(
            backgroundColor: Colors.green,
            label: Text(">"),
            onPressed: () {
              _currentPage += 1;
              _pdfViewController.setPage(_currentPage);
            },
          )
              : Offstage(),

        ],

      ),

    );
  }



}
