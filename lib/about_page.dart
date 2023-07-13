import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'global.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = Container(
      padding: const EdgeInsets.only(top: 50, left: 39, bottom: 5, right: 39),
      child: Row(
        children: [
          Image.asset(
            "images/logo-ddn.png",
            width: MediaQuery.of(context).size.width - 80,
          ),
        ],
      ),
    );

    final description = Container(
        padding: const EdgeInsets.only(left: 44, right: 39, top: 18),
        child: const Center(
          child: Text(
            'Dynamsoft Document Normalizer (DDN) is an SDK designed to detect quadrilaterals (quads for short) such as document/table boundaries and more from images, then perform document normalization on the images in the detected quads.',
            style: TextStyle(color: Colors.white, wordSpacing: 2),
            textAlign: TextAlign.center,
          ),
        ));

    final button = Container(
      padding: const EdgeInsets.only(top: 48, left: 91, right: 91, bottom: 69),
      child: MaterialButton(
        minWidth: 208,
        height: 44,
        color: colorOrange,
        onPressed: () {
          launchUrlString(
              'https://www.dynamsoft.com/document-normalizer/downloads/1000023-confirmation/');
        },
        child: const Text(
          'GET FREE TRIAL SDK',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    final links = Padding(
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width - 30,
        padding: const EdgeInsets.only(left: 20),
        decoration: const BoxDecoration(color: Colors.black),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 13, bottom: 15),
              child: InkWell(
                  onTap: () {
                    launchUrlString(
                        'https://www.dynamsoft.com/document-normalizer/docs/core/introduction/?ver=latest&ver=latest');
                  },
                  child: Text(
                    'Dynamsoft Document Normalizer overview >',
                    style: TextStyle(color: colorOrange, fontSize: 16),
                  )),
            ),
            Container(
              height: 1,
              color: colorMainTheme,
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 13,
                bottom: 15,
              ),
              child: InkWell(
                  onTap: () {
                    launchUrlString('https://www.dynamsoft.com/company/about/');
                  },
                  child: Text(
                    'Contact us >',
                    style: TextStyle(color: colorOrange, fontSize: 16),
                  )),
            ),
          ],
        ),
      ),
    );

    final version = Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        child: Container(
          width: MediaQuery.of(context).size.width - 30,
          height: 49,
          padding: const EdgeInsets.only(left: 20, right: 24),
          decoration: const BoxDecoration(color: Colors.black),
          child: Row(
            children: [
              const Text(
                'SDK Version',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Expanded(child: Container()),
              Text(
                '1.0.2',
                style: TextStyle(color: colorText, fontSize: 15),
              )
            ],
          ),
        ));
    final sourceCode = Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 1),
        child: Container(
          width: MediaQuery.of(context).size.width - 30,
          height: 49,
          padding: const EdgeInsets.only(left: 20, right: 24),
          decoration: const BoxDecoration(color: Colors.black),
          child: Row(
            children: [
              InkWell(
                  onTap: () {
                    launchUrlString(
                        'https://github.com/yushulx/flutter-document-scanner');
                  },
                  child: const Text(
                    'App Source Code >',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  )),
              Expanded(child: Container()),
            ],
          ),
        ));

    return Scaffold(
        appBar: AppBar(
          title: Text('About',
              style: TextStyle(
                fontSize: 22,
                color: colorTitle,
              )),
          centerTitle: true,
          backgroundColor: colorMainTheme,
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [title, description, button, links, version, sourceCode],
        )));
  }
}
