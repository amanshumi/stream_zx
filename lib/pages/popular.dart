import 'dart:convert';

import 'package:audioplayers/audio_cache.dart';
//import 'package:audioplayers/audioplayers.dart' as AudioPlayer;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_zx/model/track.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:stream_zx/pages/audioplayer.dart';

class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    this.total,
  });
  final Duration progress;
  final Duration buffered;
  final Duration? total;
}

class Popular extends StatefulWidget {
  final String? genreId;
  final String? genreName;
  final bool? playlistEnabled;
  final String? playListName;
  final String? playListId;
  const Popular(
      {Key? key,
      this.genreId,
      this.genreName,
      this.playlistEnabled,
      this.playListName,
      this.playListId})
      : super(key: key);

  @override
  State<Popular> createState() => _PopularState();
}

class _PopularState extends State<Popular> {
  String apiKey = "MGVjN2VmMWItZjc5OS00MDNkLTkxYTktYWQ5MmUxNTA0MDQ2";
  String? genreId;
  String? genreName;
  late bool playlistEnabled = false;
  String? playListName;
  String? playListId;
  bool? favEnabled = false;

  List<Track> allTracks = [];
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

  Future<List<Track>> loadTopTracks() async {
    String tracksUrl =
        "http://api.napster.com/v2.2/tracks/top?limit=100&apikey=${apiKey}";

    if (genreId != null && genreId != "") {
      tracksUrl =
          "http://api.napster.com/v2.2/genres/${genreId}/tracks/top?apikey=${apiKey}";
    }

    if (playlistEnabled) {
      print(playListId);
      tracksUrl =
          "http://api.napster.com/v2.2/playlists/${playListId}/tracks?apikey=${apiKey}&limit=30&offset=5";
    }

    try {
      var response = await get(Uri.parse(tracksUrl));

      Map<String, dynamic> tracksParsed = jsonDecode(response.body);

      List<dynamic> tracksAll = tracksParsed['tracks'];

      for (var trackSingle in tracksAll) {
        allTracks.add(Track(
            id: trackSingle['id'],
            name: trackSingle['name'],
            href: trackSingle['href'],
            tIndex: trackSingle['index'],
            playbackSeconds: trackSingle['playbackSeconds'],
            artistName: trackSingle['artistName'],
            albumName: trackSingle['albumName'],
            previewUrl: trackSingle['previewURL']));
      }

      selectedTrack['name'] = allTracks[currentTrackIndex].name;
      selectedTrack['artistName'] = allTracks[currentTrackIndex].artistName;
      selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl;
      selectedTrack['playbackSeconds'] =
          allTracks[currentTrackIndex].playbackSeconds;
    } catch (e) {
      print(e.toString());
    }

    return allTracks;
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

    print("fav tracks : ${favTracksSaved}");
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
    genreId = this.widget.genreId;
    playlistEnabled = this.widget.playlistEnabled!;
    playListName = this.widget.playListName;
    playListId = this.widget.playListId;

    if (this.widget.genreName != null && this.widget.genreName != "") {
      genreName = this.widget.genreName;
    } else if (playlistEnabled != null && playlistEnabled == true) {
      genreName = playListName;
    } else {
      genreName = "Popular";
    }

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
    instantiatePref();

    if (this.widget.genreName != null || this.widget.genreName != "") {
      genreName = this.widget.genreName;
    } else if (playlistEnabled != null && playlistEnabled == true) {
      genreName = playListName;
    } else {
      genreName = "Popular";
    }

    print(playlistEnabled);

    _durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        audioPlayer.positionStream,
        audioPlayer.playbackEventStream,
        (position, playbackEvent) => DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration,
            ));

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GestureDetector(
                        //     onTap: () {
                        //       Navigator.pop(context);
                        //     },
                        //     child: Icon(Icons.arrow_back_ios,
                        //         color: Colors.blue[600])),
                        Image(
                          image: AssetImage("assets/music_illustr.png"),
                          height: 120,
                        ),

                        playlistEnabled
                            ? Container(
                                child: Text("${playListName}",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        overflow: TextOverflow.clip,
                                        fontFamily: "Montserrat",
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)))
                            : Container(
                                child: Text(
                                    "${genreName != null ? genreName : 'Popular'}",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        fontFamily: "Montserrat",
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold))),
                      ]),

                  SizedBox(height: 30),
                  // TextField(
                  //   onTap: () {},
                  //   decoration: new InputDecoration(
                  //     filled: true,
                  //     fillColor: Colors.grey.shade200,
                  //     hintStyle: TextStyle(fontFamily: "Montserrat"),
                  //     suffixIcon: Icon(Icons.search_rounded),
                  //     border: new OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(50),
                  //         borderSide: new BorderSide(
                  //             width: 1.0, color: Colors.grey.shade200)),
                  //     focusedBorder: new OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(50),
                  //         borderSide: new BorderSide(
                  //             width: 1.0, color: Colors.grey.shade200)),
                  //     enabledBorder: new OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(50),
                  //         borderSide: new BorderSide(
                  //             width: 1.0, color: Colors.grey.shade200)),
                  //     hintText: 'Enter a search term',
                  //   ),
                  // ),
                  // SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Track>>(
                        future: loadTopTracks(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              snapshot.data == null) {
                            return Center(child: CircularProgressIndicator());
                          } else {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              child: ListView.builder(
                                itemCount: allTracks.length,
                                itemBuilder: (context, item) {
                                  return GestureDetector(
                                    onTap: () async {
                                      Map<String, dynamic> favTracksSaved = {
                                        "id":
                                            "${allTracks[currentTrackIndex].id}",
                                        "name":
                                            "${allTracks[currentTrackIndex].name}",
                                        "previewUrl":
                                            "${allTracks[currentTrackIndex].previewUrl}",
                                        "playbackSeconds":
                                            "${allTracks[currentTrackIndex].playbackSeconds}",
                                        "artistName":
                                            "${allTracks[currentTrackIndex].artistName}",
                                        "albumName":
                                            "${allTracks[currentTrackIndex].albumName}"
                                      };

                                      checkItemExistenceForFavIc(
                                          favTracksSaved);
                                      setState(() {
                                        currentTrackIndex = item;

                                        selectedTrack['name'] =
                                            allTracks[item].name;
                                        selectedTrack['artistName'] =
                                            allTracks[item].artistName;
                                        selectedTrack['previewUrl'] =
                                            allTracks[item].previewUrl;
                                        selectedTrack['playbackSeconds'] =
                                            allTracks[item].playbackSeconds;
                                        isPaused = false;
                                      });

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AudioSelectedPlayer(
                                                  favEnabled: favEnabled,
                                                  allTracks: allTracks,
                                                  currentTrackIndex:
                                                      currentTrackIndex),
                                        ),
                                      );
                                    },
                                    child: Container(
                                        margin:
                                            EdgeInsets.only(top: 10, bottom: 0),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                offset: Offset(10, 10),
                                                blurRadius: 10,
                                                color: Colors.grey.shade100,
                                              )
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Column(
                                          children: [
                                            Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                      height: 70,
                                                      width: 70,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          image: DecorationImage(
                                                              fit: BoxFit.cover,
                                                              image: NetworkImage(
                                                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ63dz8EEcIKfOQjU3j3RWVOepm8MxVr02yitEV2bEFlg-2tHWWbZGWNszGWCyUL-zi5Ug&usqp=CAU")))),
                                                  SizedBox(width: 0),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.5,
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 20),
                                                          child: ConstrainedBox(
                                                            constraints: BoxConstraints(
                                                                maxWidth: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.8),
                                                            child: Text(
                                                                "${allTracks[item].name!.length > 30 ? allTracks[item].name!.substring(0, 30) : allTracks[item].name}",
                                                                softWrap: true,
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                style: TextStyle(
                                                                    height: 1.6,
                                                                    fontFamily:
                                                                        "Montserrat",
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          )),
                                                      SizedBox(height: 10),
                                                      Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 20),
                                                          child: Text(
                                                              "${allTracks[item].artistName!.length > 20 ? allTracks[item].artistName!.substring(0, 20) : allTracks[item].artistName}",
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "Montserrat",
                                                                fontSize: 11,
                                                              )))
                                                    ],
                                                  ),
                                                  // Expanded(
                                                  //     child: Container()),
                                                  Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: Column(
                                                        children: [
                                                          Icon(Icons
                                                              .play_circle_fill),
                                                          SizedBox(height: 20),
                                                          Text(
                                                              "${formatDuration(allTracks[item].playbackSeconds!.toInt())}",
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "Montserrat",
                                                                fontSize: 11,
                                                              ))
                                                        ],
                                                      ))
                                                ])
                                          ],
                                        )),
                                  );
                                },
                              ),
                            );
                          }
                        }),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
