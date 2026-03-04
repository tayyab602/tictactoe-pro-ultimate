import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Global notifier for theme switching
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// ================= ENUMS =================
enum GameMode { multiplayer, bot }
enum BoardLevel { easy, medium, hard }
enum Difficulty { easy, medium, hard }

/// Custom Scroll Behavior to hide scrollbars globally
class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          scrollBehavior: NoScrollbarBehavior(),
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            fontFamily: 'Segoe UI',
            scaffoldBackgroundColor: const Color(0xFFF0F2F5),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            fontFamily: 'Segoe UI',
            scaffoldBackgroundColor: const Color(0xFF0f0c29),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}

/// ================= ANIMATED BACKGROUND =================
class AnimatedShapesBackground extends StatefulWidget {
  final Widget child;
  const AnimatedShapesBackground({super.key, required this.child});

  @override
  State<AnimatedShapesBackground> createState() => _AnimatedShapesBackgroundState();
}

class _AnimatedShapesBackgroundState extends State<AnimatedShapesBackground> with TickerProviderStateMixin {
  late List<ShapeModel> shapes;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    shapes = List.generate(15, (index) => ShapeModel());
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var shape in shapes) {
          shape.update();
        }
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [const Color(0xFF0f0c29), const Color(0xFF302b63), const Color(0xFF24243e)]
                      : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
                ),
              ),
            ),
            ...shapes.map((shape) => Positioned(
                  left: shape.x,
                  top: shape.y,
                  child: Opacity(
                    opacity: isDark ? 0.15 : 0.4,
                    child: Transform.rotate(
                      angle: shape.rotation,
                      child: _buildShape(shape, isDark),
                    ),
                  ),
                )),
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildShape(ShapeModel shape, bool isDark) {
    final color = isDark ? Colors.white : Colors.indigo.withOpacity(0.5);
    switch (shape.type) {
      case ShapeType.circle:
        return Container(
          width: shape.size,
          height: shape.size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      case ShapeType.square:
        return Container(
          width: shape.size,
          height: shape.size,
          color: color,
        );
      case ShapeType.triangle:
        return CustomPaint(
          size: Size(shape.size, shape.size),
          painter: TrianglePainter(color: color),
        );
    }
  }
}

enum ShapeType { circle, square, triangle }

class ShapeModel {
  double x = Random().nextDouble() * 1500;
  double y = Random().nextDouble() * 1000;
  double size = Random().nextDouble() * 30 + 10;
  double speedX = (Random().nextDouble() - 0.5) * 1.5;
  double speedY = (Random().nextDouble() - 0.5) * 1.5;
  double rotation = Random().nextDouble() * pi;
  double rotationSpeed = (Random().nextDouble() - 0.5) * 0.05;
  ShapeType type = ShapeType.values[Random().nextInt(3)];

