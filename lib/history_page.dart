import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'global.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoaded = false;
  final List<Uint8List> _documentHistory =
      List<Uint8List>.empty(growable: true);
  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getStringList('document_data');
    if (data != null) {
      _documentHistory.clear();
      for (String imageString in data) {
        _documentHistory.add(decodeImageFromBase64(imageString));
      }
    }
    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var listView = Expanded(
        child: ListView.builder(
            itemCount: _documentHistory.length,
            itemBuilder: (context, index) {
              return MyCustomWidget(
                  result: _documentHistory[index],
                  cbDeleted: () async {
                    _documentHistory.removeAt(index);
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    List<String> data =
                        prefs.getStringList('document_data') as List<String>;
                    data.removeAt(index);
                    prefs.setStringList('document_data', data);
                    setState(() {});
                  },
                  cbOpenResultPage: () {});
            }));
    return Scaffold(
      appBar: AppBar(
        title: Text('History',
            style: TextStyle(
              fontSize: 22,
              color: colorTitle,
            )),
        centerTitle: true,
        backgroundColor: colorMainTheme,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 30),
              child: IconButton(
                onPressed: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('document_data');
                  setState(() {
                    _documentHistory.clear();
                  });
                },
                icon: Image.asset(
                  "images/icon-delete.png",
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ))
        ],
      ),
      body: _isLoaded
          ? Column(
              children: [listView],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class MyCustomWidget extends StatelessWidget {
  final Uint8List result;
  final Function cbDeleted;
  final Function cbOpenResultPage;

  const MyCustomWidget({
    super.key,
    required this.result,
    required this.cbDeleted,
    required this.cbOpenResultPage,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 16, left: 30),
            child: Row(
              children: [
                SizedBox(
                    width: 100.0,
                    height: 100.0,
                    child: Image.memory(
                      result,
                      fit: BoxFit.contain,
                    )),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: Colors.white,
                    onPressed: () async {
                      final RenderBox button =
                          context.findRenderObject() as RenderBox;

                      final RelativeRect position = RelativeRect.fromLTRB(
                        100,
                        button.localToGlobal(Offset.zero).dy,
                        40,
                        0,
                      );

                      final selected = await showMenu(
                        context: context,
                        position: position,
                        color: colorBackground,
                        items: [
                          const PopupMenuItem<int>(
                              value: 0,
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              )),
                          const PopupMenuItem<int>(
                              value: 1,
                              child: Text(
                                'Share',
                                style: TextStyle(color: Colors.white),
                              )),
                        ],
                      );

                      if (selected != null) {
                        if (selected == 0) {
                          // delete
                          cbDeleted();
                        } else if (selected == 1) {
                          // share
                          final XFile xFile = XFile.fromData(
                            result,
                            mimeType: 'image/png',
                            name: 'image.png',
                          );
                          Share.shareXFiles([xFile], text: 'Image Shared');
                        }
                      }
                    },
                  ),
                ),
              ],
            )));
  }
}
