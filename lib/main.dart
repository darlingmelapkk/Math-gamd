import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MathGameApp());

class MathGameApp extends StatelessWidget {
  const MathGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9D4EDD),
          brightness: Brightness.dark,
        ),
      ),
      home: const MathGameScreen(),
    );
  }
}

class MathGameScreen extends StatefulWidget {
  const MathGameScreen({super.key});

  @override
  State<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen>
    with TickerProviderStateMixin {
  static const double tempoInicial = 20.0;

  final Random _random = Random();
  final FocusNode _keyboardFocusNode = FocusNode();

  int pontos = 0;
  int rodada = 1;
  int streak = 0;
  int maiorStreak = 0;
  int respostaCorreta = 0;
  int recordePontos = 0;

  String respostaUsuario = '';
  String textoPergunta = '';
  double tempoRestante = tempoInicial;

  bool respondendo = false;
  bool isGameOver = false;

  Timer? timer;

  late final AnimationController _correctAnimController;
  late final AnimationController _wrongAnimController;
  late final AnimationController _btnCorrectController;
  late final AnimationController _btnWrongController;
  late final AnimationController _streakAnimController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shakeAnimation;
  late final Animation<double> _btnScaleAnimation;
  late final Animation<double> _btnShakeAnimation;
  late final Animation<double> _streakScaleAnimation;

  @override
  void initState() {
    super.initState();

    _correctAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _wrongAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _btnCorrectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _btnWrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _streakAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.07),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.07, end: .96),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: .96, end: 1.035),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.035, end: 1.0),
        weight: 35,
      ),
    ]).animate(_correctAnimController);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -12.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -12.0, end: 12.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 12.0, end: -10.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -10.0, end: 10.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 10.0, end: -7.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -7.0, end: 7.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 7.0, end: -3.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -3.0, end: 0.0),
        weight: 16,
      ),
    ]).animate(_wrongAnimController);

    _btnScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: .96),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: .96, end: 1.0),
        weight: 40,
      ),
    ]).animate(_btnCorrectController);

    _btnShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 8.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 8.0, end: -6.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -6.0, end: 6.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 6.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_btnWrongController);

    _streakScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0),
        weight: 50,
      ),
    ]).animate(_streakAnimController);

    _carregarRecorde();
    _novaPergunta();
  }

  @override
  void dispose() {
    timer?.cancel();
    _keyboardFocusNode.dispose();
    _correctAnimController.dispose();
    _wrongAnimController.dispose();
    _btnCorrectController.dispose();
    _btnWrongController.dispose();
    _streakAnimController.dispose();
    super.dispose();
  }

  Future<void> _carregarRecorde() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        recordePontos = prefs.getInt('mathRecorde') ?? 0;
      });
    }
  }

  Future<void> _salvarRecorde(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mathRecorde', value);
  }

  int _aleatorio(int min, int max) {
    return _random.nextInt(max - min + 1) + min;
  }

  String _gerarPergunta() {
    if (rodada <= 5) return _multiplicacaoInicial();
    if (rodada <= 10) return _multiplicacaoMedia();
    if (rodada <= 15) return _multiplicacaoDificil();
    if (rodada <= 20) return _divisao();
    if (rodada <= 25) return _somaSubtracao();
    if (rodada <= 30) return _contaTripla();
    if (rodada <= 35) return _mista();
    if (rodada <= 40) return _mistaSubtracao();
    if (rodada <= 45) return _duasMultiplicacoes();
    if (rodada <= 50) return _parenteses();
    if (rodada <= 55) return _parentesesSubtracao();
    if (rodada <= 60) return _potencia();
    if (rodada <= 65) return _porcentagem();
    if (rodada <= 70) return _raiz();
    if (rodada <= 80) return _equacao();
    if (rodada <= 85) return _equacaoMultiplicacao();
    if (rodada <= 90) return _equacaoComplexa();
    if (rodada <= 100) return _expressaoComplexa();

    return _expressaoMuitoDificil();
  }

  String _multiplicacaoInicial() {
    final a = _aleatorio(6, 12);
    final b = _aleatorio(6, 12);
    respostaCorreta = a * b;
    return '\(a × \)b';
  }

  String _multiplicacaoMedia() {
    final a = _aleatorio(8, 18);
    final b = _aleatorio(6, 15);
    respostaCorreta = a * b;
    return '\(a × \)b';
  }

  String _multiplicacaoDificil() {
    final a = _aleatorio(12, 30);
    final b = _aleatorio(8, 20);
    respostaCorreta = a * b;
    return '\(a × \)b';
  }

  String _divisao() {
    final resultado = _aleatorio(5, min(30 + rodada, 80));
    final divisor = _aleatorio(3, 15);

    respostaCorreta = resultado;
    return '\({resultado * divisor} ÷ \)divisor';
  }

  String _somaSubtracao() {
    final a = _aleatorio(20, 100);
    final b = _aleatorio(10, 80);
    final c = _aleatorio(5, 50);

    respostaCorreta = a + b - c;
    return '\(a + \)b − $c';
  }

  String _contaTripla() {
    final a = _aleatorio(5, 30);
    final b = _aleatorio(5, 30);
    final c = _aleatorio(5, 30);

    respostaCorreta = a + b + c;
    return '\(a + \)b + $c';
  }

  String _mista() {
    final a = _aleatorio(5, 20);
    final b = _aleatorio(4, 15);
    final c = _aleatorio(10, 50);

    respostaCorreta = a * b + c;
    return '\(a × \)b + $c';
  }

  String _mistaSubtracao() {
    final a = _aleatorio(8, 25);
    final b = _aleatorio(5, 15);
    final produto = a * b;
    final c = _aleatorio(5, produto - 1);

    respostaCorreta = produto - c;
    return '\(a × \)b − $c';
  }

  String _duasMultiplicacoes() {
    final a = _aleatorio(5, 20);
    final b = _aleatorio(3, 12);
    final c = _aleatorio(5, 20);
    final d = _aleatorio(3, 12);

    respostaCorreta = a * b + c * d;
    return '\(a × \)b + \(c × \)d';
  }

  String _parenteses() {
    final a = _aleatorio(5, 20);
    final b = _aleatorio(3, 15);
    final c = _aleatorio(3, 12);

    respostaCorreta = (a + b) * c;
    return '(\(a + \)b) × $c';
  }

  String _parentesesSubtracao() {
    final a = _aleatorio(15, 40);
    final b = _aleatorio(3, a - 2);
    final c = _aleatorio(3, 12);

    respostaCorreta = (a - b) * c;
    return '(\(a − \)b) × $c';
  }

  String _potencia() {
    final base = _aleatorio(2, 8);
    final expoente = rodada >= 70 ? _aleatorio(2, 3) : 2;

    respostaCorreta = pow(base, expoente).toInt();

    return expoente == 2 ? '\(base²' : '\)base³';
  }

  String _porcentagem() {
    const valores = [10, 20, 25, 50, 75];

    final porcentagem =
        valores[_aleatorio(0, valores.length - 1)];

    final base = _aleatorio(2, 20) * 10;

    respostaCorreta =
        (base * porcentagem / 100).round();

    return '\(porcentagem% de \)base';
  }

  String _raiz() {
    final numero = _aleatorio(2, 20);

    respostaCorreta = numero;
    return '√${numero * numero}';
  }

  String _equacao() {
    final x = _aleatorio(2, 30);
    final numero = _aleatorio(2, 20);

    respostaCorreta = x;
    return 'x + \(numero = \){x + numero}';
  }

  String _equacaoMultiplicacao() {
    final x = _aleatorio(2, 30);
    final numero = _aleatorio(2, 12);

    respostaCorreta = x;
    return '\({numero}x = \){numero * x}';
  }

  String _equacaoComplexa() {
    final x = _aleatorio(2, 30);
    final a = _aleatorio(2, 12);
    final b = _aleatorio(1, 30);

    respostaCorreta = x;
    return '\({a}x + \)b = ${a * x + b}';
  }

  String _expressaoComplexa() {
    final a = _aleatorio(5, 20);
    final b = _aleatorio(3, 15);
    final c = _aleatorio(3, 12);
    final d = _aleatorio(5, 40);

    respostaCorreta = (a + b) * c - d;
    return '(\(a + \)b) × \(c − \)d';
  }

  String _expressaoMuitoDificil() {
    final a = _aleatorio(5, 20);
    final b = _aleatorio(3, 12);
    final c = _aleatorio(5, 20);
    final d = _aleatorio(3, 12);
    final e = _aleatorio(5, 30);

    respostaCorreta = a * b + c * d - e;
    return '\(a × \)b + \(c × \)d − $e';
  }

  int get calcularNivel => ((rodada - 1) ~/ 10) + 1;

  double get obterTempoMaximo =>
      max(7.0, tempoInicial - (rodada ~/ 15));

  void _novaPergunta() {
    timer?.cancel();

    if (!mounted) return;

    setState(() {
      respondendo = false;
      respostaUsuario = '';
      textoPergunta = _gerarPergunta();
      tempoRestante = obterTempoMaximo;
    });

    _correctAnimController.reset();
    _wrongAnimController.reset();
    _btnCorrectController.reset();
    _btnWrongController.reset();

    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timerAtual) {
        if (!mounted || respondendo || isGameOver) {
          timerAtual.cancel();
          return;
        }

        setState(() {
          tempoRestante = max(0, tempoRestante - .1);

          if (tempoRestante <= 0) {
            timerAtual.cancel();
            _tempoEsgotado();
          }
        });
      },
    );
  }

  void _adicionarNumero(String numero) {
    if (respondendo ||
        isGameOver ||
        respostaUsuario.length >= 7) {
      return;
    }

    setState(() {
      respostaUsuario += numero;
    });
  }

  void _limparResposta() {
    if (respondendo) return;

    setState(() {
      respostaUsuario = '';
    });
  }

  void _apagarNumero() {
    if (respondendo || respostaUsuario.isEmpty) return;

    setState(() {
      respostaUsuario = respostaUsuario.substring(
        0,
        respostaUsuario.length - 1,
      );
    });
  }

  void _verificarResposta() {
    if (respondendo ||
        isGameOver ||
        respostaUsuario.isEmpty) {
      return;
    }

    respondendo = true;
    timer?.cancel();

    final valor =
        int.tryParse(respostaUsuario) ?? -999999;

    if (valor == respostaCorreta) {
      final ganhos =
          100 + ((calcularNivel - 1) * 25) + (streak * 10);

      setState(() {
        pontos += ganhos;
        streak++;
        maiorStreak = max(maiorStreak, streak);
      });

      _correctAnimController.forward();
      _btnCorrectController.forward();
      _streakAnimController.forward(from: 0);

      Future.delayed(
        const Duration(milliseconds: 650),
        () {
          if (!mounted) return;

          setState(() {
            rodada++;
          });

          _novaPergunta();
        },
      );
    } else {
      setState(() {
        respostaUsuario = respostaCorreta.toString();
        streak = 0;
      });

      _wrongAnimController.forward();
      _btnWrongController.forward();

      Future.delayed(
        const Duration(milliseconds: 1000),
        () {
          if (mounted) {
            _finalizarJogo();
          }
        },
      );
    }
  }

  void _tempoEsgotado() {
    if (respondendo || isGameOver) return;

    respondendo = true;
    timer?.cancel();

    setState(() {
      respostaUsuario = respostaCorreta.toString();
      streak = 0;
    });

    _wrongAnimController.forward();
    _btnWrongController.forward();

    Future.delayed(
      const Duration(milliseconds: 1000),
      () {
        if (mounted) {
          _finalizarJogo();
        }
      },
    );
  }

  Future<void> _finalizarJogo() async {
    timer?.cancel();

    if (pontos > recordePontos) {
      recordePontos = pontos;
      await _salvarRecorde(recordePontos);
    }

    if (mounted) {
      setState(() {
        isGameOver = true;
      });
    }
  }

  void _reiniciar() {
    timer?.cancel();

    setState(() {
      pontos = 0;
      rodada = 1;
      streak = 0;
      maiorStreak = 0;
      respostaCorreta = 0;
      respostaUsuario = '';
      respondendo = false;
      isGameOver = false;
    });

    _novaPergunta();
    _keyboardFocusNode.requestFocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        respondendo ||
        isGameOver) {
      return;
    }

    final key = event.logicalKey;
    final label = key.keyLabel;

    if (RegExp(r'^[0-9]$').hasMatch(label)) {
      _adicionarNumero(label);
    } else if (key == LogicalKeyboardKey.backspace) {
      _apagarNumero();
    } else if (key == LogicalKeyboardKey.escape) {
      _limparResposta();
    } else if (key == LogicalKeyboardKey.enter) {
      _verificarResposta();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [
                Color(0xFF42145F),
                Color(0xFF180B29),
                Color(0xFF0C0615),
              ],
              stops: [0, .65, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F0D30)
                        .withOpacity(.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(.08),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 60,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: isGameOver
                      ? _buildGameOver()
                      : _buildGameContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    final porcentagemTempo =
        (tempoRestante / obterTempoMaximo)
            .clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            _stat('PONTOS', '$pontos'),
            ScaleTransition(
              scale: _streakScaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F43)
                      .withOpacity(.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9F43)
                        .withOpacity(.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFFF9F43),
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFC56E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _stat('RODADA', '$rodada'),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: porcentagemTempo,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              _barColor,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${tempoRestante.toStringAsFixed(1)}s',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: _barColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'RESOLVA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFA99BB5),
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: Listenable.merge([
            _correctAnimController,
            _wrongAnimController,
          ]),
          builder: (_, child) {
            final shake = _shakeAnimation.value;
            final scale = _scaleAnimation.value;

            return Transform.translate(
              offset: Offset(shake, 0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: Text(
            textoPergunta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 17),
        Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.22),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(.1),
            ),
          ),
          child: Text(
            respostaUsuario.isEmpty
                ? '?'
                : respostaUsuario,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: respostaUsuario.isEmpty
                  ? Colors.white38
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildKeypad(),
        const SizedBox(height: 14),
        ScaleTransition(
          scale: _btnScaleAnimation,
          child: AnimatedBuilder(
            animation: _btnWrongController,
            builder: (_, child) {
              return Transform.translate(
                offset: Offset(
                  _btnShakeAnimation.value,
                  0,
                ),
                child: child,
              );
            },
            child: SizedBox(
              height: 53,
              child: ElevatedButton(
                onPressed: _verificarResposta,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF9D4EDD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'CONFIRMAR  →',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'Nível \(calcularNivel  •  Recorde: \)recordePontos',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color get _barColor {
    final porcentagem =
        tempoRestante / obterTempoMaximo;

    if (porcentagem <= .25) {
      return const Color(0xFFFF3F61);
    }

    if (porcentagem <= .5) {
      return const Color(0xFFFF9F43);
    }

    return const Color(0xFF9D4EDD);
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA99BB5),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'C',
      '0',
      '⌫',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (_, index) {
        final key = keys[index];
        final special = key == 'C' || key == '⌫';

        return OutlinedButton(
          onPressed: () {
            if (key == 'C') {
              _limparResposta();
            } else if (key == '⌫') {
              _apagarNumero();
            } else {
              _adicionarNumero(key);
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: special
                ? Colors.white.withOpacity(.04)
                : Colors.white.withOpacity(.08),
            foregroundColor: special
                ? const Color(0xFFFF9F43)
                : Colors.white,
            side: BorderSide(
              color: Colors.white.withOpacity(.08),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: special ? 20 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOver() {
    return Column(
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFFFC857),
          size: 70,
        ),
        const SizedBox(height: 10),
        const Text(
          'FIM DE JOGO',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text(
                'SUA PONTUAÇÃO',
                style: TextStyle(
                  color: Color(0xFFA99BB5),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pontos',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  _result('RODADA', '$rodada'),
                  _result(
                    'MELHOR STREAK',
                    '$maiorStreak',
                  ),
                  _result(
                    'RECORDE',
                    '$recordePontos',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _reiniciar,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF9D4EDD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'JOGAR NOVAMENTE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _result(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
