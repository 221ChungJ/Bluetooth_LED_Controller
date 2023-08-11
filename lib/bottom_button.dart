import 'package:flutter/material.dart';
import 'package:led_controller_ble_2/constants.dart';

class BottomButton extends StatelessWidget {
  BottomButton({required this.onTap, required this.buttonTitle});

  final VoidCallback onTap;
  final String buttonTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Center(
          child: Text(
            buttonTitle,
            style: kLargeButtonTextStyle,
          ),
        ),
        width: MediaQuery. of(context). size. width-50,
        height: kBottomContainerHeight,
        decoration: BoxDecoration(
            color: kBottomContainerColour,
            border: Border.all(
              color: kBottomContainerBorderColour,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20))
        ),
      ),
    );
  }
}
