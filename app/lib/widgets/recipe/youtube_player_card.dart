import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:whipup/theme/app_theme.dart';

/// YouTube 영상을 인앱 WebView로 재생하는 카드.
///
/// 초기엔 YouTube 썸네일 + 재생 버튼을 표시하고,
/// 탭하면 WebView로 전환하여 인앱 재생한다.
/// YouTube URL이 아니면 "외부에서 보기" 폴백 카드를 표시한다.
class YouTubePlayerCard extends StatefulWidget {
  const YouTubePlayerCard({
    super.key,
    required this.videoUrl,
    this.onTimeUpdate,
  });

  final String videoUrl;

  /// 영상 재생 중 현재 시간(초)을 받는 콜백. null이면 시간 추적 비활성.
  final void Function(double seconds)? onTimeUpdate;

  /// YouTube URL에서 videoId를 추출한다.
  static String? extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host == 'youtu.be') return uri.pathSegments.firstOrNull;
    if (host.contains('youtube.com')) {
      if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'shorts') return segments[1];
      if (segments.length >= 2 && segments[0] == 'embed') return segments[1];
    }
    return null;
  }

  @override
  State<YouTubePlayerCard> createState() => _YouTubePlayerCardState();
}

class _YouTubePlayerCardState extends State<YouTubePlayerCard> {
  bool _playing = false;
  WebViewController? _controller;
  bool _webViewError = false;

  void _onPlayTapped() {
    final videoId = YouTubePlayerCard.extractYouTubeId(widget.videoUrl);
    if (videoId == null) return;
    setState(() => _playing = true);
    _initWebView(videoId);
  }

  void _initWebView(String videoId) {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final url = request.url;
              // YouTube embed, CDN, about:blank 만 허용 — 그 외는 차단해
              // 유튜브 앱/외부 브라우저로 빠져나가지 않도록 한다.
              if (url == 'about:blank' ||
                  url.contains('youtube.com/embed') ||
                  url.contains('youtube-nocookie.com') ||
                  url.contains('googlevideo.com') ||
                  url.contains('ytimg.com') ||
                  url.startsWith('blob:') ||
                  url.startsWith('data:')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..addJavaScriptChannel(
          'TimeChannel',
          onMessageReceived: (msg) {
            final t = double.tryParse(msg.message);
            if (t != null) widget.onTimeUpdate?.call(t);
          },
        )
        ..addJavaScriptChannel(
          'ErrorChannel',
          onMessageReceived: (_) {
            if (mounted) setState(() => _webViewError = true);
          },
        )
        ..loadHtmlString(_buildHtml(videoId));

      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _webViewError = true);
    }
  }

  String _buildHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#000; overflow:hidden; }
  #player { width:100vw; height:100vh; }
</style>
</head>
<body>
<div id="player"></div>
<script src="https://www.youtube.com/iframe_api"></script>
<script>
var player;
function onYouTubeIframeAPIReady() {
  player = new YT.Player('player', {
    videoId: '$videoId',
    playerVars: { autoplay: 1, controls: 1, rel: 0, modestbranding: 1 },
    events: {
      onReady: function(e) {
        e.target.playVideo();
        setInterval(function() {
          try {
            if (player && player.getPlayerState && player.getPlayerState() === 1) {
              TimeChannel.postMessage(player.getCurrentTime().toString());
            }
          } catch(e) {}
        }, 500);
      },
      onError: function(e) {
        try { ErrorChannel.postMessage(e.data.toString()); } catch(ex) {}
      }
    }
  });
}
</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    final videoId = YouTubePlayerCard.extractYouTubeId(widget.videoUrl);

    // YouTube URL이 아닌 경우 폴백
    if (videoId == null) return _FallbackCard(videoUrl: widget.videoUrl);

    // 재생 전: 썸네일 표시
    if (!_playing) {
      return _ThumbnailCard(videoId: videoId, onTap: _onPlayTapped);
    }

    // WebView 에러: 썸네일 + 외부 열기
    if (_webViewError) {
      return _ThumbnailCard(
        videoId: videoId,
        onTap: () async {
          final uri = Uri.tryParse(widget.videoUrl);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        showExternalIcon: true,
      );
    }

    // WebView 로딩 중: 썸네일 + 스피너
    if (_controller == null) {
      return _ThumbnailCard(videoId: videoId, loading: true);
    }

    // WebView 재생
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: WebViewWidget(controller: _controller!),
    );
  }
}

// ─── 썸네일 카드 ──────────────────────────────────────────────────────────────

/// YouTube 썸네일과 재생 버튼 오버레이를 표시하는 카드.
class _ThumbnailCard extends StatelessWidget {
  const _ThumbnailCard({
    required this.videoId,
    this.onTap,
    this.loading = false,
    this.showExternalIcon = false,
  });

  final String videoId;
  final VoidCallback? onTap;
  final bool loading;
  final bool showExternalIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── YouTube 썸네일 ────────────────────────────────────
            Image.network(
              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
              ),
            ),

            // ─── 어두운 오버레이 ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ─── 재생 / 로딩 버튼 ──────────────────────────────────
            Center(
              child: loading
                  ? Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: showExternalIcon
                            ? Colors.black.withValues(alpha: 0.6)
                            : AppTheme.flameOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (showExternalIcon
                                    ? Colors.black
                                    : AppTheme.flameOrange)
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        showExternalIcon
                            ? Icons.open_in_new_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
            ),

            // ─── YouTube 로고 배지 ──────────────────────────────────
            if (!loading)
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'YouTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 비 YouTube URL 폴백 카드 ─────────────────────────────────────────────────

/// 비 YouTube URL 시 표시하는 폴백 카드.
class _FallbackCard extends StatelessWidget {
  const _FallbackCard({required this.videoUrl});
  final String videoUrl;

  String get _domain {
    final uri = Uri.tryParse(videoUrl);
    return uri?.host ?? videoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(videoUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1410), Color(0xFF3D2412)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.flameOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.flameOrange.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 12),
            Text(
              '원본 영상 보기',
              style: tt.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _domain,
              style: tt.labelSmall
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