  void update() {
    x += speedX;
    y += speedY;
    rotation += rotationSpeed;

    if (x < -100) x = 1500;
    if (x > 1500) x = -100;
    if (y < -100) y = 1000;
    if (y > 1000) y = -100;
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// ================= LOGIN SCREEN =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final player1Controller = TextEditingController(text: "Player 1");
  final player2Controller = TextEditingController(text: "Player 2");

  GameMode selectedMode = GameMode.multiplayer;
  Difficulty selectedDifficulty = Difficulty.easy;
  BoardLevel selectedBoardLevel = BoardLevel.easy;

  void startGame() {
    if (player1Controller.text.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => TicTacToeGame(
          mode: selectedMode,
          difficulty: selectedMode == GameMode.bot ? selectedDifficulty : null,
          boardLevel: selectedBoardLevel,
          player1: player1Controller.text,
          player2: selectedMode == GameMode.multiplayer
              ? player2Controller.text
              : _getBotName(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
        },
      ),
    );
  }

  String _getBotName() {
    switch (selectedDifficulty) {
      case Difficulty.easy: return "Rookie Bot";
      case Difficulty.medium: return "Smart Bot";
      case Difficulty.hard: return "Unbeatable AI";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
        },
        child: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      ),
      body: AnimatedShapesBackground(
        child: Center(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Hero(
                    tag: 'game_content',
                    child: Card(
                      elevation: 20,
                      shadowColor: Colors.black54,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.grid_3x3, size: 64, color: isDark ? Colors.indigo.shade200 : const Color(0xFF302b63)),
                            const SizedBox(height: 16),
                            Text(
                              "TIC TAC TOE",
                              style: TextStyle(
                                  fontSize: 32,
                                  letterSpacing: 4,
                                  color: isDark ? Colors.white : const Color(0xFF302b63),
                                  fontWeight: FontWeight.w900),
                            ),
                            const Text("ULTIMATE EDITION", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 2)),
                            const SizedBox(height: 40),
                            _textField("Player 1 Name", player1Controller, Icons.person),
                            const SizedBox(height: 20),
                            
                            const Text("Game Mode", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            SegmentedButton<GameMode>(
                              segments: const [
                                ButtonSegment(value: GameMode.multiplayer, label: Text("PvP"), icon: Icon(Icons.people)),
                                ButtonSegment(value: GameMode.bot, label: Text("PvE"), icon: Icon(Icons.smart_toy)),
                              ],
                              selected: {selectedMode},
                              onSelectionChanged: (value) => setState(() => selectedMode = value.first),
                            ),
                            
                            const SizedBox(height: 24),

                            if (selectedMode == GameMode.multiplayer) ...[
                              _textField("Player 2 Name", player2Controller, Icons.person_outline),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<BoardLevel>(
                                value: selectedBoardLevel,
                                decoration: const InputDecoration(labelText: "Board Size", border: OutlineInputBorder()),
                                onChanged: (value) => setState(() => selectedBoardLevel = value!),
                                items: const [
                                  DropdownMenuItem(value: BoardLevel.easy, child: Text("3x3 Classic")),
                                  DropdownMenuItem(value: BoardLevel.medium, child: Text("4x4 Professional")),
                                  DropdownMenuItem(value: BoardLevel.hard, child: Text("5x5 Master")),
                                ],
                              ),
                            ] else ...[
                              DropdownButtonFormField<Difficulty>(
                                value: selectedDifficulty,
                                decoration: const InputDecoration(labelText: "AI Difficulty", border: OutlineInputBorder()),
                                onChanged: (value) => setState(() => selectedDifficulty = value!),
                                items: const [
                                  DropdownMenuItem(value: Difficulty.easy, child: Text("Easy")),
                                  DropdownMenuItem(value: Difficulty.medium, child: Text("Medium")),
                                  DropdownMenuItem(value: Difficulty.hard, child: Text("Hard")),
                                ],
                              ),
                            ],

                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: startGame,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF302b63),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                ),
                                child: const Text("LAUNCH GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String hint, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
    );
  }
}

/// ================= GAME SCREEN =================
class TicTacToeGame extends StatefulWidget {
  final GameMode mode;
  final Difficulty? difficulty;
  final BoardLevel boardLevel;
  final String player1;
  final String player2;

  const TicTacToeGame({
    super.key,
    required this.mode,
    required this.player1,
    required this.player2,
    required this.boardLevel,
    this.difficulty,
  });

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  late int boardSize;
  late List<String> board;

  bool isXturn = true;
  String? winner;
  int player1Score = 0;
  int player2Score = 0;
  int? hintIndex;
  int? lastMoveIndex;
  late int player1Hints;
  late int player2Hints;
  bool _dialogShowing = false;
  
  List<String> moveHistory = [];
  Timer? turnTimer;
  int secondsRemaining = 20;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _initGame(isInitial: true);
  }

  @override
  void dispose() {
    turnTimer?.cancel();
    super.dispose();
  }

  void _initGame({bool isInitial = false}) {
    boardSize = widget.boardLevel == BoardLevel.easy ? 3 : widget.boardLevel == BoardLevel.medium ? 4 : 5;
    board = List.filled(boardSize * boardSize, "");
    winner = null;
    isXturn = true;
    hintIndex = null;
    lastMoveIndex = null;
    moveHistory.clear();
    _dialogShowing = false;
    
    if (isInitial) {
      int initialHints = _getInitialHints();
      player1Hints = initialHints;
      player2Hints = initialHints;
    }
    _startTimer();
  }

