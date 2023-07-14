import 'dart:io';

import 'package:documentscanner/data/document_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk_platform_interface.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'editing_page.dart';
import 'utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'camera_page.dart';
import 'global.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();

  void openResultPage(DocumentData data, bool found) {
    if (!found) {
      SnackBar snackBar = const SnackBar(
        content: Text('No document detected. Please edit it manually.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditingPage(documentData: data),
        ));
  }

  void scanImage() async {
    XFile? photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo == null) {
      return;
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      File rotatedImage =
          await FlutterExifRotation.rotateImage(path: photo.path);
      photo = XFile(rotatedImage.path);
    }

    Uint8List fileBytes = await photo.readAsBytes();

    ui.Image image = await decodeImageFromList(fileBytes);

    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData != null) {
      List<DocumentResult>? results = await docScanner.detectBuffer(
          byteData.buffer.asUint8List(),
          image.width,
          image.height,
          byteData.lengthInBytes ~/ image.height,
          ImagePixelFormat.IPF_ARGB_8888.index);

      if (results != null && results.isNotEmpty) {
        openResultPage(
            DocumentData(
              image: image,
              documentResults: results,
            ),
            true);
      } else {
        double padding = 100;
        List<Offset> points = <Offset>[
          Offset(padding, padding),
          Offset(image.width.toDouble() - padding, padding),
          Offset(image.width.toDouble() - padding,
              image.height.toDouble() - padding),
          Offset(padding, image.height.toDouble() - padding)
        ];
        openResultPage(
            DocumentData(
              image: image,
              documentResults: <DocumentResult>[DocumentResult(0, points, 0)],
            ),
            false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var title = const Padding(
      padding: EdgeInsets.only(
        top: 32,
      ),
      child: Text('DOCUMENT SCANNER',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            color: Colors.white,
          )),
    );

    var description = Padding(
        padding: const EdgeInsets.only(top: 7, left: 33, right: 33),
        child: Text(
            "Auto document border detection, crop and image quality enhancement.",
            style: TextStyle(
              fontSize: 18,
              color: colorTitle,
            )));

    final buttons = Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
                onTap: () {
                  if (!kIsWeb && Platform.isLinux) {
                    showAlert(context, "Warning",
                        "${Platform.operatingSystem} is not supported");
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const CameraPage();
                  }));
                },
                child: Container(
                  width: 150,
                  height: 125,
                  decoration: BoxDecoration(
                    color: colorOrange,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        "images/icon-camera.png",
                        width: 90,
                        height: 60,
                      ),
                      const Text(
                        "Camera Scan",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                )),
            GestureDetector(
                onTap: () {
                  scanImage();
                },
                child: Container(
                  width: 150,
                  height: 125,
                  decoration: BoxDecoration(
                    color: colorBackground,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        "images/icon-image.png",
                        width: 90,
                        height: 60,
                      ),
                      const Text(
                        "Image Scan",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                ))
          ],
        ));
    final image = Image.asset(
      "images/image-document.png",
      width: MediaQuery.of(context).size.width,
      fit: BoxFit.cover,
    );
    return Scaffold(
      body: Column(
        children: [
          title,
          description,
          buttons,
          const SizedBox(
            height: 34,
          ),
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(
                child: image,
              ),
              if (!isLicenseValid)
                Opacity(
                  opacity: 0.8,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      color: const Color(0xffFF1A1A),
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: InkWell(
                          onTap: () {
                            launchUrlString(
                                'https://www.dynamsoft.com/customer/license/trialLicense?product=dbr');
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 20),
                              Text(
                                "  License expired! Renew your license ->",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ))),
                )
            ],
          ))
        ],
      ),
    );
  }
}
