class StickerStats {
  const StickerStats({
    required this.owned,
    required this.duplicates,
    required this.missing,
  });

  final int owned;
  final int duplicates;
  final int missing;
}