  void _startTimer() {
    turnTimer?.cancel();
    secondsRemaining = 20;
    turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (winner != null || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
        } else {
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (widget.mode == GameMode.bot && !isXturn) return;
    List<int> empty = List.generate(board.length, (i) => i).where((i) => board[i] == "").toList();
    if (empty.isNotEmpty) {
      _handleTap(empty[random.nextInt(empty.length)], isAutoMove: true);
    }
  }

  int _getInitialHints() {
    dynamic level = widget.mode == GameMode.bot ? widget.difficulty : widget.boardLevel;
    if (level == Difficulty.easy || level == BoardLevel.easy) return -1;
    if (level == Difficulty.medium || level == BoardLevel.medium) return 3;
    return 1;
  }

  void _handleTap(int index, {bool isBotAction = false, bool isAutoMove = false}) {
    if (winner != null || board[index].isNotEmpty) return;
    if (widget.mode == GameMode.bot && !isXturn && !isBotAction) return;

    setState(() {
      String pName = isXturn ? widget.player1 : widget.player2;
      String symbol = isXturn ? 'X' : 'O';
      board[index] = symbol;
      lastMoveIndex = index;
      moveHistory.insert(0, "$pName: $symbol at Cell ${index + 1}${isAutoMove ? ' (Auto)' : ''}");
      
      isXturn = !isXturn;
      hintIndex = null;
      winner = _checkWinner();
      if (winner == null) _startTimer();
    });

    if (winner != null) {
      _updateScore();
      _showResult();
    } else if (widget.mode == GameMode.bot && !isXturn) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _botMove();
        }
      });
    }
  }

  void _botMove() {
    if (winner != null || !mounted) return;
    int move = _getBestMove('O');
    _handleTap(move, isBotAction: true);
  }

  int _getBestMove(String playerSymbol) {
    String opponentSymbol = playerSymbol == 'X' ? 'O' : 'X';
    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        board[i] = playerSymbol;
        if (_checkWinner() == playerSymbol) { board[i] = ""; return i; }
        board[i] = "";
      }
    }
    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        board[i] = opponentSymbol;
        if (_checkWinner() == opponentSymbol) { board[i] = ""; return i; }
        board[i] = "";
      }
    }
    List<int> empty = List.generate(board.length, (i) => i).where((i) => board[i] == "").toList();
    return empty[random.nextInt(empty.length)];
  }

  void _giveHint() {
    if (winner != null) return;
    int currentHints = isXturn ? player1Hints : player2Hints;
    if (currentHints == 0) return;

    setState(() {
      hintIndex = _getBestMove(isXturn ? 'X' : 'O');
      if (currentHints != -1) {
        if (isXturn) player1Hints--; else player2Hints--;
      }
    });
  }

  String? _checkWinner() {
    for (int r = 0; r < boardSize; r++) {
      String first = board[r * boardSize];
      if (first != "" && List.generate(boardSize, (c) => board[r * boardSize + c]).every((e) => e == first)) return first;
    }
    for (int c = 0; c < boardSize; c++) {
      String first = board[c];
      if (first != "" && List.generate(boardSize, (r) => board[r * boardSize + c]).every((e) => e == first)) return first;
    }
    String d1 = board[0];
    if (d1 != "" && List.generate(boardSize, (i) => board[i * boardSize + i]).every((e) => e == d1)) return d1;
    String d2 = board[boardSize - 1];
    if (d2 != "" && List.generate(boardSize, (i) => board[i * boardSize + (boardSize - 1 - i)]).every((e) => e == d2)) return d2;
    if (!board.contains("")) return "Draw";
    return null;
  }

  void _updateScore() {
    if (winner == "X") player1Score++; else if (winner == "O") player2Score++;
  }

  void _showResult() {
    if (_dialogShowing) return;
    _dialogShowing = true;
    
    String winName = winner == "X" ? widget.player1 : winner == "O" ? widget.player2 : "Nobody";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(ctx).cardColor,
        title: Column(
          children: [
            Icon(winner == "Draw" ? Icons.handshake : Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(winner == "Draw" ? "🤝 IT'S A DRAW" : "🏆 ${winName.toUpperCase()} WINS!", 
                 textAlign: TextAlign.center,
                 style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo)),
          ],
        ),
        content: const Text("The round has ended. Ready for another?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () { 
              Navigator.of(ctx, rootNavigator: true).pop(); 
              setState(() { _initGame(); }); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF302b63), foregroundColor: Colors.white),
            child: const Text("Next Round"),
          ),
          TextButton(onPressed: () { 
            Navigator.of(ctx, rootNavigator: true).pop(); 
            Navigator.pop(context);
          }, child: const Text("Main Menu")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: AnimatedShapesBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 1050;
              return isWide ? _buildWideLayout(isDark, constraints) : _buildNarrowLayout(isDark, constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(bool isDark, BoxConstraints constraints) {
    final panelColor = isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9);
    final availableCenterWidth = constraints.maxWidth - 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        // Left Panel (Player 1) - Fixed at top-left
        Container(
          width: 300,
          height: constraints.maxHeight,
          color: panelColor,
          padding: const EdgeInsets.all(24),
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _playerProfile(widget.player1, "X", player1Score, isXturn, player1Hints, true),
                  const Divider(height: 40),
                  const Text("MOVE HISTORY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _moveHistoryList(isDark),
                ],
              ),
            ),
          ),
        ),
        // Center
        Expanded(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _topStatusBar(isDark),
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'game_card_hero',
                      child: _gameBoard(isDark, availableCenterWidth),
                    ),
                    const SizedBox(height: 40),
                    _actionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right Panel (Player 2) - Fixed at top-right
        Container(
          width: 300,
          height: constraints.maxHeight,
          color: panelColor,
          padding: const EdgeInsets.all(24),
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _playerProfile(widget.player2, "O", player2Score, !isXturn, player2Hints, true),
                  const Divider(height: 40),
                  const Text("LAST MOVE PREVIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _lastMovePreview(isDark),
                  const SizedBox(height: 24),
                  _difficultyBadge(),
                  const SizedBox(height: 20),
                  _resetStatsButton(),
                  const SizedBox(height: 10),
                  _exitButton(),
                  const SizedBox(height: 10),
                  _themeToggle(isDark),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(bool isDark, BoxConstraints constraints) {
    return Column(
      children: [
        _topStatusBarCompact(isDark),
        Expanded(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _playerProfile(widget.player1, "X", player1Score, isXturn, player1Hints, false)),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: _VsDivider()),
                      Expanded(child: _playerProfile(widget.player2, "O", player2Score, !isXturn, player2Hints, false)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Hero(
                    tag: 'game_content',
                    child: _gameBoard(isDark, constraints.maxWidth),
                  ),
                  const SizedBox(height: 30),
                  _actionButtons(),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(16)),
                    child: ScrollConfiguration(
                      behavior: NoScrollbarBehavior(),
                      child: ListView(
                        children: [_moveHistoryList(isDark)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topStatusBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.indigo),
          const SizedBox(width: 12),
          Text(
            "TIME LEFT: ${secondsRemaining}s",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: secondsRemaining < 5 ? Colors.red : Colors.indigo),
          ),
        ],
      ),
    );
  }

  Widget _topStatusBarCompact(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.black.withOpacity(0.5) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          Text("TICTACTOE PRO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: isDark ? Colors.white : Colors.indigo.shade900)),
          Text("${secondsRemaining}s", style: TextStyle(fontWeight: FontWeight.bold, color: secondsRemaining < 5 ? Colors.red : Colors.indigo)),
        ],
      ),
    );
  }

  Widget _playerProfile(String name, String symbol, int score, bool isActive, int hints, bool full) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(full ? 16 : 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo.withOpacity(0.1) : (isDark ? Colors.grey.shade900 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: Colors.indigo, width: 2) : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: full ? 40 : 20,
            backgroundColor: symbol == "X" ? Colors.blue.shade100 : Colors.red.shade100,
            child: Text(symbol, style: TextStyle(fontSize: full ? 32 : 18, fontWeight: FontWeight.bold, color: symbol == "X" ? Colors.blue : Colors.red)),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
          Text("Score: $score", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
          if (isActive) ...[
            const SizedBox(height: 4),
            const Text("TURN", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 4),
          Text("Hints: ${hints == -1 ? '∞' : hints}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _gameBoard(bool isDark, double availableWidth) {
    double size = min(availableWidth * 0.8, 450);
    if (MediaQuery.of(context).size.height < 600) size = min(size, 250);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF302b63),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: board.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: boardSize,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (_, index) => _gridCell(index, isDark),
      ),
    );
  }

  Widget _gridCell(int index, bool isDark) {
    bool isHint = hintIndex == index;
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isHint ? Colors.amber.shade200 : (isDark ? Colors.grey.shade800 : Colors.white.withOpacity(0.95)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              child: Text(
                board[index],
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: board[index] == 'X' ? const Color(0xFF4e89ae) : const Color(0xFFe53935),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lastMovePreview(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: lastMoveIndex == null
          ? const Center(child: Text("No moves", style: TextStyle(fontSize: 10, color: Colors.grey)))
          : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: board.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: boardSize,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (_, index) => Container(
                decoration: BoxDecoration(
                  color: lastMoveIndex == index ? Colors.indigo.shade100 : (isDark ? Colors.grey.shade900 : Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      board[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: board[index] == 'X' ? Colors.blue : Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _giveHint,
          icon: const Icon(Icons.lightbulb),
          label: const Text("HINT"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => _initGame()),
          icon: const Icon(Icons.restart_alt),
          label: const Text("RESET"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _moveHistoryList(bool isDark) {
    return Column(
      children: moveHistory.map((move) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(12)
        ),
        child: Text(move, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  Widget _difficultyBadge() {
    String text = widget.mode == GameMode.bot ? widget.difficulty!.name.toUpperCase() : widget.boardLevel.name.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(20)),
      child: Text("LEVEL: $text", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _resetStatsButton() {
    return TextButton.icon(
      onPressed: () => setState(() { player1Score = 0; player2Score = 0; }),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text("RESET SCORES"),
      style: TextButton.styleFrom(foregroundColor: Colors.red),
    );
  }

  Widget _exitButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.exit_to_app),
      label: const Text("EXIT TO MENU"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _themeToggle(bool isDark) {
    return OutlinedButton.icon(
      onPressed: () {
        themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      label: Text(isDark ? "LIGHT MODE" : "DARK MODE"),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
    );
  }
}

class _VsDivider extends StatelessWidget {
  const _VsDivider();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text("VS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 18)),
      ],
    );
  }
}
