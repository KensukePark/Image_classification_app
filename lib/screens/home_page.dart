import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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

  // 모델과 라벨을 가져오는 함수
  void loadModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/labels.txt",
    ).then((value) {
      setState(() {
        //_loading = false;
      });
    });
  }

  // 이미지를 가져와서 분류하는 함수
  Future getImage(ImageSource imageSource) async {
    final image = await picker.pickImage(source: imageSource);
    setState(() {
      _image = File(image!.path);
    });
    await classifyImage(File(image!.path));
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

  //분석 결과를 출력하여 보여줄 위젯
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

  //카메라 촬영으로 이미지를 받을 함수
  void FromCamera() async {
    await getImage(ImageSource.camera);
    stopwatch.start();
    if (stopwatch.elapsed.inMilliseconds == 0) time = '0ms 미만';
    else time = stopwatch.elapsed.inMilliseconds.toString() + 'ms';
    stopwatch.stop();
  }

  //갤러리에서 이미지를 받을 함수
  void FromGallery() async {
    await getImage(ImageSource.gallery);
    stopwatch.start();
    if (stopwatch.elapsed.inMilliseconds == 0) time = '0ms 미만';
    else time = stopwatch.elapsed.inMilliseconds.toString() + 'ms';
    stopwatch.stop();
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: EdgeInsets.only(right: 15, bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          SpeedDial(
                            backgroundColor: Colors.black,
                            icon: Icons.add,
                            children: [
                              SpeedDialChild(
                                child: Icon(Icons.photo_camera),
                                onTap: () => FromCamera(),
                              ),
                              SpeedDialChild(
                                child: Icon(Icons.wallpaper),
                                onTap: () => FromGallery(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
    );
  }
  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}

