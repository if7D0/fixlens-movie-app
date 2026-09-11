import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/app_result.dart';
import '../../account/presentation/account_provider.dart';
import '../data/models/review.dart';
import 'reviews_provider.dart';

/// Bottom sheet for writing/editing my review (rating 1-10 + text ≤500).
class ReviewSheet extends ConsumerStatefulWidget {
  final int movieId;
  final String uid;

  const ReviewSheet({super.key, required this.movieId, required this.uid});

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  double _rating = 7;
  late final TextEditingController _text = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _prefilled = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Prefills once the existing review loads (listener runs off-build,
  /// so setState is safe here).
  void _listenExisting() {
    ref.listen(
      myReviewProvider((movieId: widget.movieId, uid: widget.uid)),
      (_, next) {
        if (_prefilled) return;
        final data = switch (next) {
          AsyncData(value: final v) => v,
          _ => null,
        };
        if (data is AppOk<Review?> && data.data != null) {
          _prefilled = true;
          setState(() {
            _rating = data.data!.rating.toDouble();
            _text.text = data.data!.text;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(
      myReviewProvider((movieId: widget.movieId, uid: widget.uid)),
    );
    _listenExisting();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ulasanmu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _rating.toStringAsFixed(0),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _rating = v),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(_rating.toStringAsFixed(0)),
              ),
            ],
          ),
          TextField(
            controller: _text,
            enabled: !_saving,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Ceritakan pendapatmu (maks 500 karakter)…',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _submit(false),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ),
              const SizedBox(width: 8),
              if (_hasExisting(existing))
                TextButton(
                  onPressed: _saving ? null : () => _submit(true),
                  child: const Text('Hapus'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasExisting(AsyncValue<AppResult<Review?>> existing) {
    final data = switch (existing) {
      AsyncData(value: final v) => v,
      _ => null,
    };
    return data is AppOk<Review?> && data.data != null;
  }

  Future<void> _submit(bool delete) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(reviewRepositoryProvider);
    final AppResult<void> res = delete
        ? await repo.deleteMyReview(movieId: widget.movieId, uid: widget.uid)
        : await repo.upsertReview(
            movieId: widget.movieId,
            uid: widget.uid,
            displayName:
                ref.read(accountProvider).user?.displayName ?? 'Anonim',
            rating: _rating.toInt(),
            text: _text.text,
          );
    ref.invalidate(summaryProvider(widget.movieId));
    ref.invalidate(reviewsProvider(widget.movieId));
    ref.invalidate(
      myReviewProvider((movieId: widget.movieId, uid: widget.uid)),
    );
    ref.invalidate(myReviewsProvider(widget.uid));
    if (!mounted) return;
    switch (res) {
      case AppOk():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(delete ? 'Ulasan dihapus' : 'Ulasan tersimpan'),
          ),
        );
      case AppErr(message: final m):
        setState(() {
          _saving = false;
          _error = m;
        });
    }
  }
}
