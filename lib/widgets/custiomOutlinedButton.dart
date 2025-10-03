import 'package:flutter/material.dart';

class CustomOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final MaterialStateProperty<Color?>? overlayColor;
  final MaterialStateProperty<Color?>? backgroundColor;
  final double? width;  
  final double? height; 

  const CustomOutlinedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.textColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 10,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.overlayColor,
    this.backgroundColor,
    this.width, 
    this.height = 40, 
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = Theme.of(context).primaryColor;
    final defaultBorderColor = Theme.of(context).primaryColor;

    final defaultOverlayColor = MaterialStateProperty.resolveWith<Color?>((
      Set<MaterialState> states,
    ) {
      if (states.contains(MaterialState.hovered)) {
        return (textColor ?? defaultTextColor).withOpacity(0.1);
      }
      if (states.contains(MaterialState.pressed)) {
        return (textColor ?? defaultTextColor).withOpacity(0.2);
      }
      return null;
    });

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey;
            }
            return textColor ?? defaultTextColor;
          }),
          side: MaterialStateProperty.resolveWith<BorderSide?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(
                color: Colors.grey.shade400,
                width: borderWidth,
              );
            }
            return BorderSide(
              color: borderColor ?? defaultBorderColor,
              width: borderWidth,
            );
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            padding ??
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          ),
          overlayColor: overlayColor ?? defaultOverlayColor,
          backgroundColor: backgroundColor,
        ),
        child: text == ""
            ? const SizedBox(
                height: 24.0,
                width: 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              )
            : Text(
                text,
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
              ),
      ),
    );
  }
}
