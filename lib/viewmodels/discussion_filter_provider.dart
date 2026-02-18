import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Time-based filter for discussions
enum TimeFilter { all, thisWeek, thisMonth }

/// Sort order for discussions
enum SortFilter { topRated, newest }

/// Immutable state holding the current filter selections
class DiscussionFilterState {
  final TimeFilter timeFilter;
  final SortFilter sortFilter;

  const DiscussionFilterState({
    this.timeFilter = TimeFilter.all,
    this.sortFilter = SortFilter.topRated,
  });

  DiscussionFilterState copyWith({
    TimeFilter? timeFilter,
    SortFilter? sortFilter,
  }) {
    return DiscussionFilterState(
      timeFilter: timeFilter ?? this.timeFilter,
      sortFilter: sortFilter ?? this.sortFilter,
    );
  }

  /// Returns the DateTime cutoff for the current time filter, or null for "all"
  DateTime? get timeCutoff {
    final now = DateTime.now();
    switch (timeFilter) {
      case TimeFilter.thisWeek:
        return now.subtract(const Duration(days: 7));
      case TimeFilter.thisMonth:
        return now.subtract(const Duration(days: 30));
      case TimeFilter.all:
        return null;
    }
  }
}

/// StateNotifier to manage filter state
class DiscussionFilterNotifier extends StateNotifier<DiscussionFilterState> {
  DiscussionFilterNotifier() : super(const DiscussionFilterState());

  void setTimeFilter(TimeFilter filter) {
    state = state.copyWith(timeFilter: filter);
  }

  void setSortFilter(SortFilter filter) {
    state = state.copyWith(sortFilter: filter);
  }
}

/// Global provider for the discussion filter state
final discussionFilterProvider =
    StateNotifierProvider<DiscussionFilterNotifier, DiscussionFilterState>(
      (ref) => DiscussionFilterNotifier(),
    );
