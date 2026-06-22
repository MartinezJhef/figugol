import 'dart:convert';
import 'package:http/http.dart' as http;

class FootballApiService {
  static const String _teamsUrl = 'https://raw.githubusercontent.com/rezarahiminia/worldcup2026/main/football.teams.json';
  static const String _matchesUrl = 'https://raw.githubusercontent.com/rezarahiminia/worldcup2026/main/football.matches.json';

  Future<String> fetchLastMatchResult() async {
    try {
      // Fetch both teams and matches
      final teamsResponse = await http.get(Uri.parse(_teamsUrl));
      final matchesResponse = await http.get(Uri.parse(_matchesUrl));

      if (teamsResponse.statusCode == 200 && matchesResponse.statusCode == 200) {
        final List teamsData = json.decode(teamsResponse.body);
        final List matchesData = json.decode(matchesResponse.body);

        // Map team IDs to team names
        final Map<String, String> teamsMap = {};
        for (var t in teamsData) {
          teamsMap[t['id']] = t['name_en'] ?? 'Equipo';
        }

        if (matchesData.isNotEmpty) {
          // Try to find the latest finished match, or the first match if none has finished.
          final finishedMatches = matchesData.where((m) => m['finished'] == 'TRUE' || m['finished'] == true).toList();
          final match = finishedMatches.isNotEmpty ? finishedMatches.last : matchesData.first;

          final team1Id = match['home_team_id']?.toString() ?? '';
          final team2Id = match['away_team_id']?.toString() ?? '';
          
          final team1Name = teamsMap[team1Id] ?? 'Equipo 1';
          final team2Name = teamsMap[team2Id] ?? 'Equipo 2';
          
          final score1 = match['home_score']?.toString() ?? '0';
          final score2 = match['away_score']?.toString() ?? '0';

          return '$team1Name $score1 - $score2 $team2Name';
        }
      }
      return 'Sin partidos recientes';
    } catch (e) {
      return 'Error conectando a la web';
    }
  }
}
