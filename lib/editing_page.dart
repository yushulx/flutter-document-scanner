import 'package:flutter/material.dart';

import 'data/document_data.dart';
import 'global.dart';
import 'saving_page.dart';

class EditingPage extends StatefulWidget {
  const EditingPage({super.key, required this.documentData});

  final DocumentData documentData;

  @override
  State<EditingPage> createState() => _EditingPageState();
}

class _EditingPageState extends State<EditingPage> {
  void close() {
    Navigator.pop(context);
  }

  Widget createCustomImage() {
    var image = widget.documentData.image;
    var detectionResults = widget.documentData.documentResults;
    return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
            width: image!.width.toDouble(),
            height: image.height.toDouble(),
            child: GestureDetector(
              onPanUpdate: (details) {
                if (details.localPosition.dx < 0 ||
                    details.localPosition.dy < 0 ||
                    details.localPosition.dx > image.width ||
                    details.localPosition.dy > image.height) {
                  return;
                }

                for (int i = 0; i < detectionResults.length; i++) {
                  for (int j = 0; j < detectionResults[i].points.length; j++) {
                    if ((detectionResults[i].points[j] - details.localPosition)
                            .distance <
                        100) {
                      bool isCollided = false;
                      for (int index = 1; index < 4; index++) {
                        int otherIndex = (j + 1) % 4;
                        if ((detectionResults[i].points[otherIndex] -
                                    details.localPosition)
                                .distance <
                            20) {
                          isCollided = true;
                          return;
                        }
                      }

                      setState(() {
                        if (!isCollided) {
                          detectionResults[i].points[j] = details.localPosition;
                        }
                      });
                    }
                  }
                }
              },
              child: CustomPaint(
                painter: OverlayPainter(image, detectionResults!),
              ),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: colorMainTheme,
            title: const Text(
              'Edit Document',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SavingPage(
                          documentData: widget.documentData,
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(colorMainTheme)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.check, color: colorOrange),
                      const SizedBox(width: 4),
                      Text('Next',
                          style: TextStyle(color: colorOrange, fontSize: 22)),
                    ],
                  ),
                ),
              )
            ],
          ),
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: createCustomImage(),
              ),
              const Positioned(
                left: 122,
                right: 122,
                bottom: 28,
                child: Text('Powered by Dynamsoft',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
        ));
  }
}
