//import 'dart:io';
//import 'package:image_cropper/image_cropper.dart';
//import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';
//import 'package:firebase_ml_vision/firebase_ml_vision.dart';
//
//void main() {
//  runApp(MyApp());
//}
//
//class MyApp extends StatelessWidget {
//  // This widget is the root of your application.
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: MyHomePage(),
//    );
//  }
//}
//
//class MyHomePage extends StatefulWidget {
//  @override
//  _MyHomePageState createState() => _MyHomePageState();
//}
//
//class _MyHomePageState extends State<MyHomePage> {
//  File pickedImage;
//  bool isImageLoad = false;
//  Future pickImage() async {
//    var tempStore = await ImagePicker.pickImage(source: ImageSource.gallery);
//    setState(() {
//      pickedImage = tempStore;
//      isImageLoad = true;
//    });
//  }
//

//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Text Scanner'),
//      ),
//      body: Column(
//        children: <Widget>[
//          isImageLoad
//              ? Center(
//                  child: Container(
//                    height: 300,
//                    width: 300,
//                    decoration: BoxDecoration(
//                      image: DecorationImage(
//                          image: FileImage(pickedImage), fit: BoxFit.cover),
//                    ),
//                  ),
//                )
//              : Container(),
//          SizedBox(
//            height: 10,
//          ),
//          RaisedButton(
//            child: Text('Pick an Image'),
//            onPressed: pickImage,
//          ),
//          SizedBox(
//            height: 10,
//          ),
//          RaisedButton(
//            child: Text('Read Text'),
//            onPressed: readText,
//          ),
//          SizedBox(
//            height: 5,
//          ),
//          TextField(
//            decoration: InputDecoration(
//              border: InputBorder.none,
//              hintText: 'Enter a search term',
//            ),
//          ),
//        ],
//      ),
//    );
//  }
//}

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: MaterialApp(
        title: 'Link Scanner',
        theme: ThemeData.light().copyWith(primaryColor: Colors.teal),
        home: Center(
          child: MyHomePage(
            title: 'Link Scanner',
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum AppState {
  free,
  picked,
  cropped,
  predict,
}

class _MyHomePageState extends State<MyHomePage> {
  AppState state;
  File imageFile;

  @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  String res = 'Recognized text will appear here';
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: imageFile != null
                  ? Image.file(imageFile)
                  : Icon(
                      Icons.image,
                      size: 100,
                    ),
            ),
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 30),
                child: Divider(
                  color: Colors.teal,
                  height: 5,
                  thickness: 2,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Linkify(
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      throw 'Could not launch $link';
                    }
                  },
                  text: res,
                  style: TextStyle(color: Colors.black, fontSize: 18),
                  linkStyle: TextStyle(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.teal,
          onPressed: () async {
            if (state == AppState.free) {
              await _pickImage();
              await _cropImage();
              await readText();
            } else if (state == AppState.predict) _clearImage();
          },
          child: _buildButtonIcon(),
        ),
      ),
    );
  }

  Widget _buildButtonIcon() {
    if (state == AppState.free)
      return Icon(Icons.add);
    else if (state == AppState.picked)
      return Icon(Icons.crop);
    else if (state == AppState.cropped)
      return Icon(Icons.text_fields);
    else if (state == AppState.predict)
      return Icon(Icons.clear);
    else
      return Container();
  }

  Future<Null> _pickImage() async {
    // ignore: deprecated_member_use
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        state = AppState.picked;
      });
    }
  }

  Future<Null> _cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      imageFile = croppedFile;
      setState(() {
        state = AppState.cropped;
      });
    }
  }

  Future readText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(imageFile);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    //print(readText.text);

    setState(() {
      res = readText.text;
      state = AppState.predict;
    });
  }

  void _clearImage() {
    imageFile = null;
    setState(() {
      state = AppState.free;
      res = 'Recognized Text will appear here!!';
    });
  }
}
