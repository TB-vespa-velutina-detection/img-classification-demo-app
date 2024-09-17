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
  static const String _imageNetQuantFolder = 'assets/imageNetQuant';
  static const String _vespaVelutinaFolder = 'assets/vespaVelutina';

  ImageClassificationHelper? _imageClassificationHelper;
  Map<String, double>? _classification;
  MapEntry<String, double>? _result;

  String? _selectedPath;
  String? _predictionLabel;
  double? _predictionValue;
  File? _image;
  bool _showOverlay = false;

  int _numThreads = 1;
  bool _useGPU = false;
  bool _useXNNPack = false;
  double _binaryThreshold = 0.5;
  NormalizeMethod _normalizeMethod = NormalizeMethod.none;

  @override
  void initState() {
    _imageClassificationHelper = ImageClassificationHelper();
    super.initState();
  }

  Future<void> _setClassificationModel(String folderPath) async {
    setState(() {
      _selectedPath = folderPath;
    });
    // Close the Interpreter Isolate of previous model
    if (_imageClassificationHelper != null) {
      _imageClassificationHelper!.close();
      await _resetOptions();
    }
    ;

    ImageClassificationOption? options;
    var separator = '\n';
    if (folderPath == _vespaVelutinaFolder) {
      separator = ',';
      options = ImageClassificationOption(
          isBinary: true,
          binaryThreshold: _binaryThreshold,
          normalizeMethod: NormalizeMethod.none);
    } else if (folderPath == _imageNetFolder) {
      options = ImageClassificationOption(
          normalizeMethod: NormalizeMethod.zero_to_one);
    } else {
      options = ImageClassificationOption();
    }

    await _imageClassificationHelper!.initHelper(
      modelAssetPath: '${folderPath}/model.tflite',
      labelsAssetPath: '${folderPath}/labels.txt',
      separator: separator,
      options: options,
    );
  }

  Future<void> _resetOptions() async {
    _numThreads = 1;
    _useGPU = false;
    _useXNNPack = false;
    _binaryThreshold = 0.5;
    _normalizeMethod = NormalizeMethod.none;
  }

  Future<void> _reloadModel() async {
    await _imageClassificationHelper!.changeOptions(
      ImageClassificationOption(
        numThreads: _numThreads,
        useGpu: _useGPU,
        useXnnPack: _useXNNPack,
        normalizeMethod: _normalizeMethod,
        isBinary: _selectedPath == _vespaVelutinaFolder,
        binaryThreshold: _binaryThreshold,
      ),
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
                      label: const Text('ImageNet Quant'),
                      selected: _selectedPath == _imageNetQuantFolder,
                      onSelected: (_) =>
                          _setClassificationModel(_imageNetQuantFolder),
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
                // Number of threads
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Number of threads: '),
                    DropdownButton<int>(
                      value: _numThreads,
                      items: List.generate(8, (index) => index + 1)
                          .map((e) => DropdownMenuItem<int>(
                                value: e,
                                child: Text(e.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _numThreads = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Normalization method: '),
                    DropdownButton<NormalizeMethod>(
                      value: _normalizeMethod,
                      items: NormalizeMethod.values
                          .map((e) => DropdownMenuItem<NormalizeMethod>(
                                value: e,
                                child: Text(e.toString().split('.').last),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _normalizeMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // GPU checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('GPU: '),
                    Checkbox(
                      value: _useGPU,
                      onChanged: (value) {
                        setState(() {
                          _useGPU = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // XNNPack checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('XNNPack: '),
                    Checkbox(
                      value: _useXNNPack,
                      onChanged: (value) {
                        setState(() {
                          _useXNNPack = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedPath == _vespaVelutinaFolder)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Binary threshold: '),
                      DropdownButton<double>(
                        value: _binaryThreshold,
                        items: List.generate(11, (index) => index * 0.1)
                            .map((e) => DropdownMenuItem<double>(
                                  value: e,
                                  child: Text(e.toStringAsFixed(1)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _binaryThreshold = value!;
                          });
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed:
                      _selectedPath == null ? null : () => _reloadModel(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload Model'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _selectedPath == null
                      ? null
                      : () => _pickPhotoFrom(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take a picture'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _selectedPath == null
                      ? null
                      : () => _pickPhotoFrom(ImageSource.gallery),
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
