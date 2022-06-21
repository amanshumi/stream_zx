import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_zx/pages/audioplayer.dart';
import 'popular.dart';
import 'package:stream_zx/model/track.dart';
import 'package:stream_zx/model/genre.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_zx/model/track.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

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

class _HomepageState extends State<Homepage> {
  static int currState = 0;
  static String name = "";
  static String email = "";
  static String avatar = "";
  static String apiKey = "MGVjN2VmMWItZjc5OS00MDNkLTkxYTktYWQ5MmUxNTA0MDQ2";
  static var selectedTrack = <String, dynamic>{};
  static bool isPlaying = false;
  static bool isPaused = true;
  static int currentTrackIndex = 0;
  static AudioCache audioCache = AudioCache();
  static AudioPlayer audioPlayer = AudioPlayer();
  late Stream<DurationState> _durationState;
  var _isShowingWidgetOutline = false;
  var _labelLocation = TimeLabelLocation.below;
  var _labelType = TimeLabelType.totalTime;
  static TextStyle? _labelStyle;
  var _thumbRadius = 10.0;
  var _labelPadding = 0.0;
  var _barHeight = 5.0;
  var _barCapShape = BarCapShape.round;
  Color? _baseBarColor;
  Color? _progressBarColor;
  Color? _bufferedBarColor;
  bool favEnabled = false;
  Color? _thumbColor;
  Color? _thumbGlowColor;
  var _thumbCanPaintOutsideBar = true;
  late SharedPreferences favPrefs;

  static List<Track> allTracks = [];
  static List<Genre> allGenres = [];

  Future instantiatePref() async {
    favPrefs = await SharedPreferences.getInstance();
  }

