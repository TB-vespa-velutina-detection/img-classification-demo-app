import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:img_classification/helper/image_classification_helper.dart';
import 'package:img_classification/model/image_classification_option.dart';
import 'package:img_classification/model/option_enum.dart';

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
  static const String _imageNetFolder = 'assets/imageNet';
  static const String _vespaVelutinaFolder = 'assets/vespaVelutina';

  //TODO: make these more dev friendly
  ImageClassificationHelper? _imageClassificationHelper;
  Map<String, double>? _classification;
  MapEntry<String, double>? _result;

  String? _selectedPath;
  String? _predictionLabel;
  double? _predictionValue;
  File? _image;
  bool _showOverlay = false;

  @override
  void initState() {
    _imageClassificationHelper = ImageClassificationHelper();
    super.initState();
  }

  Future<void> _setClassificationModel(String folderPath) async {
    setState(() {
      _selectedPath = folderPath;
    });
    ImageClassificationOption? options;
    if (folderPath == _vespaVelutinaFolder) {
      options = ImageClassificationOption(isBinary: true, binaryThreshold: 0.5, normalizeMethod: NormalizeMethod.none); //TODO: check model range values
    } else {
      options = ImageClassificationOption(
          normalizeMethod: NormalizeMethod.zero_to_one);
    }

    await _imageClassificationHelper!.initHelper(
      modelAssetPath: '${folderPath}/model.tflite',
      labelsAssetPath: '${folderPath}/labels.txt',
      separator: folderPath == _imageNetFolder ? '\n' : ',',
      options: options,
    );
  }

  Future<void> _pickPhotoFrom(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    _processImage(pickedFile);
  }

  // Process picked image
  Future<void> _processImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      _classification =
          await _imageClassificationHelper?.inferenceImage(pickedFile.path);
      _result = (_classification!.entries.toList()
            ..sort(
              (a, b) => a.value.compareTo(b.value),
            ))
          .reversed
          .first;
      _setOverlay(pickedFile, _result);
    }
  }

  Future<void> _setOverlay(
      XFile pickedFile, MapEntry<String, double>? prediction) async {
    setState(() {
      _image = File(pickedFile.path);
      _showOverlay = true;
      _predictionLabel = prediction?.key ?? 'Unknown';
      _predictionValue = prediction?.value ?? 0.0;
      _predictionValue = _predictionValue! * 100;
    });
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
                      selected: _selectedPath == _imageNetFolder,
                      onSelected: (_) =>
                          _setClassificationModel(_imageNetFolder),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Vespa Velutina'),
                      selected: _selectedPath == _vespaVelutinaFolder,
                      onSelected: (_) =>
                          _setClassificationModel(_vespaVelutinaFolder),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickPhotoFrom(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take a picture'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickPhotoFrom(ImageSource.gallery),
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
