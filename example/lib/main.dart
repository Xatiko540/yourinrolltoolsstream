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

// class CameraExampleHome extends StatefulWidget {
//   @override
//   _CameraExampleHomeState createState() {
//     return _CameraExampleHomeState();
//   }
// }

// class _CameraExampleHomeState extends State<CameraExampleHome>
//     with WidgetsBindingObserver {
//   CameraController controller;
//   String imagePath;
//   String videoPath;
//   String url;
//   VideoPlayerController videoController;
//   VoidCallback videoPlayerListener;
//   bool enableAudio = true;
//   bool useOpenGL = true;
//   TextEditingController _textFieldController =
//       TextEditingController(text: "rtmp://192.168.68.116/live/your_stream");
//
//   bool get isStreaming => controller?.value?.isStreamingVideoRtmp ?? false;
//   bool isVisible = true;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     Wakelock.disable();
//     super.dispose();
//   }
//
//   @override
//   Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
//     // App state changed before we got the chance to initialize.
//     if (controller == null || !controller.value.isInitialized) {
//       return;
//     }
//     if (state == AppLifecycleState.paused) {
//       isVisible = false;
//       if(isStreaming) {
//         await pauseVideoStreaming();
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       isVisible = true;
//       if (controller != null) {
//         if(isStreaming) {
//           await resumeVideoStreaming();
//         } else {
//           onNewCameraSelected(controller.description);
//         }
//
//       }
//     }
//   }
//
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   ////////////var showSnackBar;
//   //(){
//
//  // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: const Text('Camera example'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: Container(
//               child: Padding(
//                 padding: const EdgeInsets.all(1.0),
//                 child: Center(
//                   child: _cameraPreviewWidget(),
//                 ),
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 border: Border.all(
//                   color: controller != null && controller.value.isRecordingVideo
//                       ? controller.value.isStreamingVideoRtmp
//                           ? Colors.redAccent
//                           : Colors.orangeAccent
//                       : controller != null &&
//                               controller.value.isStreamingVideoRtmp
//                           ? Colors.blueAccent
//                           : Colors.grey,
//                   width: 3.0,
//                 ),
//               ),
//             ),
//           ),
//           _captureControlRowWidget(),
//           _toggleAudioWidget(),
//           Padding(
//             padding: const EdgeInsets.all(5.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: <Widget>[
//                 _cameraTogglesRowWidget(),
//                 _thumbnailWidget(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Display the preview from the camera (or a message if the preview is not available).
//   Widget _cameraPreviewWidget() {
//     if (controller == null || !controller.value.isInitialized) {
//       return const Text(
//         'Tap a camera',
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 24.0,
//           fontWeight: FontWeight.w900,
//         ),
//       );
//     } else {
//       return AspectRatio(
//         aspectRatio: controller.value.aspectRatio,
//         child: CameraPreview(controller),
//       );
//     }
//   }
//
//   /// Toggle recording audio
//   Widget _toggleAudioWidget() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 25),
//       child: Row(
//         children: <Widget>[
//           const Text('Enable Audio:'),
//           Switch(
//             value: enableAudio,
//             onChanged: (bool value) {
//               enableAudio = value;
//               if (controller != null) {
//                 onNewCameraSelected(controller.description);
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Display the thumbnail of the captured image or video.
//   Widget _thumbnailWidget() {
//     return Expanded(
//       child: Align(
//         alignment: Alignment.centerRight,
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             videoController == null && imagePath == null
//                 ? Container()
//                 : SizedBox(
//                     child: (videoController == null)
//                         ? Image.file(File(imagePath))
//                         : Container(
//                             child: Center(
//                               child: AspectRatio(
//                                   aspectRatio:
//                                       videoController.value.size != null
//                                           ? videoController.value.aspectRatio
//                                           : 1.0,
//                                   child: VideoPlayer(videoController)),
//                             ),
//                             decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.pink)),
//                           ),
//                     width: 64.0,
//                     height: 64.0,
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Display the control bar with buttons to take pictures and record videos.
//   Widget _captureControlRowWidget() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       mainAxisSize: MainAxisSize.max,
//       children: <Widget>[
//         IconButton(
//           icon: const Icon(Icons.camera_alt),
//           color: Colors.blue,
//           onPressed: controller != null && controller.value.isInitialized
//               ? onTakePictureButtonPressed
//               : null,
//         ),
//         IconButton(
//           icon: const Icon(Icons.videocam),
//           color: Colors.blue,
//           onPressed: controller != null &&
//                   controller.value.isInitialized &&
//                   !controller.value.isRecordingVideo
//               ? onVideoRecordButtonPressed
//               : null,
//         ),
//         IconButton(
//           icon: const Icon(Icons.watch),
//           color: Colors.blue,
//           onPressed: controller != null &&
//                   controller.value.isInitialized &&
//                   !controller.value.isStreamingVideoRtmp
//               ? onVideoStreamingButtonPressed
//               : null,
//         ),
//         IconButton(
//           icon: controller != null &&
//                   (controller.value.isRecordingPaused ||
//                       controller.value.isStreamingPaused)
//               ? Icon(Icons.play_arrow)
//               : Icon(Icons.pause),
//           color: Colors.blue,
//           onPressed: controller != null &&
//                   controller.value.isInitialized &&
//                   (controller.value.isRecordingVideo ||
//                       controller.value.isStreamingVideoRtmp)
//               ? (controller != null &&
//                       (controller.value.isRecordingPaused ||
//                           controller.value.isStreamingPaused)
//                   ? onResumeButtonPressed
//                   : onPauseButtonPressed)
//               : null,
//         ),
//         IconButton(
//           icon: const Icon(Icons.stop),
//           color: Colors.red,
//           onPressed: controller != null &&
//                   controller.value.isInitialized &&
//                   (controller.value.isRecordingVideo ||
//                       controller.value.isStreamingVideoRtmp)
//               ? onStopButtonPressed
//               : null,
//         )
//       ],
//     );
//   }
//
//   /// Display a row of toggle to select the camera (or a message if no camera is available).
//   Widget _cameraTogglesRowWidget() {
//     final List<Widget> toggles = <Widget>[];
//
//     if (cameras.isEmpty) {
//       return const Text('No camera found');
//     } else {
//       for (CameraDescription cameraDescription in cameras) {
//         toggles.add(
//           SizedBox(
//             width: 90.0,
//             child: RadioListTile<CameraDescription>(
//               title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
//               groupValue: controller?.description,
//               value: cameraDescription,
//               onChanged: controller != null && controller.value.isRecordingVideo
//                   ? null
//                   : onNewCameraSelected,
//             ),
//           ),
//         );
//       }
//     }
//
//     return Row(children: toggles);
//   }
//   //final _scaffoldKey = GlobalKey<ScaffoldState>();
//   String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
//
//   void showInSnackBar(String message) {
//     // ignore: deprecated_member_use
//    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }
// //  showSnackBar(){
//
//  // }
//
//   void onNewCameraSelected(CameraDescription cameraDescription) async {
//     if (controller != null) {
//       await stopVideoStreaming();
//       await controller.dispose();
//     }
//     controller = CameraController(
//       cameraDescription,
//       ResolutionPreset.medium,
//       enableAudio: enableAudio,
//       androidUseOpenGL: useOpenGL,
//     );
//
//     // If the controller is updated then update the UI.
//     controller.addListener(() async {
//       if (mounted) setState(() {});
//       if (controller.value.hasError) {
//         showInSnackBar('Camera error ${controller.value.errorDescription}');
//         await stopVideoStreaming();
//       } else {
//         try {
//           final Map<dynamic, dynamic> event =
//           controller.value.event as Map<dynamic, dynamic>;
//           if (event != null) {
//             print('Event $event');
//             final String eventType = event['eventType'] as String;
//             if (isVisible && isStreaming && eventType == 'rtmp_retry') {
//               showInSnackBar('BadName received, endpoint in use.');
//               await stopVideoStreaming();
//             }
//           }
//         } catch (e) {
//           print(e);
//         }
//       }
//     });
//
//     try {
//       await controller.initialize();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//     }
//
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   void onTakePictureButtonPressed() {
//     takePicture().then((String filePath) {
//       if (mounted) {
//         setState(() {
//           imagePath = filePath;
//           videoController?.dispose();
//           videoController = null;
//         });
//         if (filePath != null) showInSnackBar('Picture saved to $filePath');
//       }
//     });
//   }
//
//   void onVideoRecordButtonPressed() {
//     startVideoRecording().then((String filePath) {
//       if (mounted) setState(() {});
//       if (filePath != null) showInSnackBar('Saving video to $filePath');
//       Wakelock.enable();
//     });
//   }
//
//   void onVideoStreamingButtonPressed() {
//     startVideoStreaming().then((String url) {
//       if (mounted) setState(() {});
//       if (url != null) showInSnackBar('Streaming video to $url');
//       Wakelock.enable();
//     });
//   }
//
//   void onRecordingAndVideoStreamingButtonPressed() {
//     startRecordingAndVideoStreaming().then((String url) {
//       if (mounted) setState(() {});
//       if (url != null) showInSnackBar('Recording streaming video to $url');
//       Wakelock.enable();
//     });
//   }
//
//   void onStopButtonPressed() {
//     if (this.controller.value.isStreamingVideoRtmp) {
//       stopVideoStreaming().then((_) {
//         if (mounted) setState(() {});
//         showInSnackBar('Video streamed to: $url');
//       });
//     } else {
//       stopVideoRecording().then((_) {
//         if (mounted) setState(() {});
//         showInSnackBar('Video recorded to: $videoPath');
//       });
//     }
//     Wakelock.disable();
//   }
//
//   void onPauseButtonPressed() {
//     pauseVideoRecording().then((_) {
//       if (mounted) setState(() {});
//       showInSnackBar('Video recording paused');
//     });
//   }
//
//   void onResumeButtonPressed() {
//     resumeVideoRecording().then((_) {
//       if (mounted) setState(() {});
//       showInSnackBar('Video recording resumed');
//     });
//   }
//
//   void onStopStreamingButtonPressed() {
//     stopVideoStreaming().then((_) {
//       if (mounted) setState(() {});
//       showInSnackBar('Video not streaming to: $url');
//     });
//   }
//
//   void onPauseStreamingButtonPressed() {
//     pauseVideoStreaming().then((_) {
//       if (mounted) setState(() {});
//       showInSnackBar('Video streaming paused');
//     });
//   }
//
//   void onResumeStreamingButtonPressed() {
//     resumeVideoStreaming().then((_) {
//       if (mounted) setState(() {});
//       showInSnackBar('Video streaming resumed');
//     });
//   }
//
//   Future<String> startVideoRecording() async {
//     if (!controller.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return null;
//     }
//
//     final Directory extDir = await getExternalStorageDirectory();
//     final String dirPath = '${extDir.path}/Movies/flutter_test';
//     await Directory(dirPath).create(recursive: true);
//     final String filePath = '$dirPath/${timestamp()}.mp4';
//
//     if (controller.value.isRecordingVideo) {
//       // A recording is already started, do nothing.
//       return null;
//     }
//
//     try {
//       videoPath = filePath;
//       await controller.startVideoRecording(filePath);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//     return filePath;
//   }
//
//   Future<void> stopVideoRecording() async {
//     if (!controller.value.isRecordingVideo) {
//       return null;
//     }
//
//     try {
//       await controller.stopVideoRecording();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//
//     await _startVideoPlayer();
//   }
//
//   Future<void> pauseVideoRecording() async {
//     try {
//       if (controller.value.isRecordingVideo) {
//         await controller.pauseVideoRecording();
//       }
//       if (controller.value.isStreamingVideoRtmp) {
//         await controller.pauseVideoStreaming();
//       }
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }
//
//   Future<void> resumeVideoRecording() async {
//     try {
//       if (controller.value.isRecordingVideo) {
//         await controller.resumeVideoRecording();
//       }
//       if (controller.value.isStreamingVideoRtmp) {
//         await controller.resumeVideoStreaming();
//       }
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }
//
//   Future<String> _getUrl() async {
//     // Open up a dialog for the url
//     String result = _textFieldController.text;
//
//     return await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: Text('Url to Stream to'),
//             content: TextField(
//               controller: _textFieldController,
//               decoration: InputDecoration(hintText: "Url to Stream to"),
//               onChanged: (String str) => result = str,
//             ),
//             actions: <Widget>[
//               // ignore: deprecated_member_use
//               new TextButton(
//                 child: new Text(
//                     MaterialLocalizations.of(context).cancelButtonLabel),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//               // ignore: deprecated_member_use
//               TextButton(
//                 child: Text(MaterialLocalizations.of(context).okButtonLabel),
//                 onPressed: () {
//                   Navigator.pop(context, result);
//                 },
//               )
//             ],
//           );
//         });
//   }
//
//   Future<String> startRecordingAndVideoStreaming() async {
//     if (!controller.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return null;
//     }
//
//     if (controller.value.isStreamingVideoRtmp ||
//         controller.value.isStreamingVideoRtmp) {
//       return null;
//     }
//
//     String myUrl = await _getUrl();
//
//     final Directory extDir = await getApplicationDocumentsDirectory();
//     final String dirPath = '${extDir.path}/Movies/flutter_test';
//     await Directory(dirPath).create(recursive: true);
//     final String filePath = '$dirPath/${timestamp()}.mp4';
//
//     try {
//       url = myUrl;
//       videoPath = filePath;
//       await controller.startVideoRecordingAndStreaming(videoPath, url);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//     return url;
//   }
//
//   Future<String> startVideoStreaming() async {
//     await stopVideoStreaming();
//     if (controller == null) {
//       return null;
//     }
//     if (!controller.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return null;
//     }
//
//     if (controller?.value?.isStreamingVideoRtmp ?? false) {
//       return null;
//     }
//
//     // Open up a dialog for the url
//     String myUrl = await _getUrl();
//
//     try {
//       url = myUrl;
//       await controller.startVideoStreaming(url);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//     return url;
//   }
//
//   Future<void> stopVideoStreaming() async {
//
//     if (controller == null || !controller.value.isInitialized) {
//       return;
//     }
//     if (!controller.value.isStreamingVideoRtmp) {
//       return;
//     }
//
//     try {
//       await controller.stopVideoStreaming();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//   }
//
//   Future<void> pauseVideoStreaming() async {
//     if (!controller.value.isStreamingVideoRtmp) {
//       return null;
//     }
//
//     try {
//       await controller.pauseVideoStreaming();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }
//
//   Future<void> resumeVideoStreaming() async {
//     if (!controller.value.isStreamingVideoRtmp) {
//       return null;
//     }
//
//     try {
//       await controller.resumeVideoStreaming();
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       rethrow;
//     }
//   }
//
//   Future<void> _startVideoPlayer() async {
//     final VideoPlayerController vcontroller =
//         VideoPlayerController.file(File(videoPath));
//     videoPlayerListener = () {
//       if (videoController != null && videoController.value.size != null) {
//         // Refreshing the state to update video player with the correct ratio.
//         if (mounted) setState(() {});
//         videoController.removeListener(videoPlayerListener);
//       }
//     };
//     vcontroller.addListener(videoPlayerListener);
//     await vcontroller.setLooping(true);
//     await vcontroller.initialize();
//     await videoController?.dispose();
//     if (mounted) {
//       setState(() {
//         imagePath = null;
//         videoController = vcontroller;
//       });
//     }
//     await vcontroller.play();
//   }
//
//   Future<String> takePicture() async {
//     if (!controller.value.isInitialized) {
//       showInSnackBar('Error: select a camera first.');
//       return null;
//     }
//     final Directory extDir = await getExternalStorageDirectory();
//     final String dirPath = '${extDir.path}/Pictures/flutter_test';
//     await Directory(dirPath).create(recursive: true);
//     final String filePath = '$dirPath/${timestamp()}.jpg';
//
//     if (controller.value.isTakingPicture) {
//       // A capture is already pending, do nothing.
//       return null;
//     }
//
//     try {
//       await controller.takePicture(filePath);
//     } on CameraException catch (e) {
//       _showCameraException(e);
//       return null;
//     }
//     return filePath;
//   }
//
//   void _showCameraException(CameraException e) {
//     logError(e.code, e.description);
//     showInSnackBar('Error: ${e.code}\n${e.description}');
//   }
// }

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
