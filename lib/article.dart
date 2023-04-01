import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
    print('write articles');
    final file = await _localFile;
    final json =
        jsonEncode(articles.map((article) => article.toJson()).toList());
    return file.writeAsString(json);
  }

  static Future<List<Article>> getArticles() async {
    print('get articles');
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
    print('parseArticle $url');
    final unescape = HtmlUnescape();
    final uri = Uri.parse(url);
    final response = await http.get(Uri.parse(url));
    final document = parse(response.body);
    print('document ${document.outerHtml}}');
    final linkTags = document.querySelectorAll('link[rel*="icon"]');
    var iconHref = linkTags.isNotEmpty ? linkTags[0].attributes['href'] : '';
    if ((iconHref?.startsWith('/') ?? false)) {
      iconHref = 'https://' + uri.host + iconHref!;
    }

    final article = document.querySelector('article');

    var content = '';
    var title = '';
    // 判断文章来源网站
    if (Uri.parse(url).host == 'mp.weixin.qq.com') {
      // 获取微信公众号文章正文
      content = document.getElementById('page-content')?.outerHtml ?? '';
      title = document.getElementById('activity-name')?.text ?? '';
    } else if (Uri.parse(url).host == 'www.zhihu.com') {
      // 获取知乎文章正文
      content = document.querySelector('div.RichText')?.outerHtml ?? '';
      title = document.querySelector('h1.QuestionHeader-title')?.text ?? '';
    } else if (Uri.parse(url).host == 'xiaohongshu.com') {
      content = document
              .querySelector('meta[name="description"]')
              ?.attributes['content'] ??
          '';
      title = document
              .querySelector('meta[property="og:title"]')
              ?.attributes['content'] ??
          '';
      print('content $content');
    } else {
      // 获取普通网站文章正文
      content = document.querySelector('article')?.outerHtml ?? '';
      title = document.querySelector('title')?.text ?? '';
    }

    // 去掉 video 标签
    content = content.replaceAll(RegExp(r'<video[^>]*>.*?</video>'), '');

    print('article content loaded');

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
      var src = imgTag.attributes['src'];
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

        try {
          final file = await DefaultCacheManager().getSingleFile(src);
          print('Cache successful: ${file.path}');
        } catch (e) {
          print('Cache failed: $e');
        }
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
        try {
          final file = await DefaultCacheManager().getSingleFile(src);
          print('Cache successful: ${file.path}');
        } catch (e) {
          print('Cache failed: $e');
        }
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

    final uuid = Uuid().v4();

    return Article(
        uuid: uuid, title: title, url: url, content: content, icon: iconHref);
  }

  static Future<void> addArticle(String url) async {
    print('before parse');
    final article = await parseArticle(url);
    print('after parse');
    final articles = await getArticles();
    articles.add(article);
    await _writeArticles(articles);
  }
}
