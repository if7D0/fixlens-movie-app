import 'package:fixlens_movie_app/src/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app launches with bottom nav', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FixLensApp()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Watchlist'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
