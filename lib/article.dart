import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

class Article {
  final String uuid;
  final String title;
  final String url;
  final String content;
  final String? icon;

  Article(
      {required this.uuid,
      required this.title,
      required this.url,
      required this.content,
      required this.icon});

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'title': title,
        'url': url,
        'content': content,
        'icon': icon
      };

  @override
  String toString() {
    return 'Article{uuid: $uuid, title: $title, url: $url, content: $content}';
  }

  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    print(directory);
    return File('${directory.path}/articles.txt');
  }

  static Future<void> deleteArticle(String uuid) async {
    final articles = await getArticles();
    articles.removeWhere((article) => article.uuid == uuid);
    await _writeArticles(articles);
  }

  static Future<File> _writeArticles(List<Article> articles) async {
    final file = await _localFile;
    final json =
        jsonEncode(articles.map((article) => article.toJson()).toList());
    return file.writeAsString(json);
  }

  static Future<List<Article>> getArticles() async {
    final file = await _localFile;
    if (!file.existsSync()) {
      return [];
    }
    final json = file.readAsStringSync();
    final List<dynamic> data = jsonDecode(json);
    return data
        .map((item) => Article(
            uuid: item['uuid'],
            title: item['title'],
            url: item['url'],
            content: item['content'],
            icon: item['icon']))
        .toList();
  }

  static Future<Article> parseArticle(String url) async {
    final unescape = HtmlUnescape();
    final uri = Uri.parse(url);
    final response = await http.get(Uri.parse(url));
    final document = parse(response.body);

    final linkTags = document.querySelectorAll('link[rel="icon"]');
    var iconHref = linkTags.isNotEmpty ? linkTags[0].attributes['href'] : '';
    if ((iconHref?.startsWith('/') ?? false)) {
      iconHref = 'https://' + uri.host + iconHref!;
    }

    final article = document.querySelector('article');
    final title = document.querySelector('title')?.text ?? '';
    var content = document.querySelector('article')?.outerHtml ?? '';
    // 去掉 video 标签
    content = content.replaceAll(RegExp(r'<video[^>]*>.*?</video>'), '');

    print('article $content');

    print('\n');
    print('uri $uri, host ${uri.host}');
    final host = '${uri.scheme}://${uri.host}';

    String _getFileName1(String url) {
      final uuid = Uuid().v4();
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final str = segments.last.replaceAll(' ', '') + '.jpg';
      return '${str}';
    }

    String _getFileName2(String url) {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      return '${segments.last}';
    }

    // 遍历所有的img标签
    final imgTags = article?.querySelectorAll('img') ?? [];
    print(imgTags);

    for (final imgTag in imgTags) {
      var tail = 1;
      var src = imgTag.attributes['src'];
      var oldsrc = imgTag.attributes['src'];
      if (src == null) continue;
      if (src.startsWith('/') ||
          (src.contains(',') && uri.host == 'www.nytimes.com')) {
        if (src.startsWith('/')) {
          src = '$host$src';
          print('without host $src');
        } else {
          print('nyt $src');
          src = src.split(',')[0];
        }

        if (!src.endsWith('.jpg') &&
            !src.endsWith('.jpeg') &&
            !src.endsWith('.png') &&
            !src.endsWith('.gif') &&
            !src.endsWith('.awebp') &&
            !src.endsWith('.awebp?')) {
          src += '.jpg';
        }

        final response = await http.get(Uri.parse(src));
        final bytes = response.bodyBytes;

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_image.jpg';
        // final fileName = _getFileName1(src);

        // 下载图片并保存到本地

        final file = File(fileName);
        await file.writeAsBytes(bytes);
        if (await file.exists()) {
          print('Download successful');
        } else {
          print('Download failed');
        }
        print('\n');
      } else if (src.startsWith('http') || src.startsWith('https')) {
        print('src $src');
        if (!src.endsWith('.jpg') &&
            !src.endsWith('.jpeg') &&
            !src.endsWith('.png') &&
            !src.endsWith('.gif') &&
            !src.endsWith('.awebp') &&
            !src.endsWith('.awebp?')) {
          src += '.jpg';
        }
        // 下载图片并保存到本地
        final response = await http.get(Uri.parse(src));
        final bytes = response.bodyBytes;
        final fileName = _getFileName2(src);
        final file = File('$fileName');
        await file.writeAsBytes(bytes);
        if (await file.exists()) {
          print('Download successful');
        } else {
          print('Download failed');
        }
        print('\n');
      }
    }

    content = content.replaceAllMapped(
      RegExp(r'src="([^"]*)"'),
      (match) {
        String encodedUrl = match.group(1) ?? '';
        String decodedUrl = Uri.decodeFull(unescape.convert(encodedUrl));
        return 'src="$decodedUrl"';
      },
    );

    content = content.replaceAllMapped(
      RegExp(r'(<img[^>]*)(\s*srcset="[^"]*")([^>]*>)', caseSensitive: false),
      (match) {
        return '${match.group(1)}${match.group(3)}';
      },
    );
    content = content.replaceAllMapped(RegExp(r'src="([^"]*?)"'), (match) {
      final src = match.group(1);
      if ((src?.contains('/_next') ?? false) ||
          (src?.startsWith('/images') ?? false)) {
        return 'src="${'https://${uri.host}$src'.replaceAll(' ', '')}"';
      } else {
        return 'src="$src"';
      }
    });

    content = content.replaceAllMapped(
      RegExp(r'src="([^"]*)"'),
      (match) {
        String encodedUrl = match.group(1) ?? '';
        String decodedUrl = Uri.decodeFull(encodedUrl);
        return 'src="$decodedUrl"';
      },
    );

    final uuid = Uuid().v4();

    return Article(
        uuid: uuid, title: title, url: url, content: content, icon: iconHref);
  }

  static Future<void> addArticle(String url) async {
    final article = await parseArticle(url);
    final articles = await getArticles();
    articles.add(article);
    await _writeArticles(articles);
  }
}
