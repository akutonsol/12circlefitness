import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:circle_fitness/features/challenges/data/models/challenge_model.dart';
import 'package:circle_fitness/features/challenges/domain/challenge_provider.dart';
import 'package:circle_fitness/features/classes/data/models/class_model.dart';
import 'package:circle_fitness/features/classes/domain/class_provider.dart';
import 'package:circle_fitness/features/classes/domain/whats_on_provider.dart';
import 'package:circle_fitness/features/community/data/models/post_model.dart';
import 'package:circle_fitness/features/community/domain/community_provider.dart';
import 'package:circle_fitness/features/messaging/presentation/connect_sections_view.dart';

/// FIT-005 · the relationship layer's three teasers, mounted.
///
/// The rules are proved in `test/unit/connect_sections_test.dart`. These mount
/// the real sections over the real source providers, so "the rule exists but
/// nothing acts on it" fails rather than survives — the mutation that got
/// through on `/profile` and was only caught by running it.
void main() {
  CommunityPost post({String user = 'Priya', String content = 'Hit 70 kg'}) =>
      CommunityPost(
        id: 'p1',
        userId: 'u1',
        userName: user,
        userRole: 'client',
        content: content,
        type: PostType.text,
        imageUrls: const [],
        reactions: const [],
        comments: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

  CommunityGroup aGroup({String name = 'Tues Lifters'}) => CommunityGroup(
        id: 'g1',
        name: name,
        description: '',
        emoji: '🏋️',
        memberCount: 12,
        isJoined: true,
      );

  Override pin<T>(ProviderBase<AsyncValue<T>> p, AsyncValue<T> v) =>
      (p as FutureProvider<T>).overrideWith((ref) => v.when(
            data: (d) => d,
            error: (e, s) => Future<T>.error(e, s),
            loading: () => Completer<T>().future,
          ));

  Future<void> mount(
    WidgetTester t, {
    AsyncValue<List<CommunityPost>> posts = const AsyncData([]),
    AsyncValue<List<CommunityGroup>> groups = const AsyncData([]),
    AsyncValue<List<FitnessClass>> classes = const AsyncData([]),
  }) async {
    await t.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(ProviderScope(
      overrides: [
        pin(livePostsProvider, posts),
        pin(liveGroupsProvider, groups),
        pin(liveClassesFromDbProvider, classes),
        pin(whatsOnEventsProvider, const AsyncData(<Map<String, dynamic>>[])),
        pin(liveChallengesProvider, const AsyncData(<Challenge>[])),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ConnectSectionsView()),
        ),
      ),
    ));
    await t.pump();
  }

  testWidgets('FIT-005 the three declared sections are present, in order',
      (t) async {
    await mount(t);
    // Feed, Groups and What's on are all labels the design package declares.
    for (final title in ['Feed', 'Groups', "What's on"]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(t.getTopLeft(find.text('Feed')).dy,
        lessThan(t.getTopLeft(find.text('Groups')).dy));
    expect(t.getTopLeft(find.text('Groups')).dy,
        lessThan(t.getTopLeft(find.text("What's on")).dy));
  });

  testWidgets('FIT-005 a post and a group render as the anchor draws them',
      (t) async {
    await mount(t,
        posts: AsyncData([post()]), groups: AsyncData([aGroup()]));

    expect(find.text('Priya Hit 70 kg · 2h'), findsOneWidget);
    expect(find.text('Tues Lifters · 12 members'), findsOneWidget);
  });

  group('FIT-005 a failed section is never drawn as an empty one', () {
    testWidgets('the feed failing names the failure under its own heading',
        (t) async {
      await mount(t,
          posts: AsyncError(Exception('x'), StackTrace.empty),
          groups: AsyncData([aGroup()]));

      expect(find.text('Could not load posts'), findsOneWidget);
      // And the other sections are untouched — one failed read must not take
      // the working ones down with it.
      expect(find.text('Tues Lifters · 12 members'), findsOneWidget);
      expect(find.text('Could not load groups'), findsNothing);
    });

    testWidgets('the groups failing is reported, not silently omitted',
        (t) async {
      // Under a heading that says "Groups", an absence is an answer: it tells
      // the client they are in none.
      await mount(t, groups: AsyncError(Exception('x'), StackTrace.empty));

      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Could not load groups'), findsOneWidget);
    });

    testWidgets('a failure line never carries a raw exception', (t) async {
      await mount(t, posts: AsyncError(Exception('offline'), StackTrace.empty));
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('offline'), findsNothing);
    });

    testWidgets('an empty section states nothing rather than guessing',
        (t) async {
      // FIT-005 declares no empty copy for these teasers, so the section is
      // quiet and offers the way to the screen that owns it. Writing three
      // sentences here would be OD-8.
      await mount(t);
      expect(find.textContaining('Could not load'), findsNothing);
      expect(find.text('Open Feed'), findsOneWidget);
    });
  });

  testWidgets('FIT-005 a section still loading renders nothing at all',
      (t) async {
    // Not a spinner per section — three stacked under a conversation list is
    // noise — and above all not an empty section, which would be a claim.
    await mount(t, posts: const AsyncLoading());

    expect(find.text('Feed'), findsNothing);
    expect(find.text('Could not load posts'), findsNothing);
    // The sections that did resolve are unaffected.
    expect(find.text('Groups'), findsOneWidget);
  });

  group('FIT-005 each section offers the way to its own screen', () {
    testWidgets('the affordance is named for the section it opens', (t) async {
      final handle = t.ensureSemantics();
      await mount(t);

      for (final title in ['Feed', 'Groups', "What's on"]) {
        final finder = find.bySemanticsLabel('Open $title');
        expect(finder, findsOneWidget,
            reason: 'a screen reader must hear WHICH of the three it is');
        final d = t.getSemantics(finder).getSemanticsData();
        expect(d.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(d.hasAction(SemanticsAction.tap), isTrue,
            reason: 'excludeSemantics drops the child\'s actions with it');
      }
      handle.dispose();
    });

    testWidgets('and clears the 44 dp target floor', (t) async {
      await mount(t);
      for (final title in ['Feed', 'Groups', "What's on"]) {
        final size = t.getSize(find
            .ancestor(
                of: find.text('Open $title'), matching: find.byType(GestureDetector))
            .first);
        expect(size.height, greaterThanOrEqualTo(44.0), reason: title);
      }
    });
  });

  testWidgets('FIT-005 section titles are announced as headings', (t) async {
    // Three sections stacked under a conversation list are unnavigable without
    // headings — a screen reader user would have to walk every row.
    final handle = t.ensureSemantics();
    await mount(t);

    for (final title in ['Feed', 'Groups', "What's on"]) {
      expect(
          t.getSemantics(find.text(title)).getSemanticsData()
              .hasFlag(SemanticsFlag.isHeader),
          isTrue,
          reason: '$title must be a heading');
    }
    handle.dispose();
  });
}
