import 'package:cached_network_image/cached_network_image.dart';
import 'package:esimtel/utills/appColors.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PopularESIMsCard extends StatelessWidget {
  final String imagePath;
  final String countryName;
  final Color colorcode;
  final String planName;
  final bool isUnlimited;

  const PopularESIMsCard({
    Key? key,
    required this.imagePath,
    required this.countryName,
    required this.colorcode,
    required this.planName,
    required this.isUnlimited,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the decoration based on isUnlimited
    final BoxDecoration cardDecoration = BoxDecoration(
      color: colorcode,
      borderRadius: BorderRadius.circular(2.w),
    );

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: 40.w,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          decoration: cardDecoration, // Use the conditional decoration
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                countryName,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                planName,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w300,
                  color: AppColors.whiteColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 15),
              Flexible(
                child: FlagContainer(
                  imagePath: imagePath,
                  borderColor: AppColors.whiteColor,
                ),
              ),
            ],
          ),
        ),
        isUnlimited
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2),
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  border: Border.all(color: colorcode),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(2.w),
                    topRight: Radius.circular(2.w),
                  ),
                ),
                child: Text(
                  "🔥Unlimited",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor,
                  ),
                ),
              )
            : SizedBox(),
      ],
    );
  }
}

class FlagContainer extends StatelessWidget {
  final String imagePath;
  final double radius;
  final double cutSize;
  final double borderWidth;
  final Color borderColor;

  const FlagContainer({
    super.key,
    required this.imagePath,
    this.radius = 8,
    this.cutSize = 12,
    this.borderWidth = 2,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BorderPainter(
        radius: radius,
        cutSize: cutSize,
        borderWidth: borderWidth,
        borderColor: borderColor,
      ),
      child: ClipPath(
        clipper: CustomClipperContainer(cutSize: cutSize, radius: radius),
        child: CachedNetworkImage(
          imageUrl: imagePath,
          placeholder: (context, url) => Skeletonizer(
            child: Container(
              width: 15.w,
              height: 12.w,
              color: AppColors.greyColor,
            ),
          ),
          errorWidget: (context, url, error) =>
              Image.asset("assets/images/earth.png", width: 15.w, height: 10.w),
          imageBuilder: (context, imageProvider) => Container(
            width: 12.w,
            height: 8.w,
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomClipperContainer extends CustomClipper<Path> {
  final double radius;
  final double cutSize;

  CustomClipperContainer({required this.radius, required this.cutSize});

  @override
  Path getClip(Size size) {
    Path path = Path();

    // Top-left rounded
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Top-right rounded
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Right edge → down to near bottom
    path.lineTo(size.width, size.height - cutSize);

    // SMALL diagonal cut (SIM-like)
    path.lineTo(size.width - cutSize, size.height);

    // Bottom edge → bottom-left rounded
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BorderPainter extends CustomPainter {
  final double radius;
  final double cutSize;
  final double borderWidth;
  final Color borderColor;

  BorderPainter({
    required this.radius,
    required this.cutSize,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    Path path = CustomClipperContainer(
      radius: radius,
      cutSize: cutSize,
    ).getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
