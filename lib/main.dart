import 'dart:io';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'article.dart';
import 'article_details.dart';
import 'platform_channel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:ui' as ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // window_size.DesktopWindow.setMinWindowSize(Size(375, 750));
    window_size.DesktopWindow.setMaxWindowSize(Size(1200, 1200));
  }
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
          trailing: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return CupertinoAlertDialog(
                    title: Text('确认删除该文章？'),
                    actions: [
                      CupertinoDialogAction(
                        child: Text('取消'),
                        onPressed: () {
                          Navigator.pop(context); // 关闭对话框
                        },
                      ),
                      CupertinoDialogAction(
                        child: Text('确认'),
                        onPressed: () async {
                          // 调用删除方法
                          await Article.deleteArticle(_articles[index].uuid);
                          _getArticles();
                          Navigator.pop(context); // 关闭对话框
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.destructiveRed,
            ),
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

  // Widget _buildFloatingActionButton(BuildContext context) {
  //   return FloatingActionButton(
  //     onPressed: () => _showUrlInputDialog(context),
  //     child: Icon(Icons.add),
  //   );
  // }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      width: 56.0,
      height: 56.0,
      child: FloatingActionButton(
        onPressed: () => _showUrlInputDialog(context),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
        tooltip: 'Add',
        elevation: 3.0,
        highlightElevation: 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EukoRead'),
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
        return CupertinoAlertDialog(
          title: Text('请输入URL'),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CupertinoTextField(
              controller: _urlController,
              placeholder: 'https://example.com',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('取消'),
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
              },
            ),
            CupertinoDialogAction(
              child: Text('确定'),
              onPressed: () {
                final String url = _urlController.text;
                if (url.isNotEmpty) {
                  _addArticle(url);
                }
                Navigator.pop(context); // 关闭对话框
              },
            ),
          ],
        );
      },
    );
  }
}
