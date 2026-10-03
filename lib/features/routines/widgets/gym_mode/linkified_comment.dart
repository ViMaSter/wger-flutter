import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkifiedComment extends StatefulWidget {
  final String text;
  final TextAlign textAlign;
  final Future<bool> Function(Uri, {LaunchMode mode}) launch;

  const LinkifiedComment(
    this.text, {
    super.key,
    this.textAlign = TextAlign.start,
    this.launch = launchUrl,
  });

  @override
  State<LinkifiedComment> createState() => _LinkifiedCommentState();
}

class _LinkifiedCommentState extends State<LinkifiedComment> {
  static final _urls = RegExp(r'''(?<![\w:/])https?://[^\s<>"']+''', caseSensitive: false);
  final _recognizers = <TapGestureRecognizer>[];
  final _failedUrls = <String>{};

  Uri? _httpUri(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          RegExp(r'[\s\x00-\x1f\x7f\\/?#@]').hasMatch(Uri.decodeComponent(uri.host)) ||
          uri.port > 65535 ||
          url.contains(r'\') ||
          uri.userInfo.isNotEmpty ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        return null;
      }
      return uri;
    } on FormatException {
      return null;
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void didUpdateWidget(LinkifiedComment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.launch != widget.launch) {
      _failedUrls.clear();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Future<void> _open(Uri uri, String text) async {
    var opened = false;
    try {
      opened = await widget.launch(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      setState(() => _failedUrls.add(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _urls.allMatches(widget.text)) {
      var url = match.group(0)!;
      while (url.isNotEmpty && '.,;:!?'.contains(url[url.length - 1])) {
        url = url.substring(0, url.length - 1);
      }
      while (url.endsWith(')') && ')'.allMatches(url).length > '('.allMatches(url).length) {
        url = url.substring(0, url.length - 1);
      }
      final uri = _httpUri(url);
      if (uri == null) {
        continue;
      }
      spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      TapGestureRecognizer? recognizer;
      if (!_failedUrls.contains(url)) {
        recognizer = TapGestureRecognizer()..onTap = () => _open(uri, url);
        _recognizers.add(recognizer);
      }
      spans.add(
        TextSpan(
          text: url,
          recognizer: recognizer,
          style: recognizer == null
              ? null
              : TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
        ),
      );
      offset = match.start + url.length;
    }
    if (spans.isEmpty) {
      return Text(widget.text, textAlign: widget.textAlign);
    }
    spans.add(TextSpan(text: widget.text.substring(offset)));
    return Text.rich(TextSpan(children: spans), textAlign: widget.textAlign);
  }
}
