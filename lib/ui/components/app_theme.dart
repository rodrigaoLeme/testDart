import 'package:flutter/material.dart';

ThemeData makeAppTheme() {
  const primaryColor = Color(0xFF0052A3);
  const primaryColorDark = Color(0xFF003366);
  const primaryColorLight = Color(0xFFD1E8FF);
  const secondaryColor = Color(0xFFff5512);
  const secondaryColorDark = Color(0xffF7F7F7);
  const disabledColor = Color(0xffEBEBEB);
  const dividerColor = Color(0xff9e9e9e);
  const hintColor = Color(0xffF2F3F8);
  const indicatorColor = Color(0xffB30000);
  const focusColor = Color(0xFFABD4FC);
  const splashColor = Color(0xFFF5F5F5);
  const cardColor = Color(0xff6B6B6B);
  const cardTheme = Color(0xff520000);
  const canvasColor = Color(0xffCCCCCC);
  const textTheme = TextTheme(
      displayLarge: TextStyle(
          fontSize: 30, fontWeight: FontWeight.bold, color: primaryColorDark));
  const inputDecorationTheme = InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColorLight)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
      alignLabelWithHint: true);
  final buttonTheme = ButtonThemeData(
      colorScheme: const ColorScheme.light(primary: primaryColor),
      buttonColor: primaryColor,
      splashColor: primaryColorLight,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));

  return ThemeData(
    primaryColor: primaryColor,
    primaryColorDark: primaryColorDark,
    primaryColorLight: primaryColorLight,
    highlightColor: secondaryColor,
    secondaryHeaderColor: secondaryColorDark,
    disabledColor: disabledColor,
    dividerColor: dividerColor,
    colorScheme: const ColorScheme.light(primary: primaryColor),
    fontFamily: 'IBMPlexMono',
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme,
    buttonTheme: buttonTheme,
    hintColor: hintColor,
    indicatorColor: indicatorColor,
    focusColor: focusColor,
    splashColor: splashColor,
    hoverColor: cardTheme,
    cardColor: cardColor,
    canvasColor: canvasColor,
  );
}
