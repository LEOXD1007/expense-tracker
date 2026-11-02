import '../models/entry_type.dart';

/// Draft produced by a future speech parser, for example "午饭 35 块".
class VoiceDraft {
  const VoiceDraft({
    this.amountCents,
    this.type,
    this.categoryName,
    this.note,
    this.occurredOn,
  });

  final int? amountCents;
  final EntryType? type;
  final String? categoryName;
  final String? note;
  final DateTime? occurredOn;
}

/// v2 seam. The v1 app does not capture audio; the editor calls this so a
/// speech implementation can fill the entry form later.
abstract interface class VoiceEntryParser {
  Future<VoiceDraft?> parse(String utterance);
}

final class UnsupportedVoiceEntryParser implements VoiceEntryParser {
  const UnsupportedVoiceEntryParser();

  @override
  Future<VoiceDraft?> parse(String utterance) async => null;
}
