import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tic Tac Toe Pro',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: TicTacToeGame(),
    );
  }
}

class TicTacToeGame extends StatefulWidget {
  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame>
    with SingleTickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  String player1 = 'X';
  String player2 = 'O';
  bool gameOver = false;
  String winner = '';
  int scoreX = 0;
  int scoreO = 0;
  int draws = 0;
  bool vsAI = false;
  bool isDarkMode = false;

  late AnimationController _controller;
  int? winStart;
  int? winEnd;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = player1;
      gameOver = false;
      winner = '';
      winStart = null;
      winEnd = null;
      _controller.reset();
    });
  }

  void _makeMove(int index) {
    if (board[index] == '' && !gameOver) {
      setState(() {
        board[index] = currentPlayer;
        if (_checkWinner(currentPlayer)) {
          gameOver = true;
          winner = currentPlayer;
          if (winner == 'X') scoreX++; else scoreO++;
          _controller.forward();
        } else if (!board.contains('')) {
          gameOver = true;
          draws++;
        } else {
          currentPlayer = currentPlayer == player1 ? player2 : player1;
          if (vsAI && currentPlayer == player2) {
            _aiMove();
          }
        }
      });
    }
  }

  void _aiMove() {
    int? move = _findBestMove();
    if (move != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        _makeMove(move!);
      });
    }
  }

  int? _findBestMove() {
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') {
        board[i] = currentPlayer;
        if (_checkWinner(currentPlayer)) {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }
    String opponent = currentPlayer == player1 ? player2 : player1;
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') {
        board[i] = opponent;
        if (_checkWinner(opponent)) {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }
    if (board[4] == '') return 4;
    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int c in corners) {
      if (board[c] == '') return c;
    }
    List<int> moves = [];
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') moves.add(i);
    }
    if (moves.isNotEmpty) return moves[Random().nextInt(moves.length)];
    return null;
  }

  bool _checkWinner(String player) {
    List<List<int>> winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];
    for (var pattern in winPatterns) {
      if (board[pattern[0]] == player &&
          board[pattern[1]] == player &&
          board[pattern[2]] == player) {
        winStart = pattern[0];
        winEnd = pattern[2];
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic Tac Toe Pro'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Player $player1 vs ${vsAI ? 'AI' : player2}',
              style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _makeMove(index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: AnimatedScale(
                            scale: board[index] == '' ? 0 : 1,
                            duration: Duration(milliseconds: 300),
                            child: Text(board[index],
                                style: TextStyle(
                                    fontSize: 40, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (winStart != null && winEnd != null)
                  CustomPaint(
                    painter: WinLinePainter(winStart!, winEnd!, _controller),
                    child: Container(),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          if (gameOver)
            Text(
              winner.isNotEmpty ? 'Winner: $winner' : 'It's a Draw!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('X: $scoreX'),
              Text('O: $scoreO'),
              Text('Draws: $draws'),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  vsAI = !vsAI;
                  _resetGame();
                });
              },
              child: Text(vsAI ? 'Switch to 2 Players' : 'Switch to vs AI'))
        ],
      ),
    );
  }
}

class WinLinePainter extends CustomPainter {
  final int start;
  final int end;
  final Animation<double> animation;

  WinLinePainter(this.start, this.end, this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    List<Offset> centers = List.generate(9, (i) {
      int row = i ~/ 3;
      int col = i % 3;
      return Offset(
          col * size.width / 3 + size.width / 6,
          row * size.height / 3 + size.height / 6);
    });

    Offset p1 = centers[start];
    Offset p2 = centers[end];

    final animatedP2 = Offset.lerp(p1, p2, animation.value)!;
    canvas.drawLine(p1, animatedP2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
