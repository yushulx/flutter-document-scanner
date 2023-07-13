import 'dart:async';
import 'dart:ui';

import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk_platform_interface.dart';

import '../global.dart';
import 'dart:ui' as ui;
import 'package:camera_platform_interface/camera_platform_interface.dart';

import '../utils.dart';

class CameraManager {
  BuildContext context;
  CameraController? controller;
  late List<CameraDescription> _cameras;
  Size? previewSize;
  bool _isScanAvailable = true;
  List<DocumentResult>? documentResults;
  bool isDriverLicense = true;
  bool isFinished = false;
  StreamSubscription<FrameAvailabledEvent>? _frameAvailableStreamSubscription;
  int cameraIndex = 0;
  bool isReadyToGo = false;
  bool _isWebFrameStarted = false;
  DocumentResult? _base;
  int _baseIndex = 0;

  CameraManager(
      {required this.context,
      required this.cbRefreshUi,
      required this.cbIsMounted,
      required this.cbNavigation});

  Function cbRefreshUi;
  Function cbIsMounted;
  Function cbNavigation;

  void initState() {
    initCamera();
  }

  Future<void> switchCamera() async {
    if (_cameras.length == 1) return;
    isFinished = true;

    if (kIsWeb) {
      await waitForStop();
    }

    cameraIndex = cameraIndex == 0 ? 1 : 0;
    toggleCamera(cameraIndex);
  }

  void resumeCamera() {
    toggleCamera(cameraIndex);
  }

  void pauseCamera() {
    stopVideo();
  }

