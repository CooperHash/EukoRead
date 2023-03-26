import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'article.dart';
import 'article_details.dart';
import 'platform_channel.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:ui' as ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformChannel.setWindowSizeToFraction(3 / 5, 1);
  runApp(ReadApp());
}

class ReadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Read App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Article> _articles = [];

  @override
  void initState() {
    super.initState();
    _getArticles();
  }

  void _getArticles() async {
    final articles = await Article.getArticles();
    setState(() {
      _articles = articles;
    });
  }

  void _addArticle(String url) async {
    await Article.addArticle(url);
    _getArticles();
  }

  Widget? _buildImage(String url) {
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        width: 24,
        height: 24,
      );
    } else {
      return Image.network(
        url,
        width: 24,
        height: 24,
      );
    }
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        return ListTile(
          // 在 ListView.builder 的 itemBuilder 中使用：
          leading: _articles[index].icon != null
              ? _buildImage(_articles[index].icon!)
              : null,
          title: Text(_articles[index].title),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('确认删除该文章？'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 关闭对话框
                        },
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // 调用删除方法
                          await Article.deleteArticle(_articles[index].uuid);
                          _getArticles();
                          Navigator.pop(context); // 关闭对话框
                        },
                        child: Text('确认'),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetails(article: _articles[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showUrlInputDialog(context),
      child: Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Read App'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 显示输入框
  void _showUrlInputDialog(BuildContext context) {
    final TextEditingController _urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Card(
            margin: EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: '请输入URL',
                      hintText: 'https://example.com',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // 处理输入逻辑
                      final String url = _urlController.text;
                      if (url.isNotEmpty) {
                        // 处理URL
                        _addArticle(url);
                      }
                      Navigator.pop(context); // 关闭对话框
                    },
                    child: Text('确定'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
