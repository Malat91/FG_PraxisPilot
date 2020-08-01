import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CreatePdf extends StatelessWidget{
  final String imagePath;
  CreatePdf(this.imagePath);

  final pdf=pw.Document();

  Future savePdf() async{
    Directory documentDirectory = await getApplicationDocumentsDirectory();

    String documentPath = documentDirectory.path;

    File file = File("$documentPath/example.pdf");
    //File file=File(imagePath);
    file.writeAsBytesSync(pdf.save());
    print(file);
  }

  writeOnPdf(){
    pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),

          build: (pw.Context context){
            return <pw.Widget> [
              pw.Header(
                level: 0,
                child: pw.Text("Easy Approach"),
              )
            ];
          }
        ));
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    throw UnimplementedError();
  }
}
