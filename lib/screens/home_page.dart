import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  List? _outputs;
  Stopwatch stopwatch = new Stopwatch();
  var time;
  final to_mili = DateFormat('HH:mm:ss.S');
  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  // 모델과 label.txt를 가져온다.
  loadModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/labels.txt",
    ).then((value) {
      setState(() {
        //_loading = false;
      });
    });
  }

  // 비동기 처리를 통해 카메라와 갤러리에서 이미지를 가져온다.
  Future getImage(ImageSource imageSource) async {
    final image = await picker.pickImage(source: imageSource);
    setState(() {
      _image = File(image!.path); // 가져온 이미지를 _image에 저장
    });
    await classifyImage(File(image!.path)); // 가져온 이미지를 분류 하기 위해 await을 사용
  }

  // 이미지 분류
  Future classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
    );
    setState(() {
      _outputs = output;
    });
  }

  // 이미지를 보여주는 위젯
  Widget showImage() {
    return Container(
      margin: EdgeInsets.only(top: 15, left: 15, right: 15),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width,
      child: Center(
          child: _image == null
              ? Text('사진을 추가하세요.')
              : Image.file(File(_image!.path)),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xffd0cece),
      ),
    );
  }

  Widget resultsList(List? results) {
    if (results == null) {
      return Container();
    }
    return Container(
      height: 120,
      child: ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return Container(
            height: 30,
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '예측 ${index+1} : ${results[index]['label']}',
                    style: TextStyle(
                      fontSize: 18
                    )
                  ),
                  Text(
                    '정확도: ${(results[index]['confidence']! * 100).toStringAsFixed(1)} %',
                    style: TextStyle(
                      fontSize: 18
                    )
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _showBottomSheet() {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 20,
            ),
            TextButton(
              onPressed: () async {
                await getImage(ImageSource.camera);
                stopwatch.start();
                if (stopwatch.elapsed.inMilliseconds == 0) time = '0ms 미만';
                else time = stopwatch.elapsed.inMilliseconds.toString() + 'ms';
                stopwatch.stop();
              },
              child: const Text('사진 촬영'),
            ),
            const SizedBox(
              height: 10,
            ),
            const Divider(
              thickness: 3,
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () async {
                await getImage(ImageSource.gallery);
                stopwatch.start();
                if (stopwatch.elapsed.inMilliseconds == 0) time = '0ms 미만';
                else time = stopwatch.elapsed.inMilliseconds.toString() + 'ms';
                stopwatch.stop();
              },
              child: const Text('갤러리'),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 세로 고정
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Column(
                  children: [
                    showImage(),
                    SizedBox(
                      height: 15.0,
                    ),
                    resultsList(_outputs),
                  ],
                )
              ),
              Container(
                child: Column(
                  children: [
                    _outputs == null ?
                    Container() :
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(15),
                      child: Text(
                        '소요시간: ' + time,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    Container(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          FloatingActionButton(
                            child: Icon(Icons.wallpaper),
                            tooltip: 'pick Iamge',
                            onPressed: () {
                              _showBottomSheet();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        )
    );
  }

  // 앱이 종료될 때
  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}