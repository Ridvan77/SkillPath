import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class _NewsItem {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String createdByName;

  _NewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.createdByName,
  });

  factory _NewsItem.fromJson(Map<String, dynamic> json) {
    return _NewsItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      createdByName: json['createdByName'] as String? ?? '',
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<_NewsItem> _news = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = true);

    try {
      final response =
          await ApiClient.get('/api/News?page=$_page&pageSize=$_pageSize');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?)
                ?.map((e) => _NewsItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final totalCount = data['totalCount'] as int? ?? 0;

        setState(() {
          if (refresh) {
            _news = items;
          } else {
            _news.addAll(items);
          }
          _hasMore = _news.length < totalCount;
          _page++;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return DateFormat('dd.MM.yyyy').format(date);
    if (diff.inDays > 0) return 'prije ${diff.inDays} dana';
    if (diff.inHours > 0) return 'prije ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'prije ${diff.inMinutes} min';
    return 'upravo sada';
  }

  void _openDetail(_NewsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NewsDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vijesti'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchNews(refresh: true),
        child: _isLoading && _news.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _news.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.newspaper_outlined,
                                  size: 40, color: primaryColor),
                            ),
                            const SizedBox(height: 20),
                            const Text('Nema vijesti za prikaz',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text('Povucite prema dolje za osvjezavanje',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _news.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _news.length) {
                        _fetchNews();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = _news[index];
                      final card = index == 0
                          ? _buildFeaturedCard(item, primaryColor)
                          : _buildNewsCard(item, primaryColor);
                      return GestureDetector(
                        onTap: () => _openDetail(item),
                        child: card,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildFeaturedCard(_NewsItem item, Color primaryColor) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or gradient header
            Stack(
              children: [
                if (hasImage)
                  Image.network(
                    item.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.newspaper, color: Colors.white38, size: 60),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.newspaper, color: Colors.white38, size: 60),
                    ),
                  ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                ),
                // Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NAJNOVIJE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, size: 16, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.createdByName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(item.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(_NewsItem item, Color primaryColor) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or color accent
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  item.imageUrl!,
                  width: 110,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 130,
                    color: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.image, color: primaryColor.withOpacity(0.3)),
                  ),
                ),
              )
            else
              Container(
                width: 6,
                height: 130,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hasImage ? 14 : 16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: primaryColor.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          item.createdByName,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsDetailScreen extends StatelessWidget {
  final _NewsItem item;

  const _NewsDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final dateStr = DateFormat('dd.MM.yyyy').format(item.createdAt);
    final timeStr = DateFormat('HH:mm').format(item.createdAt);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing app bar with image
          SliverAppBar(
            expandedHeight: hasImage ? 260 : 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.newspaper, color: Colors.white24, size: 80),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author & date row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor.withOpacity(0.15),
                          child: Icon(Icons.person, size: 20, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.createdByName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dateStr u $timeStr',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Full content
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
