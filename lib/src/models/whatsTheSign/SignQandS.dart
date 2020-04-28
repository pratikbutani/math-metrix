class SignQandS {
  int id;
  String firstDigit;
  String sign;
  String secondDigit;
  String answer;

  SignQandS(this.id, this.firstDigit, this.sign, this.secondDigit, this.answer);

  @override
  String toString() {
    return 'SignQandS{id: $id, firstDigit: $firstDigit, sign: $sign, secondDigit: $secondDigit, answer: $answer}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SignQandS &&
              runtimeType == other.runtimeType &&
              firstDigit == other.firstDigit &&
              sign == other.sign &&
              secondDigit == other.secondDigit;

  @override
  int get hashCode =>
      firstDigit.hashCode ^
      sign.hashCode ^
      secondDigit.hashCode;



}
