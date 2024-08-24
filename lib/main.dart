import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

import 'package:img_classification/helper/image_classification_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Image classification demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //TODO: make these more dev friendly
  ImageClassificationHelper? _imageClassificationHelper;
  Map<String, double>? _classification;
  MapEntry<String, double>? _result;

  String _selectedPath = 'assets/image1.png';
  String? _predictionLabel;
  double? _predictionValue;
  File? _image;
  bool _showOverlay = false;

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    // _setOverlay(pickedFile);
    _processImage(pickedFile);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // _setOverlay(pickedFile);
    _processImage(pickedFile);
  }

  // Process picked image
  Future<void> _processImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      // Read image bytes from file
      final imageData = File(pickedFile.path).readAsBytesSync();

      // Decode image using package:image/image.dart (https://pub.dev/image)
      final image = img.decodeImage(imageData);
      setState(() {});
      _classification = await _imageClassificationHelper?.inferenceImage(image!);
      _result = (_classification!.entries.toList()
            ..sort(
              (a, b) => a.value.compareTo(b.value),
            ))
          .reversed
          .first;
      _setOverlay(pickedFile, _result);
    }
  }

  Future<void> _setOverlay(XFile pickedFile, MapEntry<String, double>? prediction) async {
    setState(() {
      _image = File(pickedFile.path);
      _showOverlay = true;
      _predictionLabel = prediction?.key ?? 'Unknown';
      _predictionValue = prediction?.value ?? 0.0;
      _predictionValue = _predictionValue! * 100;
    });
  }

  @override
  void initState() {
    _imageClassificationHelper = ImageClassificationHelper();
    _imageClassificationHelper!.initHelper();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final imageHeight = screenSize.height * 0.7;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('ImageNet'),
                      selected: _selectedPath == 'assets/image1.png',
                      onSelected: (selected) {
                        setState(() {
                          _selectedPath = 'assets/image1.png';
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Vespa Velutina'),
                      selected: _selectedPath == 'assets/image2.png',
                      onSelected: (selected) {
                        setState(() {
                          _selectedPath = 'assets/image2.png';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take a picture'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text('Take from gallery'),
                ),
              ],
            ),
          ),
          if (_showOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_image != null)
                        Image.file(
                          _image!,
                          height: orientation == Orientation.portrait
                              ? imageHeight
                              : imageHeight * 0.7,
                        ),
                      const SizedBox(height: 10),
                      Text(
                        '${_predictionLabel!} ${_predictionValue} %',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _image = null;
                            _showOverlay = false;
                            _predictionLabel = null;
                            _predictionValue = null;
                          });
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
