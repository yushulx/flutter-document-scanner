import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';

class EditingPage extends StatefulWidget {
  const EditingPage({super.key, required this.documentResults});

  final List<DocumentResult> documentResults;

  @override
  State<EditingPage> createState() => _EditingPageState();
}

class _EditingPageState extends State<EditingPage> {
  void close() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(color: Colors.white, fontSize: 14);
    var count = Container(
      padding: const EdgeInsets.only(left: 16, top: 14, bottom: 15),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          const Text('Total:', style: valueStyle),
          Text('${widget.documentResults.length}',
              style: TextStyle(color: colorGreen, fontSize: 14))
        ],
      ),
    );
    final resultList = Expanded(
        child: ListView.builder(
            itemCount: widget.documentResults.length,
            itemBuilder: (context, index) {
              return MyCustomWidget(
                index: index,
                result: widget.documentResults[index],
              );
            }));

    final button = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            padding: const EdgeInsets.only(bottom: 23),
            child: MaterialButton(
              minWidth: 208,
              height: 45,
              onPressed: () async {
                // final SharedPreferences prefs =
                //     await SharedPreferences.getInstance();
                // var results = prefs.getStringList('barcode_data');
                // List<String> jsonList = <String>[];
                // for (BarcodeResult result in widget.documentResults) {
                //   jsonList.add(jsonEncode(result.toJson()));
                // }
                // if (results == null) {
                //   prefs.setStringList('barcode_data', jsonList);
                // } else {
                //   results.addAll(jsonList);
                //   prefs.setStringList('barcode_data', results);
                // }

                // close();
              },
              color: colorOrange,
              child: const Text(
                'Save and Continue',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ))
      ],
    );

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
                child: IconButton(
                  onPressed: () {
                    // String result = '';
                    // for (BarcodeResult barcodeResult in widget.documentResults) {
                    //   result +=
                    //       'Format: ${barcodeResult.format}, Text: ${barcodeResult.text}\n';
                    // }
                    // Share.share(result);
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                ),
              )
            ],
          ),
          body: Column(
            children: [
              count,
              resultList,
              Expanded(
                child: Container(),
              ),
              button
            ],
          ),
        ));
  }
}

class MyCustomWidget extends StatelessWidget {
  final DocumentResult result;
  final int index;

  const MyCustomWidget({
    super.key,
    required this.index,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Padding(
            padding:
                const EdgeInsets.only(top: 13, bottom: 14, left: 20, right: 19),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(color: colorGreen, fontSize: 14),
                ),
                const SizedBox(width: 14),
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       'Format: ${result.format}',
                //       style: const TextStyle(
                //           color: Colors.white,
                //           fontSize: 14,
                //           overflow: TextOverflow.ellipsis),
                //     ),
                //     SizedBox(
                //       width: MediaQuery.of(context).size.width - 110,
                //       child: Text(
                //         'Text: ${result.text}',
                //         style: const TextStyle(
                //             color: Colors.white,
                //             fontSize: 14,
                //             overflow: TextOverflow.ellipsis),
                //       ),
                //     ),
                //   ],
                // ),
                Expanded(child: Container()),
                InkWell(
                  onTap: () {
                    // Clipboard.setData(ClipboardData(
                    //     text:
                    //         'Format: ${result.format}, Text: ${result.text}'));
                  },
                  child: Text('Copy',
                      style: TextStyle(color: colorGreen, fontSize: 14)),
                ),
              ],
            )));
  }
}
