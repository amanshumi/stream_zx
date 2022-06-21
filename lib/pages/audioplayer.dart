import 'dart:convert';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_zx/controller/audio_controller.dart';
import 'package:stream_zx/model/track.dart';

import 'home.dart';

class AudioSelectedPlayer extends StatefulWidget {
  final List<Track>? allTracks;
  final int? currentTrackIndex;
  final bool? favEnabled;
  const AudioSelectedPlayer(
      {Key? key, this.favEnabled, this.allTracks, this.currentTrackIndex})
      : super(key: key);

  @override
  State<AudioSelectedPlayer> createState() => _AudioSelectedPlayerState();
}

class _AudioSelectedPlayerState extends State<AudioSelectedPlayer> {
  AudioController audioController = Get.put(AudioController());
  bool favEnabled = false;
  List<Track> allTracks = [];
  var selectedTrack = <String, dynamic>{};
  bool isPlaying = false;
  bool isPaused = true;
  int currentTrackIndex = 0;
  AudioCache audioCache = AudioCache();
  AudioPlayer? audioPlayer;
  late Stream<DurationState> _durationState;
  var _isShowingWidgetOutline = false;
  var _labelLocation = TimeLabelLocation.below;
  var _labelType = TimeLabelType.totalTime;
  TextStyle? _labelStyle;
  var _thumbRadius = 10.0;
  var _labelPadding = 0.0;
  var _barHeight = 5.0;
  var _barCapShape = BarCapShape.round;
  Color? _baseBarColor;
  Color? _progressBarColor;
  Color? _bufferedBarColor;
  Color? _thumbColor;
  Color? _thumbGlowColor;
  var _thumbCanPaintOutsideBar = true;
  late SharedPreferences favPrefs;

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer!.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 32.0,
            height: 32.0,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.red),
            iconSize: 40.0,
            onPressed: audioPlayer!.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.pause),
            iconSize: 40.0,
            onPressed: audioPlayer!.pause,
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.replay),
            iconSize: 40.0,
            onPressed: () => audioPlayer!.seek(Duration.zero),
          );
        }
      },
    );
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _durationState.asBroadcastStream(),
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          buffered: buffered,
          total: total,
          onSeek: (duration) {
            audioPlayer!.seek(duration);
          },
          onDragUpdate: (details) {
            debugPrint('${details.timeStamp}, ${details.localPosition}');
          },
          barHeight: _barHeight,
          baseBarColor: _baseBarColor,
          progressBarColor: _progressBarColor,
          bufferedBarColor: _bufferedBarColor,
          thumbColor: _thumbColor,
          thumbGlowColor: _thumbGlowColor,
          barCapShape: _barCapShape,
          thumbRadius: _thumbRadius,
          thumbCanPaintOutsideBar: _thumbCanPaintOutsideBar,
          timeLabelLocation: _labelLocation,
          timeLabelType: _labelType,
          timeLabelTextStyle: _labelStyle,
          timeLabelPadding: _labelPadding,
        );
      },
    );
  }

  String formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes;
    final seconds = totalSeconds % 60;

    final minutesString = '$minutes'.padLeft(2, '0');
    final secondsString = '$seconds'.padLeft(2, '0');
    return '$minutesString:$secondsString';
  }

  Future instantiatePref() async {
    favPrefs = await SharedPreferences.getInstance();
  }

  void addFavorites(singleFavTrack) async {
    await instantiatePref();

    List<dynamic> favTracksSaved = [];

    if (favPrefs.getString("favorites") != null) {
      favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);

      if (favTracksSaved == null) {
        favTracksSaved = [];
      }

      favTracksSaved.add(singleFavTrack);

      var encoded = jsonEncode(favTracksSaved);

      favPrefs.setString("favorites", encoded);
    } else {
      favTracksSaved.add(singleFavTrack);
      var encoded = jsonEncode(favTracksSaved);
      favPrefs.setString("favorites", encoded);
    }

    setState(() {
      favEnabled = true;
    });
  }

  void removeFav(singleFavTrack) async {
    await instantiatePref();

    List<dynamic> favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);

    favTracksSaved
        .removeWhere((element) => element['id'] == singleFavTrack['id']);

    favPrefs.setString("favorites", jsonEncode(favTracksSaved));

    setState(() {
      favEnabled = false;
    });
  }

  void loadFavPrefs() async {
    await instantiatePref();

    List<dynamic> favTracksSaved = [];

    if (favPrefs.getString("favorites") != null) {
      favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);
    }
  }

  void playFirst() async {
    try {
      await audioPlayer!.stop();
      await audioPlayer!.setUrl(
          "${selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl}");

      await audioPlayer!.play();
      setState(() {
        isPaused = false;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<bool> checkFavItem(singleFavTrack) async {
    await instantiatePref();

    bool toReturn = false;

    List<dynamic> favTracksSaved = [];

    if (favPrefs.getString("favorites") != null) {
      favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);

      for (var singleTrack in favTracksSaved) {
        if (singleTrack['id'] == singleFavTrack['id']) {
          setState(() {
            toReturn = true;
          });
          print("shit");
          break;
        } else {
          setState(() {
            toReturn = false;
          });
        }
      }
    } else {
      setState(() {
        toReturn = false;
      });
    }

    return Future.value(toReturn);
  }

  void checkItemExistenceForFavIc(singleFavTrack) async {
    await instantiatePref();

    List<dynamic> favTracksSaved = [];

    if (favPrefs.getString("favorites") != null) {
      favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);

      for (var singleTrack in favTracksSaved) {
        if (singleTrack['id'] == singleFavTrack['id']) {
          favEnabled = true;

          print("shit");
          break;
        } else {
          favEnabled = false;
        }
      }
    } else {
      setState(() {
        favEnabled = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    audioPlayer = audioController.audioPlayer;
    print("fuck ${this.widget.favEnabled}");
    allTracks = this.widget.allTracks!;
    favEnabled = this.widget.favEnabled!;
    currentTrackIndex = this.widget.currentTrackIndex!;
    selectedTrack['name'] = allTracks[currentTrackIndex].name;
    selectedTrack['artistName'] = allTracks[currentTrackIndex].artistName;
    selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl;
    selectedTrack['playbackSeconds'] =
        allTracks[currentTrackIndex].playbackSeconds;

    _durationState =
        rxdart.Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
            audioPlayer!.positionStream,
            audioPlayer!.playbackEventStream,
            (position, playbackEvent) => DurationState(
                  progress: position,
                  buffered: playbackEvent.bufferedPosition,
                  total: playbackEvent.duration,
                ));

    super.initState();

    playFirst();
  }

  @override
  Widget build(BuildContext context) {
    _durationState =
        rxdart.Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
            audioPlayer!.positionStream,
            audioPlayer!.playbackEventStream,
            (position, playbackEvent) => DurationState(
                  progress: position,
                  buffered: playbackEvent.bufferedPosition,
                  total: playbackEvent.duration,
                ));

    Map<String, dynamic> favTracksSaved = {
      "id": "${allTracks[currentTrackIndex].id}",
      "name": "${allTracks[currentTrackIndex].name}",
      "previewUrl": "${allTracks[currentTrackIndex].previewUrl}",
      "playbackSeconds": "${allTracks[currentTrackIndex].playbackSeconds}",
      "artistName": "${allTracks[currentTrackIndex].artistName}",
      "albumName": "${allTracks[currentTrackIndex].albumName}"
    };

    checkItemExistenceForFavIc(favTracksSaved);

    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_ios, size: 20),
                    ),
                    onTap: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                  ),
                  GestureDetector(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.cancel_outlined, size: 23),
                      ),
                      onTap: () {
                        setState(() {
                          Navigator.pop(context);
                        });
                      })
                ],
              ),
              Center(
                  child: Container(
                      margin: EdgeInsets.only(top: 30),
                      padding: EdgeInsets.all(10),
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                                offset: Offset(3, 10),
                                blurRadius: 30,
                                color: Colors.grey.shade700)
                          ],
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(100)),
                      child: CircleAvatar(
                        backgroundColor: Colors.black12,
                        backgroundImage: NetworkImage(
                            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSl8dmldDh6eLJPevAOpTv4EjldGurQi8gslg&usqp=CAU"),
                      ))),
              SizedBox(height: 100),
              Center(
                child: Container(
                    child: Text(
                        "${selectedTrack['name'].toString().length > 20 ? selectedTrack['name'].substring(0, 20) : selectedTrack['name']}",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontFamily: "Montserrat",
                            fontSize: 26,
                            fontWeight: FontWeight.bold))),
              ),
              SizedBox(height: 40),
              Center(
                child: Container(
                    child: Text("By ${selectedTrack['artistName']}",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontFamily: "Montserrat",
                            fontSize: 16,
                            fontWeight: FontWeight.normal))),
              ),
              SizedBox(height: 30),
              // Stack(
              //   children: [
              //     Container(
              //         height: 6,
              //         width: MediaQuery.of(context).size.width,
              //         decoration: BoxDecoration(
              //             color: Colors.blue.shade100,
              //             borderRadius: BorderRadius.circular(40))),
              //     Container(
              //         height: 6,
              //         width: 150,
              //         decoration: BoxDecoration(
              //             color: Colors.blue.shade900,
              //             borderRadius: BorderRadius.circular(40))),
              //   ],
              // ),
              _progressBar(),
              SizedBox(height: 20),
              // LinearProgressIndicator(
              //   backgroundColor: Colors.blue.shade100,
              //   color: Colors.blue.shade900,

              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text("02:30",
              //         style: TextStyle(
              //             fontFamily: "Montserrat",
              //             fontSize: 16,
              //             fontWeight: FontWeight.normal)),
              //     Text("05:30",
              //         style: TextStyle(
              //             fontFamily: "Montserrat",
              //             fontSize: 16,
              //             fontWeight: FontWeight.normal))
              //   ],
              // ),

              // SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (currentTrackIndex > 0) {
                        setState(() {
                          currentTrackIndex--;
                          selectedTrack['name'] =
                              allTracks[currentTrackIndex].name;
                          selectedTrack['artistName'] =
                              allTracks[currentTrackIndex].artistName;
                          selectedTrack['previewUrl'] =
                              allTracks[currentTrackIndex].previewUrl;
                          selectedTrack['playbackSeconds'] =
                              allTracks[currentTrackIndex].playbackSeconds;
                          isPaused = false;
                        });

                        Map<String, dynamic> favTracksSaved = {
                          "id": "${allTracks[currentTrackIndex].id}",
                          "name": "${allTracks[currentTrackIndex].name}",
                          "previewUrl":
                              "${allTracks[currentTrackIndex].previewUrl}",
                          "playbackSeconds":
                              "${allTracks[currentTrackIndex].playbackSeconds}",
                          "artistName":
                              "${allTracks[currentTrackIndex].artistName}",
                          "albumName":
                              "${allTracks[currentTrackIndex].albumName}"
                        };

                        checkItemExistenceForFavIc(favTracksSaved);

                        try {
                          await audioPlayer!.setUrl(
                              "${selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl}");
                          await audioPlayer!.play();
                        } catch (e) {
                          print(e.toString());
                        }
                      }
                    },
                    child: Container(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.fast_rewind, size: 30)),
                  ),
                  // GestureDetector(
                  //   child: isPaused
                  //       ? Container(
                  //           padding: EdgeInsets.all(10),
                  //           child: Icon(Icons.play_circle_fill_rounded,
                  //               size: 80, color: Colors.red.shade400))
                  //       : Container(
                  //           padding: EdgeInsets.all(10),
                  //           child: Icon(Icons.pause_circle_filled,
                  //               size: 80, color: Colors.red.shade400)),
                  //   onTap: () async {
                  //     if (isPaused) {
                  //       await audioPlayer.setUrl(
                  //           "${selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl}");
                  //       await audioPlayer.play();
                  //     } else {
                  //       await audioPlayer.pause();
                  //     }

                  //     setState(() {
                  //       isPaused = !isPaused;
                  //     });
                  //   },
                  // ),

                  _playButton(),

                  GestureDetector(
                    onTap: () async {
                      if (currentTrackIndex < allTracks.length) {
                        setState(() {
                          currentTrackIndex++;
                          print(currentTrackIndex);
                          selectedTrack['name'] =
                              allTracks[currentTrackIndex].name;
                          selectedTrack['artistName'] =
                              allTracks[currentTrackIndex].artistName;
                          selectedTrack['previewUrl'] =
                              allTracks[currentTrackIndex].previewUrl;
                          selectedTrack['playbackSeconds'] =
                              allTracks[currentTrackIndex].playbackSeconds;
                          isPaused = false;
                        });

                        try {
                          await audioPlayer!.setUrl(
                              "${selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl}");
                          await audioPlayer!.play();
                        } catch (e) {
                          print(e.toString());
                        }
                      }
                    },
                    child: Container(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.fast_forward, size: 30)),
                  ),
                ],
              ),

              SizedBox(height: 20),
              GestureDetector(
                  onTap: () {
                    Map<String, dynamic> favTracksSaved = {
                      "id": "${allTracks[currentTrackIndex].id}",
                      "name": "${allTracks[currentTrackIndex].name}",
                      "previewUrl":
                          "${allTracks[currentTrackIndex].previewUrl}",
                      "playbackSeconds":
                          "${allTracks[currentTrackIndex].playbackSeconds}",
                      "artistName":
                          "${allTracks[currentTrackIndex].artistName}",
                      "albumName": "${allTracks[currentTrackIndex].albumName}"
                    };

                    checkFavItem(favTracksSaved).then((value) => {
                          if (value)
                            {removeFav(favTracksSaved)}
                          else
                            {addFavorites(favTracksSaved)}
                        });

                    checkItemExistenceForFavIc(favTracksSaved);
                  },
                  child: Icon(Icons.favorite,
                      color: favEnabled ? Colors.red : Colors.grey, size: 30))
            ],
          ),
        ),
      ),
    );
  }
}
