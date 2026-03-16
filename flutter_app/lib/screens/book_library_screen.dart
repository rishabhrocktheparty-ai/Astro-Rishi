import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class BookLibraryScreen extends StatefulWidget {
  const BookLibraryScreen({super.key});
  @override
  State<BookLibraryScreen> createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BookProvider>().loadBooks();
      context.read<BookProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Knowledge Library')),
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats bar
                if (bp.stats != null) _StatsBar(stats: bp.stats!),
                const SizedBox(height: 20),

                Text('Source Texts', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'The AI learns astrology principles from these classical texts.',
                  style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 16),

                if (bp.isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: CosmicTheme.starGold),
                  ))
                else if (bp.books.isEmpty)
                  _EmptyLibrary()
                else
                  ...bp.books.map((b) => _BookCard(book: b)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CosmicTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CosmicTheme.starGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _StatItem(value: '${stats['books_processed'] ?? 0}', label: 'Books', color: CosmicTheme.starGold),
          _StatDivider(),
          _StatItem(value: '${stats['total_chunks'] ?? 0}', label: 'Chunks', color: CosmicTheme.celestialBlue),
          _StatDivider(),
          _StatItem(value: '${stats['graph_nodes'] ?? 0}', label: 'Concepts', color: CosmicTheme.venusGreen),
          _StatDivider(),
          _StatItem(value: '${stats['graph_edges'] ?? 0}', label: 'Relations', color: CosmicTheme.jupiterOrange),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
    ]));
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 30, color: CosmicTheme.borderGlow);
}

class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  Color _statusColor() {
    switch (book.processingStatus) {
      case 'completed': return CosmicTheme.venusGreen;
      case 'processing': case 'extracting': case 'embedding': return CosmicTheme.starGold;
      case 'failed': return CosmicTheme.marsRed;
      default: return CosmicTheme.rahuSmoke;
    }
  }

  IconData _statusIcon() {
    switch (book.processingStatus) {
      case 'completed': return Icons.check_circle;
      case 'processing': case 'extracting': case 'embedding': return Icons.hourglass_top;
      case 'failed': return Icons.error;
      default: return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: CosmicTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CosmicTheme.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: CosmicTheme.starGold.withOpacity(0.1),
              ),
              child: Icon(Icons.menu_book, color: CosmicTheme.starGold.withOpacity(0.7), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                if (book.author != null)
                  Text(book.author!, style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 11)),
              ],
            )),
            Icon(_statusIcon(), color: statusColor, size: 18),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (book.traditionName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CosmicTheme.celestialBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(book.traditionName!, style: const TextStyle(color: CosmicTheme.celestialBlue, fontSize: 10)),
              ),
            const SizedBox(width: 8),
            if (book.language != null)
              Text(book.language!.toUpperCase(), style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10, letterSpacing: 1)),
            const Spacer(),
            Text(book.processingStatus.replaceAll('_', ' '),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          if (book.isProcessing) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: book.processingProgress / 100,
                minHeight: 3,
                backgroundColor: CosmicTheme.surfaceDark,
                color: CosmicTheme.starGold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CosmicTheme.borderGlow),
      ),
      child: Column(children: [
        Icon(Icons.library_books_outlined, size: 48, color: CosmicTheme.rahuSmoke),
        const SizedBox(height: 16),
        const Text('No books in the library yet', style: TextStyle(color: CosmicTheme.moonSilver)),
        const SizedBox(height: 8),
        Text('Admin can upload Jyotish texts to train the AI.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 12)),
      ]),
    );
  }
}
