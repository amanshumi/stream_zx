class Track {
  String? id;
  String? href;
  int? tIndex;
  int? playbackSeconds;
  String? name;
  String? artistName;
  String? albumName;
  String? previewUrl;

  Track(
      {this.id,
      this.href,
      this.tIndex,
      this.playbackSeconds,
      this.name,
      this.artistName,
      this.albumName,
      this.previewUrl});

  factory Track.fromJson(Map<String, dynamic> json) {
    return new Track(
      id: json["id"] ?? "",
      href: json["href"] ?? "",
      tIndex: json["tIndex"] ?? 0,
      playbackSeconds: json["playbackSeconds"] ?? 0,
      name: json["name"] ?? "",
      artistName: json["artistName"] ?? "",
      albumName: json["albumName"] ?? "",
      previewUrl: json["previewUrl"] ?? "",
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      "id": this.id,
      "href": this.href,
      "tIndex": this.tIndex,
      "playbackSeconds": this.playbackSeconds,
      "name": this.name,
      "artistName": this.artistName,
      "albumName": this.albumName,
      "previewUrl": this.previewUrl,
    };
  }
}
