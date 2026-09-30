class Dua {
  const Dua({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    this.source,
  });

  final String title;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String? source;
}

const List<Dua> duas = [
  Dua(
    title: 'Sübhaneke',
    arabic:
        'سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالٰى جَدُّكَ وَلَا اِلٰهَ غَيْرُكَ',
    transliteration:
        'Sübhânekellâhümme ve bi hamdik ve tebârakesmük ve teâlâ ceddük ve lâ ilâhe ğayruk.',
    meaning:
        'Allah\'ım! Sen eksik sıfatlardan pak ve uzaksın. Seni daima böyle tenzih eder ve överim. '
        'Senin adın mübarektir. Varlığın her şeyden üstündür. Senden başka ilah yoktur.',
  ),
  Dua(
    title: 'Rabbena Âtina',
    arabic:
        'رَبَّنَا اٰتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْاٰخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        'Rabbenâ âtinâ fi\'d-dünyâ haseneten ve fi\'l-âhirati haseneten ve kınâ azâbe\'n-nâr.',
    meaning:
        'Rabbimiz! Bize dünyada iyilik ver, ahirette de iyilik ver ve bizi cehennem azabından koru.',
    source: 'Bakara, 2/201',
  ),
  Dua(
    title: 'Rabbenağfirlî',
    arabic:
        'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
    transliteration:
        'Rabbenağfirlî ve li-vâlideyye ve li\'l-mü\'minîne yevme yekûmü\'l-hisâb.',
    meaning:
        'Rabbimiz! Hesap gününde beni, anamı, babamı ve bütün müminleri bağışla.',
    source: 'İbrâhîm, 14/41',
  ),
  Dua(
    title: 'Kelime-i Tevhid',
    arabic: 'لَا اِلٰهَ اِلَّا اللّٰهُ مُحَمَّدٌ رَسُولُ اللّٰهِ',
    transliteration: 'Lâ ilâhe illallâh Muhammedün Resûlullâh.',
    meaning: 'Allah\'tan başka ilah yoktur. Muhammed Allah\'ın elçisidir.',
  ),
];
