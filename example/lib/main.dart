// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:yourinrolltoolsstream/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
}

void logError(String code, String message) =>
    print('Error.: $code\nError Message: $message');

class RtmpVideoStreamPage extends StatefulWidget {
  final int userId;
  final int pageIndex;

  const RtmpVideoStreamPage({
    required this.userId,
    required this.pageIndex,
    super.key,
  });

  @override
  State<RtmpVideoStreamPage> createState() => _RtmpVideoStreamPageState();
}

class _RtmpVideoStreamPageState extends State<RtmpVideoStreamPage> {
  WebSocketChannel? _channel;

  CameraController? controller;
  String? imagePath;
  String? videoPath;
  String? url;

  VideoPlayerController? videoController;
  late VoidCallback videoPlayerListener;

  bool enableAudio = true;
  bool useOpenGL = true;
  String streamURL = "";
  String decodedStreamKey = '';
  bool streaming = false;

  String? cameraDirection;

  late String userName;
  late String dateRegisteredUser;

  Timer? _timer;
  Timer? _timerForCheckBroadcastStatus;

  String? token;
  String? streamId;

  bool isLoaded = false;
  bool broadcastError = false;

  String views = '';

  List<CameraDescription> cameras = [];

  // Future<void> _saveToSharedPrefs(String key, String value) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setString(key, value);
  // }

