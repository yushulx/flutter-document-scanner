# Flutter Document Scanner

A Flutter project that demonstrates how to use [Dynamsoft Document Normalizer](https://www.dynamsoft.com/document-normalizer/docs/core/introduction/?ver=latest&ver=latest) to rectify and enhance document images on Android, iOS, Windows, Linux, and web.

## Demo Video
https://github.com/yushulx/flutter-document-scanner/assets/2202306/cdcb4fd9-c1c9-44ac-bc67-2d02e4739523

## Supported Platforms
- **Web**
- **Android**
- **iOS**
- **Windows**
- **Linux** (Without camera support)

## Getting Started
1. Apply for a [30-day trial license](https://www.dynamsoft.com/customer/license/trialLicense/?product=ddn) and replace the license key in the `global.dart` file with your own:

    ```dart
    Future<int> initDocumentSDK() async {
        int? ret = await docScanner.init(
            'LICENSE-KEY');
        if (ret == 0) isLicenseValid = true;
        await docScanner.setParameters(Template.color);
        return ret ?? -1;
    }
    ```

2. Run the project:

    ```
    flutter run
    # flutter run -d windows
    # flutter run -d edge
    # flutter run -d linux
    ```
## Known Issues
The rectified images are converted to base64 strings and saved with [shared_preferences](https://pub.dev/packages/shared_preferences). When the total size of the images you're trying to save exceeds the size limitation of web local storage (typically around 5MB), it can lead to issues such as the app crashing or unexpected behavior.

![web local storage size limitation](https://www.dynamsoft.com/codepool/img/2023/07/flutter-web-local-storage-limitation.png)

## Try Online Demo
https://yushulx.me/flutter-document-scanner/
