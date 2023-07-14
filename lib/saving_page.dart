import 'dart:ui';

import 'global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk_platform_interface.dart';
import 'package:flutter_document_scan_sdk/template.dart';
import 'package:flutter_document_scan_sdk/normalized_image.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'data/document_data.dart';
import 'utils.dart';

class SavingPage extends StatefulWidget {
  const SavingPage({super.key, required this.documentData});

  final DocumentData documentData;

  @override
  State<SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<SavingPage> {
  ui.Image? normalizedUiImage;

  NormalizedImage? normalizedImage;
  String _pixelFormat = 'color';

  @override
  void initState() {
    super.initState();
    initDocumentState();
  }

  Future<ui.Image> loadImage(XFile file) async {
    final data = await file.readAsBytes();
    return await decodeImageFromList(data);
  }

  Future<int> initDocumentState() async {
    await docScanner.setParameters(Template.color);
    await normalizeBuffer(widget.documentData.image!,
        widget.documentData.documentResults![0].points);
    return 0;
  }

  Widget createCustomImage(BuildContext context, ui.Image image,
      List<DocumentResult> detectionResults) {
    return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
            width: image.width.toDouble(),
            height: image.height.toDouble(),
            child: CustomPaint(
              painter: OverlayPainter(image, detectionResults),
            )));
  }

  Widget createWidget() {
    if (normalizedUiImage == null) {
      return const CircularProgressIndicator();
    } else {
      var pageContent = Column(children: [
        Expanded(child: createCustomImage(context, normalizedUiImage!, [])),
        SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Theme(
                  data: Theme.of(context).copyWith(
                    unselectedWidgetColor:
                        Colors.white, // Color when unselected
                  ),
                  child: Radio(
                    activeColor: colorOrange,
                    value: 'binary',
                    groupValue: _pixelFormat,
                    onChanged: (String? value) async {
                      setState(() {
                        _pixelFormat = value!;
                      });

                      await docScanner.setParameters(Template.binary);

                      if (widget.documentData.documentResults!.isNotEmpty) {
                        await normalizeBuffer(widget.documentData.image!,
                            widget.documentData.documentResults![0].points);
                      }
                    },
                  ),
                ),
                const Text('Binary', style: TextStyle(color: Colors.white)),
                Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor:
                          Colors.white, // Color when unselected
                    ),
                    child: Radio(
                      activeColor: colorOrange,
                      value: 'grayscale',
                      groupValue: _pixelFormat,
                      onChanged: (String? value) async {
                        setState(() {
                          _pixelFormat = value!;
                        });

                        await docScanner.setParameters(Template.grayscale);

                        if (widget.documentData.documentResults!.isNotEmpty) {
                          await normalizeBuffer(widget.documentData.image!,
                              widget.documentData.documentResults![0].points);
                        }
                      },
                    )),
                const Text('Gray', style: TextStyle(color: Colors.white)),
                Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor:
                          Colors.white, // Color when unselected
                    ),
                    child: Radio(
                      activeColor: colorOrange,
                      value: 'color',
                      groupValue: _pixelFormat,
                      onChanged: (String? value) async {
                        setState(() {
                          _pixelFormat = value!;
                        });

                        await docScanner.setParameters(Template.color);

                        if (widget.documentData.documentResults!.isNotEmpty) {
                          await normalizeBuffer(widget.documentData.image!,
                              widget.documentData.documentResults![0].points);
                        }
                      },
                    )),
                const Text('Color', style: TextStyle(color: Colors.white)),
              ],
            )),
      ]);
      return pageContent;
    }
  }

  void close() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorMainTheme,
        title: const Text('Edit Document'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: ElevatedButton(
              onPressed: () async {
                String imageString =
                    await convertImagetoPngBase64(normalizedUiImage!);

                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                var results = prefs.getStringList('document_data');
                List<String> imageList = <String>[];
                imageList.add(imageString);
                if (results == null) {
                  prefs.setStringList('document_data', imageList);
                } else {
                  results.addAll(imageList);
                  prefs.setStringList('document_data', results);
                }

                close();
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorMainTheme)),
              child: Text('Save',
                  style: TextStyle(color: colorOrange, fontSize: 22)),
            ),
          )
        ],
      ),
      body: createWidget(),
    );
  }

  Future<void> normalizeFile(String file, dynamic points) async {
    normalizedImage = await docScanner.normalizeFile(file, points);
    if (normalizedImage != null) {
      decodeImageFromPixels(normalizedImage!.data, normalizedImage!.width,
          normalizedImage!.height, PixelFormat.rgba8888, (ui.Image img) {
        normalizedUiImage = img;
        setState(() {});
      });
    }
  }

  Future<void> normalizeBuffer(ui.Image sourceImage, dynamic points) async {
    ByteData? byteData =
        await sourceImage.toByteData(format: ui.ImageByteFormat.rawRgba);

    Uint8List bytes = byteData!.buffer.asUint8List();
    int width = sourceImage.width;
    int height = sourceImage.height;
    int stride = byteData.lengthInBytes ~/ sourceImage.height;
    int format = ImagePixelFormat.IPF_ARGB_8888.index;

    normalizedImage = await docScanner.normalizeBuffer(
        bytes, width, height, stride, format, points);
    if (normalizedImage != null) {
      decodeImageFromPixels(normalizedImage!.data, normalizedImage!.width,
          normalizedImage!.height, PixelFormat.rgba8888, (ui.Image img) {
        normalizedUiImage = img;
        setState(() {});
      });
    }
  }
}
