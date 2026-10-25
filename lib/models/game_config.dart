/// Танзимоти бозии офлайн
class GameConfig {
  final String mode; // classic | survival
  final String category; // all | general | geography | ...
  final String difficulty; // all | easy | medium | hard
  final String type; // all | choice | text | match
  final int count;
  final int time;
  final String source; // json | admin | both

  const GameConfig({
    this.mode = 'classic',
    this.category = 'all',
    this.difficulty = 'all',
    this.type = 'all',
    this.count = 10,
    this.time = 20,
    this.source = 'json',
  });
}