  static StreamBuilder<PlayerState> _playButton() {
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
            iconSize: 80.0,
            onPressed: audioPlayer.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.pause),
            iconSize: 80.0,
            onPressed: audioPlayer.pause,
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.replay),
            iconSize: 80.0,
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

  static Future<List<Genre>> loadGenres() async {
    try {
      var response = await get(
          "http://api.napster.com/v2.2/genres?limit=20&apikey=${apiKey}");

      Map<String, dynamic> genresMap = jsonDecode(response.body);

      List<dynamic> genresList = genresMap['genres'];

      for (var genre in genresList) {
        allGenres.add(Genre(
            type: genre['type'],
            id: genre['id'],
            name: genre['name'],
            description: genre['description'],
            href: genre['href'],
            shortcut: genre['shortcut']));
      }
    } catch (e) {
      print(e.toString());
    }

    return allGenres;
  }

  static Future<List<Track>> loadTopTracks() async {
    try {
      var response = await get(
          Uri.parse("http://api.napster.com/v2.2/tracks/top?apikey=${apiKey}"));

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

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString("name")!;
      email = prefs.getString("email")!;
      avatar = prefs.getString("avatar")!;
    });
  }

  Future<bool> checkFavItem(singleFavTrack) async {
    await instantiatePref();

    bool toReturn = false;

    List<dynamic> favTracksSaved = [];

    if (favPrefs.getString("favorites") != null) {
      favTracksSaved = await jsonDecode(favPrefs.getString("favorites")!);

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

  Future<bool> checkItemExistenceForFavIc(singleFavTrack) async {
    await instantiatePref();

    late bool favoriteEnabled;

    List<dynamic> favTracksSaved = [];

    if (favPrefs.getString("favorites") != null) {
      favTracksSaved = jsonDecode(favPrefs.getString("favorites")!);

      for (var singleTrack in favTracksSaved) {
        if (singleTrack['id'] == singleFavTrack['id']) {
          favoriteEnabled = true;
          break;
        } else {
          favoriteEnabled = false;
        }
      }
    } else {
      favoriteEnabled = false;
    }

    print("in the future : ${favoriteEnabled}");

    return Future.value(favoriteEnabled);
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

    _loadUser();

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
    return SafeArea(child: _popularListWidget());
  }

  Widget _popularListWidget() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 0,
        backgroundColor: Colors.grey.shade900,
        automaticallyImplyLeading: false,
        title: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.97,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(top: 10, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: EdgeInsets.all(5),
                    child: const Text("Welcome",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Montserrat")),
                  ),
                  Container(
                    padding: EdgeInsets.all(5),
                    child: Text("${name}",
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            fontFamily: "Montserrat")),
                  )
                ]),
                Container(
                    height: 50,
                    width: 50,
                    child: avatar == ""
                        ? Icon(Icons.account_circle, size: 50)
                        : CircleAvatar(
                            backgroundImage: NetworkImage("${avatar}") != null
                                ? NetworkImage("${avatar}")
                                : null,
                          )),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Form(
                child: TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    hintStyle: TextStyle(fontFamily: "Montserrat"),
                    suffixIcon: Icon(Icons.search_rounded),
                    border: new OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: new BorderSide(
                            width: 1.0, color: Colors.grey.shade200)),
                    focusedBorder: new OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: new BorderSide(
                            width: 1.0, color: Colors.grey.shade200)),
                    enabledBorder: new OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: new BorderSide(
                            width: 1.0, color: Colors.grey.shade200)),
                    hintText: 'Enter a search term',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Container(
                      margin: EdgeInsets.only(top: 10, bottom: 20),
                      padding: EdgeInsets.all(0),
                      child: Text("Popular Songs",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 15,
                              fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 5, bottom: 20),
                    padding: EdgeInsets.all(15),
                    child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Popular(
                                        playlistEnabled: false,
                                      )));
                        },
                        child: Text("more...",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 15,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
              Container(
                  height: 120,
                  child: FutureBuilder<List<Track>>(
                      future: loadTopTracks(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return snapshot.data != null
                              ? Container(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: allTracks.length > 30
                                        ? 20
                                        : allTracks.length,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, item) {
                                      return GestureDetector(
                                          onTap: () async {
                                            Map<String, dynamic> singleTrack = {
                                              "id": allTracks[currentTrackIndex]
                                                  .id,
                                              "name":
                                                  allTracks[currentTrackIndex]
                                                      .name,
                                              "href":
                                                  allTracks[currentTrackIndex]
                                                      .href,
                                              "previewUrl":
                                                  allTracks[currentTrackIndex]
                                                      .previewUrl,
                                              "artistName":
                                                  allTracks[currentTrackIndex]
                                                      .artistName,
                                              "albumName":
                                                  allTracks[currentTrackIndex]
                                                      .albumName,
                                              "playbackSeconds":
                                                  allTracks[currentTrackIndex]
                                                      .playbackSeconds,
                                            };

                                            bool isFavorite = false;

                                            setState(() {
                                              currentTrackIndex = item;
                                            });

                                            await checkItemExistenceForFavIc(
                                                    singleTrack)
                                                .then((value) async {
                                              print("before ${value}");
                                              if (value) {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AudioSelectedPlayer(
                                                            favEnabled: true,
                                                            allTracks:
                                                                allTracks,
                                                            currentTrackIndex:
                                                                currentTrackIndex),
                                                  ),
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AudioSelectedPlayer(
                                                            favEnabled: false,
                                                            allTracks:
                                                                allTracks,
                                                            currentTrackIndex:
                                                                currentTrackIndex),
                                                  ),
                                                );
                                              }
                                            });
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(right: 15),
                                            height: 150,
                                            width: 120,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                      image: const DecorationImage(
                                                          fit: BoxFit.cover,
                                                          image: NetworkImage(
                                                              "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ63dz8EEcIKfOQjU3j3RWVOepm8MxVr02yitEV2bEFlg-2tHWWbZGWNszGWCyUL-zi5Ug&usqp=CAU")),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                                // Align(
                                                //   alignment: Alignment.center,
                                                //   child: (Container(
                                                //     child: Icon(Icons.play_circle,
                                                //         color: Colors.black, size: 35),
                                                //   )),
                                                // ),
                                                Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: Container(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        decoration: BoxDecoration(
                                                            color:
                                                                Color.fromRGBO(
                                                                    200,
                                                                    20,
                                                                    90,
                                                                    0.8),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                        height: 40,
                                                        child: Column(
                                                          children: [
                                                            SizedBox(height: 4),
                                                            Center(
                                                              child: Text(
                                                                  "${allTracks[item].name!.length > 10 ? allTracks[item].name!.substring(0, 10) : allTracks[item].name}",
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          "Montserrat",
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white)),
                                                            ),
                                                            SizedBox(height: 4),
                                                            Center(
                                                              child: Text(
                                                                  "${allTracks[item].artistName}",
                                                                  style: TextStyle(
                                                                      fontFamily:
                                                                          "Montserrat",
                                                                      fontSize:
                                                                          9,
                                                                      color: Colors
                                                                          .white)),
                                                            ),
                                                          ],
                                                        ))),
                                              ],
                                            ),
                                          ));
                                    },
                                  ),
                                )
                              : Center(child: Text("What's going on?"));
                        } else {
                          return Center(child: Text("Loading..."));
                        }
                      })),
              SizedBox(height: 20),
              Container(
                  margin: EdgeInsets.only(top: 10, bottom: 20),
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.all(0),
                  child: Text("By Genre",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 15,
                          fontWeight: FontWeight.bold))),
              FutureBuilder<List<Genre>>(
                  future: loadGenres(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.data == null) {
                      return Center(
                        child: Text("Loading..."),
                        //   child: SpinKitPulse(
                        // color: Colors.blue,
                        // size: 100.0,
                        // controller: AnimationController(
                        //     vsync: this,
                        //     duration: const Duration(milliseconds: 200))),
                      );
                    } else {
                      return Container(
                          width: MediaQuery.of(context).size.width,
                          child: GridView.count(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            mainAxisSpacing: 15,
                            childAspectRatio: 2 / 2.4,
                            crossAxisSpacing: 15,
                            children: List.generate(
                                allGenres.length > 30 ? 20 : allGenres.length,
                                (index) {
                              return GestureDetector(
                                  onTap: () async {
                                    String? genreId = allGenres[index].id;
                                    String? genreName = allGenres[index].name;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Popular(
                                            playlistEnabled: false,
                                            genreId: genreId,
                                            genreName: genreName),
                                      ),
                                    );
                                    print(allGenres[index].id);
                                  },
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 2,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 100,
                                          decoration: BoxDecoration(
                                              image: const DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: NetworkImage(
                                                      "https://t3.ftcdn.net/jpg/04/54/66/12/360_F_454661277_NtQYM8oJq2wOzY1X9Y81FlFa06DVipVD.jpg")),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          width:
                                              MediaQuery.of(context).size.width,
                                        ),
                                        Align(
                                            alignment: Alignment.center,
                                            child: Container(
                                                height: 35,
                                                margin:
                                                    EdgeInsets.only(bottom: 10),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                decoration: BoxDecoration(
                                                    color: Color.fromRGBO(
                                                        20, 20, 20, 0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                child: Column(
                                                  children: [
                                                    SizedBox(height: 10),
                                                    Center(
                                                      child: Text(
                                                          "${allGenres[index].name}",
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  "Montserrat",
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ],
                                                ))),
                                      ],
                                    ),
                                  ));
                            }),
                          ));
                    }
                  }),
            ],
          )),
    );
  }
}
