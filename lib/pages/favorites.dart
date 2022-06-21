import 'dart:convert';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_zx/model/track.dart';
import 'package:stream_zx/pages/audioplayer.dart';
import 'package:stream_zx/pages/home.dart';

class Favorites extends StatefulWidget {
  const Favorites({Key? key}) : super(key: key);

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  var selectedTrack = <String, dynamic>{};
  bool isPlaying = false;
  bool isPaused = true;
  int currentTrackIndex = 0;
  AudioCache audioCache = AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
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
  bool favEnabled = false;
  List<dynamic> allTracks = [];
  List<Track> allTracksModel = [];

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
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
            onPressed: audioPlayer.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.pause),
            iconSize: 40.0,
            onPressed: audioPlayer.pause,
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.replay),
            iconSize: 40.0,
            onPressed: () => audioPlayer.seek(Duration.zero),
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
            audioPlayer.seek(duration);
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

  //change seconds to mm:ss format
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
  }

  void removeFav(singleFavTrack) async {
    await instantiatePref();

    List<dynamic> favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);

    favTracksSaved
        .removeWhere((element) => element['id'] == singleFavTrack['id']);

    favPrefs.setString("favorites", jsonEncode(favTracksSaved));
  }

  Future<List<dynamic>> loadFavPrefs() async {
    await instantiatePref();

    if (favPrefs.getString("favorites") != null) {
      allTracks = jsonDecode(favPrefs.getString("favorites")!);
    }

    for (var item in allTracks) {
      allTracksModel.add(Track(
          id: item['id'],
          name: item['name'],
          href: item['href'],
          playbackSeconds: int.parse(item['playbackSeconds']),
          artistName: item['artistName'],
          albumName: item['albumName'],
          previewUrl: item['previewUrl']));
    }

    print("fav tracks : ${allTracks}");

    return allTracks;
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
          setState(() {
            favEnabled = true;
          });
          print("shit");
          break;
        } else {
          setState(() {
            favEnabled = false;
          });
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
    _durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        audioPlayer.positionStream,
        audioPlayer.playbackEventStream,
        (position, playbackEvent) => DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration,
            ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        audioPlayer.positionStream,
        audioPlayer.playbackEventStream,
        (position, playbackEvent) => DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration,
            ));

    return SafeArea(
      child: Container(
        child: SingleChildScrollView(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.favorite, size: 34),
                        Text("Favorites",
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 22))
                      ],
                    )),
                FutureBuilder(
                    future: loadFavPrefs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else {
                        return Column(children: [
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(10),
                              child: Text("Favorite tracks ${allTracks.length}",
                                  style: TextStyle(
                                      fontFamily: 'Montserrat', fontSize: 17))),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              padding: EdgeInsets.all(10),
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: allTracks.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                        onTap: () async {
                                          Map<String, dynamic> favTracksSaved =
                                              {
                                            "id":
                                                "${allTracks[currentTrackIndex]['id']}",
                                            "name":
                                                "${allTracks[currentTrackIndex]['name']}",
                                            "previewUrl":
                                                "${allTracks[currentTrackIndex]['previewUrl']}",
                                            "playbackSeconds":
                                                "${allTracks[currentTrackIndex]['playbackSeconds']}",
                                            "artistName":
                                                "${allTracks[currentTrackIndex]['artistName']}",
                                            "albumName":
                                                "${allTracks[currentTrackIndex]['albumName']}"
                                          };

                                          checkItemExistenceForFavIc(
                                              favTracksSaved);
                                          print(allTracks[index]);
                                          setState(() {
                                            currentTrackIndex = index;

                                            selectedTrack['name'] =
                                                allTracks[index]['name'];
                                            selectedTrack['artistName'] =
                                                allTracks[index]['artistName'];
                                            selectedTrack['previewUrl'] =
                                                allTracks[index]['previewUrl'];
                                            selectedTrack['playbackSeconds'] =
                                                allTracks[index]
                                                    ['playbackSeconds'];
                                            isPaused = false;
                                          });

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AudioSelectedPlayer(
                                                      favEnabled: favEnabled,
                                                      allTracks: allTracksModel,
                                                      currentTrackIndex:
                                                          currentTrackIndex),
                                            ),
                                          );
                                        },
                                        child: Container(
                                            height: 70,
                                            margin: EdgeInsets.only(bottom: 15),
                                            padding: EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                      offset: Offset(2, 2),
                                                      blurRadius: 20,
                                                      color:
                                                          Colors.grey.shade200)
                                                ]),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(children: [
                                                    Image(
                                                        image: NetworkImage(
                                                            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ63dz8EEcIKfOQjU3j3RWVOepm8MxVr02yitEV2bEFlg-2tHWWbZGWNszGWCyUL-zi5Ug&usqp=CAU")),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  10),
                                                          child: Text(
                                                              "${allTracks[index]['name'].toString().length > 30 ? allTracks[index]['name'].toString().substring(0, 30) : allTracks[index]['name']}",
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      15)),
                                                        ),
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 10),
                                                          padding:
                                                              EdgeInsets.all(0),
                                                          child: Text(
                                                              "by ${allTracks[index]['artistName']}",
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  fontSize:
                                                                      11)),
                                                        )
                                                      ],
                                                    ),
                                                  ]),
                                                  Column(children: [
                                                    Container(
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        child: Text(
                                                            "${formatDuration(int.parse(allTracks[index]['playbackSeconds']))}",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Montserrat',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                fontSize: 11))),
                                                    Container(
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        child: Icon(
                                                            Icons.play_circle))
                                                  ])
                                                ])));
                                  }))
                        ]);
                      }
                    })
              ],
            )),
      ),
    );
  }
}