  Future<void> waitForStop() async {
    while (true) {
      if (_isWebFrameStarted == false) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> stopVideo() async {
    isFinished = true;
    if (kIsWeb) {
      await waitForStop();
    }
    if (controller == null) return;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await controller!.stopImageStream();
    }

    controller!.dispose();
    controller = null;

    _frameAvailableStreamSubscription?.cancel();
    _frameAvailableStreamSubscription = null;
  }

  Future<void> webCamera() async {
    _isWebFrameStarted = true;
    while (!(controller == null || isFinished || cbIsMounted() == false)) {
      XFile file = await controller!.takePicture();
      var results = await docScanner.detectFile(file.path);
      if (!cbIsMounted()) break;

      documentResults = results;
      cbRefreshUi();

      if (results == null) continue;
      if (_base == null) {
        _baseIndex += 1;
        _base = results[0];
      } else {
        double previousArea = calculateArea(_base!.points[0], _base!.points[1],
            _base!.points[2], _base!.points[3]);
        double currentArea = calculateArea(results[0].points[0],
            results[0].points[1], results[0].points[2], results[0].points[3]);
        double diff = previousArea - currentArea > 0
            ? previousArea - currentArea
            : currentArea - previousArea;
        if (diff / previousArea < 0.2) {
          _baseIndex += 1;
        } else {
          _baseIndex = 1;
        }

        _base = results[0];
      }

      if (_baseIndex == 10 && results.isNotEmpty) {
        if (!isFinished) {
          isFinished = true;

          final data = await file.readAsBytes();
          ui.Image sourceImage = await decodeImageFromList(data);
          ByteData? byteData =
              await sourceImage.toByteData(format: ui.ImageByteFormat.rawRgba);

          Uint8List bytes = byteData!.buffer.asUint8List();
          int width = sourceImage.width;
          int height = sourceImage.height;
          int stride = byteData.lengthInBytes ~/ sourceImage.height;
          int format = ImagePixelFormat.IPF_ARGB_8888.index;
          handleDocument(
              bytes, width, height, stride, format, documentResults![0].points);
        }
      }
    }
    _isWebFrameStarted = false;
  }

  void handleDocument(Uint8List bytes, int width, int height, int stride,
      int format, dynamic points) {
    docScanner
        .normalizeBuffer(bytes, width, height, stride, format, points)
        .then((normalizedImage) {
      if (normalizedImage != null) {
        PixelFormat pixelFormat = PixelFormat.rgba8888;
        if (!kIsWeb && Platform.isIOS) {
          pixelFormat = PixelFormat.bgra8888;
        }
        decodeImageFromPixels(normalizedImage.data, normalizedImage.width,
            normalizedImage.height, pixelFormat, (ui.Image img) {
          cbNavigation(img);
        });
      }
    });
  }

  void processDocument(List<Uint8List> bytes, int width, int height,
      List<int> strides, int format, List<int> pixelStrides) {
    docScanner
        .detectBuffer(bytes[0], width, height, strides[0], format)
        .then((results) {
      if (!cbIsMounted()) return;
      // results = filterResults(results, width, height);
      if (results == null || results.isEmpty) {
        documentResults = results;
        cbRefreshUi();
        _isScanAvailable = true;
        return;
      }
      if (MediaQuery.of(context).size.width <
          MediaQuery.of(context).size.height) {
        if (Platform.isAndroid) {
          results = rotate90document(results, previewSize!.height.toInt());
        }
      }

      documentResults = results;
      cbRefreshUi();
      if (_base == null) {
        _baseIndex += 1;
        _base = results[0];
      } else {
        double previousArea = calculateArea(_base!.points[0], _base!.points[1],
            _base!.points[2], _base!.points[3]);
        double currentArea = calculateArea(results[0].points[0],
            results[0].points[1], results[0].points[2], results[0].points[3]);
        double diff = previousArea - currentArea > 0
            ? previousArea - currentArea
            : currentArea - previousArea;
        if (diff / previousArea < 0.2) {
          _baseIndex += 1;
        } else {
          _baseIndex = 1;
        }

        _base = results[0];
      }

      if (_baseIndex == 10 && results.isNotEmpty) {
        if (!isFinished) {
          isFinished = true;

          Uint8List data = bytes[0];
          int imageWidth = width;
          int imageHeight = height;

          if (format == ImagePixelFormat.IPF_NV21.index) {
            List<Uint8List> planes = [];
            for (int planeIndex = 0; planeIndex < 3; planeIndex++) {
              Uint8List buffer;
              int planeWidth;
              int planeHeight;
              if (planeIndex == 0) {
                planeWidth = width;
                planeHeight = height;
              } else {
                planeWidth = width ~/ 2;
                planeHeight = height ~/ 2;
              }

              buffer = Uint8List(planeWidth * planeHeight);

              int pixelStride = pixelStrides[planeIndex];
              int rowStride = strides[0];
              int index = 0;
              for (int i = 0; i < planeHeight; i++) {
                for (int j = 0; j < planeWidth; j++) {
                  buffer[index++] =
                      bytes[planeIndex][i * rowStride + j * pixelStride];
                }
              }

              planes.add(buffer);
            }

            data = yuv420ToRgba8888(planes, imageWidth, imageHeight);
            if (MediaQuery.of(context).size.width <
                MediaQuery.of(context).size.height) {
              if (Platform.isAndroid) {
                data = rotate90Degrees(data, imageWidth, imageHeight);
                imageWidth = height;
                imageHeight = width;
              }
            }
          }

          handleDocument(data, imageWidth, imageHeight, imageWidth * 4,
              ImagePixelFormat.IPF_ARGB_8888.index, results[0].points);
        }
      }

      _isScanAvailable = true;
    });
  }

  Future<void> mobileCamera() async {
    await controller!.startImageStream((CameraImage availableImage) async {
      assert(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
      if (cbIsMounted() == false || isFinished) return;
      int format = ImagePixelFormat.IPF_NV21.index;

      switch (availableImage.format.group) {
        case ImageFormatGroup.yuv420:
          format = ImagePixelFormat.IPF_NV21.index;
          break;
        case ImageFormatGroup.bgra8888:
          format = ImagePixelFormat.IPF_ARGB_8888.index;
          break;
        default:
          format = ImagePixelFormat.IPF_RGB_888.index;
      }

      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;

      if (Platform.isAndroid) {
        processDocument(
            [
              availableImage.planes[0].bytes,
              availableImage.planes[1].bytes,
              availableImage.planes[2].bytes
            ],
            availableImage.width,
            availableImage.height,
            [
              availableImage.planes[0].bytesPerRow,
              availableImage.planes[1].bytesPerRow,
              availableImage.planes[2].bytesPerRow
            ],
            format,
            [
              availableImage.planes[0].bytesPerPixel!,
              availableImage.planes[1].bytesPerPixel!,
              availableImage.planes[2].bytesPerPixel!
            ]);
      } else if (Platform.isIOS) {
        processDocument(
            [availableImage.planes[0].bytes],
            availableImage.width,
            availableImage.height,
            [availableImage.planes[0].bytesPerRow],
            format,
            []);
      }
    });
  }

  Future<void> startVideo() async {
    documentResults = null;

    isFinished = false;

    cbRefreshUi();

    if (kIsWeb) {
      webCamera();
    } else if (Platform.isAndroid || Platform.isIOS) {
      mobileCamera();
    } else if (Platform.isWindows) {
      _frameAvailableStreamSubscription?.cancel();
      _frameAvailableStreamSubscription =
          (CameraPlatform.instance as CameraWindows)
              .onFrameAvailable(controller!.cameraId)
              .listen(_onFrameAvailable);
    }
  }

  void _onFrameAvailable(FrameAvailabledEvent event) {
    if (cbIsMounted() == false || isFinished) return;

    Map<String, dynamic> map = event.toJson();
    final Uint8List? data = map['bytes'] as Uint8List?;
    if (data != null) {
      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;
      int width = previewSize!.width.toInt();
      int height = previewSize!.height.toInt();

      processDocument([data], width, height, [width * 4],
          ImagePixelFormat.IPF_ARGB_8888.index, []);
    }
  }

  Future<void> initCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      // int index = 0;

      // for (; index < _cameras.length; index++) {
      //   CameraDescription description = _cameras[index];
      //   if (description.name.toLowerCase().contains('back')) {
      //     _isMobileWeb = true;
      //     break;
      //   }
      // }
      if (_cameras.isEmpty) return;

      if (!kIsWeb) {
        toggleCamera(cameraIndex);
      } else {
        if (_cameras.length > 1) {
          cameraIndex = 1;
          toggleCamera(cameraIndex);
        } else {
          toggleCamera(cameraIndex);
        }
      }
    } on CameraException catch (e) {
      print(e);
    }
  }

  Widget getPreview() {
    if (controller == null || !controller!.value.isInitialized || isFinished) {
      return Container(
        child: const Text('No camera available!'),
      );
    }

    // if (kIsWeb && !_isMobileWeb) {
    //   return Transform(
    //     alignment: Alignment.center,
    //     transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
    //     child: CameraPreview(controller!),
    //   );
    // }

    return CameraPreview(controller!);
  }

  Future<void> toggleCamera(int index) async {
    // if (controller != null) controller!.dispose();
    ResolutionPreset preset = ResolutionPreset.high;
    if (kIsWeb) {
      preset = ResolutionPreset.medium;
    }
    controller = CameraController(_cameras[index], preset);
    controller!.initialize().then((_) {
      if (!cbIsMounted()) {
        return;
      }

      previewSize = controller!.value.previewSize;

      startVideo();
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
  }
}
