import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'article.dart';

class ArticleDetails extends StatefulWidget {
  final Article article;

  ArticleDetails({required this.article});

  @override
  _ArticleDetailsState createState() => _ArticleDetailsState();
}

class _ArticleDetailsState extends State<ArticleDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildImage(String url) {
    return Image.asset('assets/$url');
  }

  Widget _buildContent() {
    return SingleChildScrollView(
        child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 100.0, // 设置最小高度
      ),
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Html(
            data: widget.article.content.replaceAll('\n', '<br>'),
            style: {
              "body": Style(margin: EdgeInsets.all(8.0)),
              "h2": Style(fontSize: FontSize(26)),
              "h4": Style(fontSize: FontSize(22)),
              "p": Style(
                  fontSize: FontSize(22),
                  padding: EdgeInsets.only(bottom: 8.0)),
            },
          )),
    ));
  }
}
