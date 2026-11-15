/// Saatsiz görev hatırlatması.
///
/// Saatsiz görevde `reminderMin` görev gününün 00:00'ına göre dakikadır:
/// -240 önceki akşam 20:00, 480 aynı gün 08:00. Boşsa ayardaki varsayılan
/// geçerlidir, [untimedReminderOff] kapalı demektir. Saatli girdilerde aynı
/// alan başlangıçtan kaç dakika önce olduğunu tutar.
library;

const untimedReminderOff = 100000;
const untimedEveningDefault = -240;
const untimedMorningDefault = 480;

enum UntimedMode { eveningBefore, sameDay, off }

UntimedMode untimedModeOf(int offset) {
  if (offset == untimedReminderOff) return UntimedMode.off;
  return offset < 0 ? UntimedMode.eveningBefore : UntimedMode.sameDay;
}

/// Bildirimin saati, gün içindeki dakika olarak (0–1439).
int untimedMinuteOfDay(int offset) => offset < 0 ? offset + 1440 : offset;

int untimedOffset(UntimedMode mode, int minuteOfDay) => switch (mode) {
  UntimedMode.eveningBefore => minuteOfDay - 1440,
  UntimedMode.sameDay => minuteOfDay,
  UntimedMode.off => untimedReminderOff,
};

bool isValidUntimedOffset(int offset) =>
    offset == untimedReminderOff || (offset >= -1440 && offset < 1440);

/// [day] günündeki saatsiz görevin hatırlatma anı, kapalıysa null.
DateTime? untimedReminderTime(DateTime day, int offset) {
  if (offset == untimedReminderOff || !isValidUntimedOffset(offset)) {
    return null;
  }
  return DateTime(day.year, day.month, day.day, 0, offset);
}
