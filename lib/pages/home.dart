import 'dart:convert';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_zx/model/track.dart';
import 'package:stream_zx/model/genre.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'homepage.dart';
import 'playlistpage.dart';
import 'settingspage.dart';
import 'favorites.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
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

class _HomeState extends State<Home> {
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
  Color? _thumbColor;
  Color? _thumbGlowColor;
  var _thumbCanPaintOutsideBar = true;

  static List<Track> allTracks = [];
  static List<Genre> allGenres = [];
  late List<Widget> allWidgets = [
    Homepage(),
    Favorites(),
    PlaylistPage(),
    SettingsPage()
  ];

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

  void _changeCurrentTrack(int item) {
    setState(() {
      currentTrackIndex = item;
      isPlaying = true;
      selectedTrack['name'] = allTracks[item].name;
      selectedTrack['artistName'] = allTracks[item].artistName;
      selectedTrack['previewUrl'] = allTracks[item].previewUrl;
      selectedTrack['playbackSeconds'] = allTracks[item].playbackSeconds;
      isPaused = false;
    });
  }

  void _changePlayerState(a) {
    setState(() {
      isPlaying = a;
    });
  }

  void _decrementTrackIndex() async {
    if (currentTrackIndex > 0) {
      setState(() {
        currentTrackIndex--;
        selectedTrack['name'] = allTracks[currentTrackIndex].name;
        selectedTrack['artistName'] = allTracks[currentTrackIndex].artistName;
        selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl;
        selectedTrack['playbackSeconds'] =
            allTracks[currentTrackIndex].playbackSeconds;
        isPaused = false;
      });

      try {
        await audioPlayer.setUrl(
            "${selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl}");
        await audioPlayer.play();
      } catch (e) {
        print(e.toString());
      }
    }
  }

  void _incrementTrackIndex() async {
    if (currentTrackIndex < allTracks.length) {
      setState(() {
        currentTrackIndex++;
        selectedTrack['name'] = allTracks[currentTrackIndex].name;
        selectedTrack['artistName'] = allTracks[currentTrackIndex].artistName;
        selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl;
        selectedTrack['playbackSeconds'] =
            allTracks[currentTrackIndex].playbackSeconds;
        isPaused = false;
      });

      try {
        await audioPlayer.setUrl(
            "${selectedTrack['previewUrl'] = allTracks[currentTrackIndex].previewUrl}");
        await audioPlayer.play();
      } catch (e) {
        print(e.toString());
      }
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

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(child: allWidgets[currState]),
          bottomNavigationBar: !isPlaying
              ? Container(
                  height: 50,
                  padding: EdgeInsets.all(0),
                  margin: EdgeInsets.only(bottom: 10, left: 8, right: 10),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(50)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BottomNavigationBar(
                      selectedFontSize: 0,
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.grey.shade900,
                      showUnselectedLabels: false,
                      unselectedItemColor: Colors.grey.shade400,
                      showSelectedLabels: false,
                      selectedItemColor: Colors.red.shade600,
                      currentIndex: currState,
                      elevation: 20,
                      onTap: (i) {
                        print(i);
                        setState(() {
                          currState = i;
                        });
                      },
                      items: const [
                        BottomNavigationBarItem(
                            icon: Icon(
                              FontAwesomeIcons.house,
                              size: 20,
                            ),
                            label: ""),
                        BottomNavigationBarItem(
                            icon: Icon(
                              FontAwesomeIcons.heart,
                              size: 20,
                            ),
                            label: ""),
                        BottomNavigationBarItem(
                            icon: Icon(
                              FontAwesomeIcons.music,
                              size: 20,
                            ),
                            label: ""),
                        BottomNavigationBarItem(
                            icon: Icon(FontAwesomeIcons.circleUser, size: 20),
                            label: "")
                      ],
                    ),
                  ))
              : null),
    );
  }
}
