import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:mathgame/src/models/correctAnswer/correctAnswerQandS.dart';
import 'package:mathgame/src/resources/correctAnswer/correctAnswerQandSDataProvider.dart';
import 'package:mathgame/src/resources/dialog_service.dart';
import 'package:mathgame/src/resources/gameCategoryDataProvider.dart';
import 'package:mathgame/src/resources/navigation_service.dart';
import 'package:mathgame/src/utility/coinUtil.dart';
import 'package:mathgame/src/provider/dashboardViewModel.dart';
import 'package:mathgame/src/utility/keyUtil.dart';
import 'package:mathgame/src/utility/scoreUtil.dart';
import 'package:mathgame/src/utility/timeUtil.dart';

class CorrectAnswerProvider with ChangeNotifier {
  var homeViewModel = GetIt.I<DashboardViewModel>();
  final DialogService _dialogService = GetIt.I<DialogService>();

  List<CorrectAnswerQandS> _list;
  CorrectAnswerQandS _currentState;
  String _result;
  int _index = 0;
  double currentScore = 0;

  bool _timeOut;
  int _time;
  bool _pause = false;

  bool get timeOut => _timeOut;

  String get result => _result;

  int get time => _time;

  bool get pause => _pause;

  StreamSubscription timerSubscription;

  CorrectAnswerQandS get currentState => _currentState;

  CorrectAnswerProvider() {
    startGame();
  }

  void startGame() {
    _list = CorrectAnswerQandSDataProvider.getCorrectAnswerDataList(1);
    _currentState = _list[_index];
    _time = TimeUtil.correctAnswerTimeOut;
    _timeOut = false;
    _result = "";
    currentScore = 0;
    startTimer();

    if (homeViewModel.isFirstTime(GameCategoryType.CORRECT_ANSWER)) {
      showInfoDialogWithDelay();
    }
  }

  Future<void> checkResult(String answer) async {
    if (!timeOut) {
      _result = answer;
      notifyListeners();
      if (int.parse(_result) == _currentState.answer) {
        await Future.delayed(Duration(milliseconds: 300));
        if (_list.length - 1 == _index) {
          _list.addAll(CorrectAnswerQandSDataProvider.getCorrectAnswerDataList(
              _index ~/ 5 + 1));
        }
        _index = _index + 1;
        currentScore = currentScore + ScoreUtil.correctAnswerScore;
        _currentState = _list[_index];
        _result = "";
        if (!timeOut) {
          restartTimer();
          notifyListeners();
        }
      } else {
        if (currentScore > 0) {
          currentScore =
              currentScore + ScoreUtil.correctAnswerScoreMinus;
        }
      }
    }
  }

  clear() {
    _result = "";
    notifyListeners();
  }

  void startTimer() {
    timerSubscription = Stream.periodic(
            Duration(seconds: 1), (x) => TimeUtil.correctAnswerTimeOut - x - 1)
        .take(TimeUtil.correctAnswerTimeOut)
        .listen((time) {
      _time = time;
      notifyListeners();
    }, onDone: () {
      showDialog();
      this._timeOut = true;
      notifyListeners();
    });
  }

  void restartTimer() {
    timerSubscription.cancel();
    startTimer();
  }

  void pauseTimer() {
    _pause = true;
    timerSubscription.pause();
    notifyListeners();
    showDialog();
  }

  Future showDialog() async {
    notifyListeners();
    var dialogResult = await _dialogService.showDialog(
        type: KeyUtil.GameOverDialog,
        gameCategoryType: GameCategoryType.CORRECT_ANSWER,
        score: currentScore,
        coin: _index * CoinUtil.correctAnswerCoin,
        isPause: _pause);

    if (dialogResult.exit) {
      homeViewModel.updateScoreboard(GameCategoryType.CORRECT_ANSWER,
          currentScore, _index * CoinUtil.correctAnswerCoin);
      GetIt.I<NavigationService>().goBack();
    } else if (dialogResult.restart) {
      homeViewModel.updateScoreboard(GameCategoryType.CORRECT_ANSWER,
          currentScore, _index * CoinUtil.correctAnswerCoin);
      timerSubscription.cancel();
      _index = 0;
      startGame();
    } else if (dialogResult.play) {
      timerSubscription.resume();
      _pause = false;
      notifyListeners();
    }
    notifyListeners();
  }

  Future showInfoDialogWithDelay() async {
    await Future.delayed(Duration(milliseconds: 500));
    showInfoDialog();
  }

  Future showInfoDialog() async {
    await Future.delayed(Duration(milliseconds: 500));
    _pause = true;
    timerSubscription.pause();
    notifyListeners();
    var dialogResult = await _dialogService.showDialog(
        type: KeyUtil.InfoDialog,
        gameCategoryType: GameCategoryType.CORRECT_ANSWER,
        score: 0,
        coin: 0,
        isPause: false);

    if (dialogResult.exit) {
      homeViewModel.setFirstTime(GameCategoryType.CORRECT_ANSWER);
      timerSubscription.resume();
      _pause = false;
      notifyListeners();
    }
  }

  void dispose() {
    super.dispose();
    this.timerSubscription.cancel();
  }
}
