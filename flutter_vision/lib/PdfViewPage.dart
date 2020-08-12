import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
//import 'package:simple_share/simple_share.dart';
import 'package:share_extend/share_extend.dart';
import 'package:flutter_vision/main.dart';


class PdfViewPage extends StatefulWidget {
  final String path;

  const PdfViewPage({Key key, this.path}) : super(key: key);
  @override
  _PdfViewPageState createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool pdfReady = false;
  PDFViewController _pdfViewController;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Document"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ShareExtend.share(widget.path, "file");
            }
             // SimpleShare.share(uri: ,msg: "My message", subject: "subject example");},
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,

        children: <Widget>[
        PDFView(filePath: widget.path,
        autoSpacing: true,
        enableSwipe: false,
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
          if(_currentPage > 0 )
          {_currentPage=page;}
        },
        onPageError: (page, e) {},
      ),
      !pdfReady
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Offstage(),
        Container(
          alignment: Alignment.centerLeft,
          child:_currentPage > 0
              ? IconButton(
          padding: EdgeInsets.all(0.0),
          alignment: Alignment.centerLeft,
          iconSize: 50,
          color: Colors.blue,
          icon: Icon(Icons.chevron_left),
            onPressed: () {
              _currentPage -= 1;
              _pdfViewController.setPage(_currentPage);
            },
          )
              : Offstage(),
        ),
          Container(
            alignment: Alignment.centerRight,
            child:_currentPage+1 < _totalPages
                ?
            IconButton(
              padding: EdgeInsets.all(0.0),
              alignment: Alignment.centerRight,
              iconSize: 50,
              color: Colors.blue,
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                _currentPage += 1;
                _pdfViewController.setPage(_currentPage);
              },
            )
                : Offstage(),
          ),

          /*PDFView(
            filePath: widget.path,
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
              if(_currentPage > 0 )
                {_currentPage=page;}
            },
            onPageError: (page, e) {},
          ),
          !pdfReady
              ? Center(
            child: CircularProgressIndicator(),
          )
              : Offstage(),
          )*/


      //Align(alignment:Alignment.centerRight,child:
      Container(
        alignment: Alignment.bottomCenter,
        child: Text('Seite ${_currentPage+1}',
              style: TextStyle(fontSize: 14)),
      ),


         // Expanded(child: RaisedButton(onPressed: () {Navigator.push(context, MaterialPageRoute(

     /* Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
         //


            IconButton(

              alignment: Alignment.centerRight,
              iconSize: 100,
              color: Colors.blue,
              icon: Icon(Icons.chevron_right),)
        ]),*/
          //builder: (context) =>CameraScreen()));},child: Text("Add Page to pdf"),color: Colors.black,textColor: Colors.white,)),
        ],

      ),
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(left: 30),
                child: IconButton(
                    iconSize: 30,
                    focusColor: Colors.blue,
                    icon: Icon(Icons.camera),
                  onPressed: () { files.removeLast();
                  Navigator.push(context, MaterialPageRoute(
                     builder: (context) =>CameraScreen()));}
                )),
      FloatingActionButton.extended(
          backgroundColor: Colors.red,
          label: Text('+'),//Icon(Icons.add),
        onPressed: () {Navigator.push(context, MaterialPageRoute(
            builder: (context) =>CameraScreen()));}
       ),

          ]
      ),




      /*floatingActionButton: Row(
       mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
        FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {Navigator.push(context, MaterialPageRoute(
              builder: (context) =>CameraScreen()));}
      ),
        FloatingActionButton(
            child: Icon(Icons.camera_alt),
            onPressed: () {Navigator.push(context, MaterialPageRoute(
                builder: (context) =>CameraScreen()));}
        ),
              ]
              )
*/
    );
  }
}