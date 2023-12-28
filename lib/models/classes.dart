class Idea {
  String title;
  String content;
  String source;

  Idea({required this.title, required this.content, required this.source});

  Idea.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        content = json['content'],
        source = json['source'];

  Map<String, dynamic> toJson() =>
      {'title': title, 'content': content, 'source': source};
}
