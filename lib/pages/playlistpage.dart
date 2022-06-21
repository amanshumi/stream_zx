import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:stream_zx/model/playlist.dart';
import 'package:stream_zx/pages/popular.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Playlist> allPlaylists = [];
  static String apiKey = "MGVjN2VmMWItZjc5OS00MDNkLTkxYTktYWQ5MmUxNTA0MDQ2";

  Future loadPlaylist() async {
    var res =
        await get("http://api.napster.com/v2.2/playlists?apikey=${apiKey}");

    Map<String, dynamic> wholePlaylist = jsonDecode(res.body);

    List<dynamic> parsed = wholePlaylist['playlists'];

    for (var item in parsed) {
      allPlaylists.add(Playlist(
          type: item['type'],
          id: item['id'],
          name: item['name'],
          trackCount: item['trackCount'],
          privacy: item['privacy'],
          favoriteCount: item['favoriteCount'],
          url: item['images'][0]['url']));
    }

    return allPlaylists;
  }

  @override
  Widget build(BuildContext context) {
    loadPlaylist();

    return Scaffold(
      body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Icon(
                  Icons.playlist_play,
                  size: 45,
                ),
                const Text("Playlists",
                    style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Montserrat")),
              ]),
              SizedBox(height: 20),
              Text("Total count 30",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      fontFamily: "Montserrat")),
              SizedBox(height: 10),
              Expanded(
                child: FutureBuilder(
                    future: loadPlaylist(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        return Container(
                            child: ListView.builder(
                                itemCount: allPlaylists.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Popular(
                                                playlistEnabled: true,
                                                playListId:
                                                    allPlaylists[index].id,
                                                playListName:
                                                    allPlaylists[index].name),
                                          ),
                                        );
                                      },
                                      child: Container(
                                          padding: EdgeInsets.all(3),
                                          child: Column(
                                            children: [
                                              SizedBox(height: 10),
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          offset: Offset(5, 5),
                                                          blurRadius: 10,
                                                          color: Colors
                                                              .grey.shade200)
                                                    ]),
                                                child: Row(children: [
                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    child: CircleAvatar(
                                                      backgroundImage: NetworkImage(
                                                          "${allPlaylists[index].url}"),
                                                      // child: Image(
                                                      //     fit: BoxFit.cover,
                                                      //     height: 60,
                                                      //     width: 60,
                                                      //     image: NetworkImage(
                                                      //         "${allPlaylists[index].url}")),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            "${allPlaylists[index].name}",
                                                            style: TextStyle(
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    "Montserrat")),
                                                        SizedBox(height: 5),
                                                        Text(
                                                            "Track count : ${allPlaylists[index].trackCount}",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                fontFamily:
                                                                    "Montserrat")),
                                                      ])
                                                ]),
                                              )
                                            ],
                                          )));
                                }));
                      }
                    }),
              )
            ],
          )),
    );
  }
}
