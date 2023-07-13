import 'package:flutter/material.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk.dart';
import 'package:flutter_document_scan_sdk/template.dart';

FlutterDocumentScanSdk docScanner = FlutterDocumentScanSdk();
bool isLicenseValid = false;

Future<int> initDocumentSDK() async {
  int? ret = await docScanner.init(
      'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
  await docScanner.setParameters(Template.color);
  return ret ?? -1;
}

Color colorMainTheme = const Color(0xff1D1B20);
Color colorOrange = const Color(0xffFE8E14);
Color colorTitle = const Color(0xffF5F5F5);
Color colorSelect = const Color(0xff757575);
Color colorText = const Color(0xff888888);
Color colorBackground = const Color(0xFF323234);
Color colorSubtitle = const Color(0xffCCCCCC);
Color colorGreen = const Color(0xff6AC4BB);

Widget createOverlay(
  List<DocumentResult>? documentResults,
) {
  return CustomPaint(
    painter: OverlayPainter(documentResults),
  );
}

class OverlayPainter extends CustomPainter {
  List<DocumentResult>? documentResults;

  OverlayPainter(this.documentResults);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (documentResults != null) {
      for (var result in documentResults!) {
        canvas.drawLine(result.points[0], result.points[1], paint);
        canvas.drawLine(result.points[1], result.points[2], paint);
        canvas.drawLine(result.points[2], result.points[3], paint);
        canvas.drawLine(result.points[3], result.points[0], paint);
      }
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) => true;
}

List<DocumentResult> rotate90document(List<DocumentResult>? input, int height) {
  if (input == null) {
    return [];
  }

  List<DocumentResult> output = [];
  for (DocumentResult result in input) {
    double x1 = result.points[0].dx;
    double x2 = result.points[1].dx;
    double x3 = result.points[2].dx;
    double x4 = result.points[3].dx;
    double y1 = result.points[0].dy;
    double y2 = result.points[1].dy;
    double y3 = result.points[2].dy;
    double y4 = result.points[3].dy;

    List<Offset> points = [
      Offset(height - y1, x1),
      Offset(height - y2, x2),
      Offset(height - y3, x3),
      Offset(height - y4, x4)
    ];
    DocumentResult newResult = DocumentResult(result.confidence, points, []);

    output.add(newResult);
  }

  return output;
}
