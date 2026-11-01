import 'dates.dart';

enum ItemKind { task, event }

const _keep = Object();

class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.day,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.start,
    this.end,
    this.doneAt,
    this.important = false,
    this.rolledCount = 0,
    this.anchorDay,
    this.reminderMin,
    this.snoozedUntil,
    this.deletedAt,
  });

  final String id;
  final ItemKind kind;
  final String title;
  final String? notes;

  /// Girdinin göründüğü gün. [start] varsa onun günüdür.
  final DateTime day;
  final DateTime? start;
  final DateTime? end;
  final DateTime? doneAt;
  final bool important;
  final int rolledCount;

  /// Görev ömrü sayacının başladığı gün, etkinliklerde boş.
  final DateTime? anchorDay;

  /// Başlangıçtan kaç dakika önce hatırlatılacağı, boşsa hatırlatma yok.
  final int? reminderMin;
  final DateTime? snoozedUntil;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTask => kind == ItemKind.task;
  bool get isDone => doneAt != null;
  bool get isTimed => start != null;
  bool get isDeleted => deletedAt != null;

  bool isOverdue(DateTime now) {
    if (!isTask || isDone) return false;
    if (start != null) return start!.isBefore(now);
    return day.isBefore(dayOnly(now));
  }

  /// Görevi saatini koruyarak [target] gününe taşır.
  AgendaItem movedTo(DateTime target, {required int rolledBy}) {
    final shift = daysBetween(day, target);
    return copyWith(
      day: dayOnly(target),
      start: start == null ? null : addDays(start!, shift),
      end: end == null ? null : addDays(end!, shift),
      rolledCount: rolledCount + rolledBy,
      snoozedUntil: null,
    );
  }

  AgendaItem copyWith({
    ItemKind? kind,
    String? title,
    Object? notes = _keep,
    DateTime? day,
    Object? start = _keep,
    Object? end = _keep,
    Object? doneAt = _keep,
    bool? important,
    int? rolledCount,
    Object? anchorDay = _keep,
    Object? reminderMin = _keep,
    Object? snoozedUntil = _keep,
    Object? deletedAt = _keep,
    DateTime? updatedAt,
  }) => AgendaItem(
    id: id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    notes: identical(notes, _keep) ? this.notes : notes as String?,
    day: day ?? this.day,
    start: identical(start, _keep) ? this.start : start as DateTime?,
    end: identical(end, _keep) ? this.end : end as DateTime?,
    doneAt: identical(doneAt, _keep) ? this.doneAt : doneAt as DateTime?,
    important: important ?? this.important,
    rolledCount: rolledCount ?? this.rolledCount,
    anchorDay: identical(anchorDay, _keep)
        ? this.anchorDay
        : anchorDay as DateTime?,
    reminderMin: identical(reminderMin, _keep)
        ? this.reminderMin
        : reminderMin as int?,
    snoozedUntil: identical(snoozedUntil, _keep)
        ? this.snoozedUntil
        : snoozedUntil as DateTime?,
    deletedAt: identical(deletedAt, _keep)
        ? this.deletedAt
        : deletedAt as DateTime?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Bir günün girdilerini ekrandaki bölümlere ayırır.
class DayGroups {
  DayGroups._(this.overdue, this.untimed, this.timed);

  factory DayGroups.from(Iterable<AgendaItem> items, DateTime day) {
    final overdue = <AgendaItem>[];
    final untimed = <AgendaItem>[];
    final timed = <AgendaItem>[];
    for (final item in items) {
      if (item.day.isBefore(day)) {
        overdue.add(item);
      } else if (item.isTimed) {
        timed.add(item);
      } else {
        untimed.add(item);
      }
    }
    overdue.sort((a, b) => a.day.compareTo(b.day));
    untimed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    timed.sort((a, b) => a.start!.compareTo(b.start!));
    return DayGroups._(overdue, untimed, timed);
  }

  final List<AgendaItem> overdue;
  final List<AgendaItem> untimed;
  final List<AgendaItem> timed;

  bool get isEmpty => overdue.isEmpty && untimed.isEmpty && timed.isEmpty;
}