  void getCameras() async {
    await Future.delayed(const Duration(milliseconds: 1))
        .whenComplete(() async {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        cameras = await availableCameras();
        _initialize();
      } on CameraException catch (e) {
        logError(e.code, e.description);
      }
    });
  }

  void checkViews() {
    Map<String, dynamic> myJson = {};

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://35.224.171.186:8081'),
    );
    myJson = {
      'api': 'check_views',
      'stream_id': streamId!,
    };
    _channel?.sink.add(jsonEncode(myJson));
    _channel?.stream.listen((message) {
      if (message != '{}') {
        var jsonData = jsonDecode(message);
        var val = jsonData['viewers'].toString();
        setState(() {
          views = val;
        });
      }
    });
  }

  void getViews() async {
    Uri url = Uri.parse(
        'https://youinroll.com/lib/ajax/conference/getStreamViews.php?stream_id=$streamId');
    Response response = await get(url);

    if (response.statusCode >= 200 && response.statusCode < 400) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        views = jsonResponse['result'].toString();
      });
    }
  }

  void getUserToken() async {
    // final prefs = await SharedPreferences.getInstance();
    token =
    '004e6cff74730832deb820d0aee6dd0fc004f5f10ddffe7bb37dc31eceb45e1eeb1b3f14fd5c00e42b575ebbd04fa0bd8d28fdab602f04b80c375aaddd5306ee';
  }

  String generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  checkBroadcastStatus() async {
    Future.delayed(const Duration(seconds: 20), () {
      _timerForCheckBroadcastStatus =
          Timer.periodic(const Duration(seconds: 10), (_) {
            getBroadcastStatus();
          });
    });
  }

  getBroadcastStatus() async {
    try {
      if (!controller!.value.isStreamingVideoRtmp) {
        showInSnackBar('error, ${controller!.value.isStreamingVideoRtmp}');
        if (streaming) {
          onStopButtonPressed();
        }
        setState(() {
          broadcastError = true;
        });
        _timerForCheckBroadcastStatus?.cancel();
        return;
      }

      Uri url = Uri.parse(
          "https://youinroll.com:8443/hls/${decodedStreamKey}_360p878kbs/index.m3u8");
      Response response = await get(url);
      if (response.statusCode == 404) {
        if (streaming) {
          onStopButtonPressed();
          showInSnackBar('404 code, $url');
        }
        setState(() {
          broadcastError = true;
        });
        _timerForCheckBroadcastStatus?.cancel();
      }
    } catch (e) {
      return;
    }
  }

  @override
  void initState() {
    getCameras();
    getUserToken();
    loadUserData();
    loadUserDataDop();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    if (streaming) {
      disposeScreen();
    }
    if (_timerForCheckBroadcastStatus != null) {
      _timerForCheckBroadcastStatus?.cancel();
    }
    if (_channel != null) {
      _channel?.sink.close();
    }
    if (controller != null) {
      controller?.dispose();
    }
    availableCameras().ignore();
    cameras.clear();
    Wakelock.disable();
    super.dispose();
  }

  void loadUserData() async {
    Uri url = Uri.parse(
        'https://youinroll.com/profile/${widget.userId}/info?api=v1.1');
    Response response = await get(url);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        var userData = jsonResponse['response'];
        var streamKey = userData['chatRoom'].toString();
        userName = userData['name'].toString();
        userAvatar = userData['avatar'].toString();
        userBio = userData['bio'].toString();
        dateRegisteredUser = userData['date_registered'].toString();
        decodedStreamKey = generateMd5(streamKey);
        if (decodedStreamKey.isNotEmpty) {
          // StaticVariables.decodedStreamKey = decodedStreamKey;
          // _saveToSharedPrefs('decodedStreamKey', decodedStreamKey);
        }
        streamURL = "rtmp://youinroll.com:1935/stream/$decodedStreamKey";
      });
    }
  }

  String userFollowers = '';
  String userViews = '';
  String userLikes = '';
  String userAvatar = '';
  String userBio = '';

  void loadUserDataDop() async {
    Uri url = Uri.parse(
        'https://youinroll.com/lib/ajax/getPopularity.php?user_id=${widget.userId}');
    Response response = await get(url);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      userFollowers = jsonResponse['followers'];
      userViews = jsonResponse['views'];
      userLikes = jsonResponse['likes'];
    }
  }

  Future<void> _initialize() async {
    streaming = false;
    cameraDirection = 'front';
    //controller = CameraController(cameras[0], ResolutionPreset.high);
    if (controller != null) {
      await controller?.dispose();
    }
    controller = CameraController(
      cameras[1],
      ResolutionPreset.high,
      enableAudio: enableAudio,
      androidUseOpenGL: useOpenGL,
      streamingPreset: ResolutionPreset.high,
    );
    await controller!.initialize().whenComplete(() {
      if (mounted) {
        setState(() {
          isLoaded = true;
        });
      }
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null) {
      return;
    } else if (!controller!.value.isInitialized!) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller!.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  toggleCameraDirection() async {
    if (cameraDirection == 'front') {
      if (controller != null) {
        await controller?.dispose();
      }
      controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: enableAudio,
        androidUseOpenGL: useOpenGL,
      );

      // If the controller is updated then update the UI.
      controller!.addListener(() {
        if (mounted) setState(() {});
        if (controller!.value.hasError) {
          showInSnackBar('Camera error ${controller!.value.errorDescription}');
          if (_timer != null) {
            _timer!.cancel();
            _timer = null;
          }
          if (streaming) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => RootApp(
            //       pageIndex: widget.pageIndex,
            //     ),
            //   ),
            // );
          }
        }
      });

      try {
        await controller!.initialize();
      } on CameraException catch (e) {
        _showCameraException(e);
      }

      if (mounted) {
        setState(() {});
      }
      cameraDirection = 'back';
    } else {
      if (controller != null) {
        await controller!.dispose();
      }
      controller = CameraController(
        cameras[1],
        ResolutionPreset.high,
        enableAudio: enableAudio,
        androidUseOpenGL: useOpenGL,
      );

      // If the controller is updated then update the UI.
      controller!.addListener(() {
        if (mounted) setState(() {});
        if (controller!.value.hasError) {
          showInSnackBar('Camera error ${controller!.value.errorDescription}');
          if (_timer != null) {
            _timer!.cancel();
            _timer = null;
          }
          if (streaming) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => RootApp(
            //       pageIndex: widget.pageIndex,
            //     ),
            //   ),
            // );
          }
        }
      });

      try {
        await controller!.initialize();
      } on CameraException catch (e) {
        _showCameraException(e);
      }

      if (mounted) {
        setState(() {});
      }
      cameraDirection = 'front';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black.withOpacity(0.5),
        leading: streaming
            ? null
            : IconButton(
          icon: const Icon(
            Icons.settings,
            color: Colors.white,
          ),
          onPressed: () {
            // showDialog(
            //   context: context,
            //   builder: (BuildContext context) {
            //     return Dialog(
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(20.0),
            //       ),
            //       child: Container(
            //         constraints: const BoxConstraints(maxHeight: 500),
            //         child: SettingBroadcastModal(
            //           token: token!,
            //         ),
            //       ),
            //     );
            //   },
            // );
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                if (streaming) {
                  delStream();
                }
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => RootApp(
                //       pageIndex: widget.pageIndex,
                //     ),
                //   ),
                // );

              },
              icon: const Icon(Icons.close)),
        ],
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      body: WillPopScope(
        onWillPop: () async => false,
        child: SingleChildScrollView(
          child: broadcastError
              ? _broadcastErrorWidget()
              : SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: <Widget>[
                Container(
                  color: Colors.black,
                  child: Center(
                    child: _cameraPreviewWidget(),
                  ),
                ),
                // if(streaming)
                //
                !streaming
                    ? Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 90, right: 20),
                    child: IconButton(
                      color: Colors.white38.withOpacity(0.3),
                      icon: const Icon(Icons.flip_camera_android),
                      alignment: Alignment.topRight,
                      iconSize: 40.0,
                      // tooltip: switchCameraTr.trText,
                      onPressed: () {
                        toggleCameraDirection();
                      },
                    ),
                  ),
                )
                    : Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding:
                    const EdgeInsets.only(top: 120, right: 20),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(right: 5),
                            child: Container(
                              padding: const EdgeInsets.only(
                                  right: 7, left: 7),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFE2C55),
                                borderRadius: BorderRadius.all(
                                    Radius.circular(6.0)),
                              ),
                              child: Text(
                                // liveTr.trText,
                                'LIVE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            // TTkIcons.profile,
                            Icons.people,
                            color: Colors.white,
                          ),
                          Text(
                            views,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 24,
                            ),
                          ),
                        ]),
                  ),
                ),
                streaming
                    ? Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 60, right: 20),
                      child: RawMaterialButton(
                        onPressed: () {
                          // Vibration.vibrate(
                          //   duration: 200,
                          //   amplitude: 1,
                          // );
                          onStopButtonPressed();
                        },
                        elevation: 2.0,
                        fillColor: const Color(0xFFFE2C55),
                        padding: const EdgeInsets.all(15.0),
                        shape: const CircleBorder(),
                        //Colors.white.withAlpha(60),
                        child: const Icon(
                          Icons.stop,
                          size: 35.0,
                          color: Colors.white,
                        ),
                      )),
                )
                    : Align(
                  alignment: Alignment.center,
                  child: isLoaded
                      ? RawMaterialButton(
                    onPressed: () {
                      // Vibration.vibrate(
                      //   duration: 200,
                      //   amplitude: 1,
                      // );
                      onVideoStreamingButtonPressed();
                    },
                    elevation: 2.0,
                    fillColor: const Color(0xFFFE2C55),
                    padding: const EdgeInsets.all(15.0),
                    shape: const CircleBorder(),
                    //Colors.white.withAlpha(60),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 35.0,
                      color: Colors.white,
                    ),
                  )
                      : const CupertinoActivityIndicator(),
                ),
                streaming
                    ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    width: 280,
                    height: 400,
                    color: Colors.transparent,
                    child: Container(),
                    // child: StreamChat(
                    //   user_id: widget.userId.toString(),
                    //   user_name: userName,
                    //   date_registered_user: dateRegisteredUser,
                    //   token: token!,
                    //   streamId: streamId!,
                    //   followers: userFollowers,
                    //   views: userViews,
                    //   likes: userLikes,
                    //   user_avatar: userAvatar,
                    //   userBio: userBio,
                    //   isBroadcastCreator: true,
                    // ),
                  ),
                )
                    : const SizedBox(),
                streaming
                    ? const SizedBox()
                    : Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              if (controller != null) {
                                controller?.dispose();
                              }
                              // Vibration.vibrate(
                              //   duration: 200,
                              //   amplitude: 1,
                              // );
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         PostScreenFromGallery(
                              //       userId: widget.userId,
                              //       myPageIndex: widget.pageIndex,
                              //     ),
                              //   ),
                              // );
                            },
                            child: Text(
                              // kpostTr.trText,
                              'POST',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            // liveTr.trText,
                            'LIVE',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 20),
                          InkWell(
                            onTap: () {
                              if (controller != null) {
                                controller?.dispose();
                              }
                              // Vibration.vibrate(
                              //   duration: 200,
                              //   amplitude: 1,
                              // );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Here was push to GetVideoPage',
                                  ),
                                ),
                              );
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         GetVideoPage(
                              //       user_id: widget.user_id,
                              //       myPageIndex: widget.page_index,
                              //       userHasStream: true,
                              //     ),
                              //   ),
                              // );
                            },
                            child: Text(
                              // cameraTr.trText,
                              'CAMERA',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  ?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _broadcastErrorWidget() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Blur(
          //   colorOpacity: 0.85,
          //   blur: 30,
          //   blurColor: Colors.black,
          //   child: Container(
          //     color: Colors.black,
          //     child: Center(
          //       child: _cameraPreviewWidget(),
          //     ),
          //   ),
          // ),
          Center(
            child: RawMaterialButton(
              onPressed: () {
                // Vibration.vibrate(
                //   duration: 200,
                //   amplitude: 1,
                // );
                onVideoStreamingButtonPressed();
                setState(() {
                  broadcastError = false;
                  streaming = true;
                });
              },
              elevation: 2.0,
              fillColor: const Color(0xFFFE2C55),
              padding: const EdgeInsets.all(15.0),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.autorenew,
                size: 35.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null) {
      return const CupertinoActivityIndicator();
    } else if (!controller!.value.isInitialized!) {
      return const CupertinoActivityIndicator();
    } else {
      if (isLoaded) {
        return AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          // aspectRatio: size.height / size.width,
          child: CameraPreview(controller!),
        );
      } else {
        return const CupertinoActivityIndicator();
      }
    }
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    controller = CameraController(
      cameraDescription!,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      androidUseOpenGL: useOpenGL,
    );

    // If the controller is updated then update the UI.
    controller!.addListener(() {
      if (mounted) setState(() {});
      if (controller!.value.hasError) {
        showInSnackBar('CAMERA ERROR: ${controller!.value.errorDescription}');
        if (_timer != null) {
          _timer!.cancel();
          _timer = null;
        }
        Wakelock.disable();
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onVideoStreamingButtonPressed() {
    startVideoStreaming().then((url) {
      if (mounted) {
        setState(() {
          // streaming = true;
        });
      }
    });
    pushStream();
    Wakelock.enable();
  }

  void onStopButtonPressed() {
    _timerForCheckBroadcastStatus?.cancel();
    stopVideoStreaming().then((_) {
      showInSnackBar(
        // broadcastSavedTr.trText,
        'Broadcast saved',
      );
    });
    try {
      delStream();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    Wakelock.disable();
  }

  void onPauseStreamingButtonPressed() {
    pauseVideoStreaming().then(
          (_) {
        if (mounted) setState(() {});
        showInSnackBar(
          // streamingPausedTr.trText,
          'Streaming paused',
        );
      },
    );
  }

  void onResumeStreamingButtonPressed() {
    resumeVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar(
        'Streaming resumed',
      );
    });
  }

  Future<String?> startVideoStreaming() async {
    if (!controller!.value.isInitialized!) {
      showInSnackBar(
        'Camera error message',
      );
      return null;
    }

    // Open up a dialog for the url
    String myUrl = streamURL;

    try {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
      }
      url = myUrl;
      int wid = MediaQuery.of(context).size.width.round();
      int hei = MediaQuery.of(context).size.height.round();
      if (!wid.isEven) {
        wid++;
      }
      if (!hei.isEven) {
        hei++;
      }
      String a = '${url!}?${hei}x$wid';
      await controller!.startVideoStreaming(a, androidUseOpenGL: useOpenGL);
      checkBroadcastStatus();
    } on CameraException catch (e) {
      _showCameraException(e);
      if (streaming) {
        delStream();
      }
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => RootApp(
      //       pageIndex: widget.pageIndex,
      //     ),
      //   ),
      // );
      return null;
    }
    return url;
  }

  Future<void> stopVideoStreaming() async {
    try {
      await controller!.stopVideoStreaming();
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
      }
    } on CameraException catch (e, s) {
      print('EXCEPTION OCCURRED: $e');
      print('TRACE: $s');
      _showCameraException(e);
      return;
    }
  }

  Future<void> pauseVideoStreaming() async {
    if (!controller!.value.isStreamingVideoRtmp) {
      return;
    }
    try {
      await controller!.pauseVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoStreaming() async {
    try {
      await controller!.resumeVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    try {
      logError(e.code, e.description);
      showInSnackBar('Error: ${e.code}\n${e.description}');
    } catch (e) {
      return;
    }
  }

  void pushStream() async {
    bool isFrontCam = false;
    if (cameraDirection == 'front') {
      isFrontCam = true;
    }
    var padding = MediaQuery.of(context).padding;
    double height =
        MediaQuery.of(context).size.height - padding.top - padding.bottom;
    String os = Platform.operatingSystem;
    Uri url =
    Uri.parse('https://youinroll.com/lib/ajax/conference/beginStream.php');
    Response response = await post(url, body: {
      'token': token,
      'platform': os,
      'height': height.toString(),
      'width': MediaQuery.of(context).size.width.toString(),
      'is_front_camera': isFrontCam ? '1' : '0',
    });

    if (response.statusCode >= 200 && response.statusCode < 400) {
      var jsonData = jsonDecode(response.body);
      streamId = jsonData['stream_id'].toString();
      getViews();
      checkViews();
      setState(() {
        streaming = true;
      });
    }
  }

  void delStream() async {
    Uri url =
    Uri.parse('https://youinroll.com/lib/ajax/conference/stopStream.php');
    await post(url, body: {
      'token': token,
    });
    if (mounted) {
      setState(() {
        streaming = false;
      });
    }
  }

  void disposeScreen() async {
    if (controller!.value.isInitialized!) {
      await controller?.stopVideoStreaming();
    }
    if (controller != null) {
      controller?.dispose();
    }
    Uri url =
    Uri.parse('https://youinroll.com/lib/ajax/conference/stopStream.php');
    await post(url, body: {
      'token': token,
    });
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RtmpVideoStreamPage(
        userId: 3310,
        pageIndex: 1,
      ),
    );
  }
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(CameraApp());
}