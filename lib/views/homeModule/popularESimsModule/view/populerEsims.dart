
import 'package:esimtel/core/bloc/api_state.dart';
import 'package:esimtel/utills/appColors.dart';
import 'package:esimtel/views/homeModule/getUsageModule/views/countryCard.dart';
import 'package:esimtel/views/navbarModule/bloc/navbar_bloc.dart';
import 'package:esimtel/views/packageModule/regionsList/model/regionsModel.dart';
import 'package:esimtel/views/packageModule/regionsList/regionList_bloc/region_bloc.dart';
import 'package:esimtel/views/packageModule/regionsList/view/regionListScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class PopularESims extends StatelessWidget {
  PopularESims({super.key});
  final navController = Get.find<BottomNavController>();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegionsListBloc, ApiState<RegionsModel>>(
      builder: (context, state) {
        if (state is ApiLoading) {
          return SizedBox();
        } else if (state is ApiFailure) {
          return SizedBox();
        } else if (state is ApiSuccess<RegionsModel>) {
          final regionList = state.data.data ?? [];
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular Regional Plans",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ).tr(),
                    InkWell(
                      onTap: () {
                        navController.jumpToTab(1);
                        debugPrint("Popular degignation click");
                      },
                      child: Text(
                        "See All",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: 15.sp,
                          color: AppColors.primaryColor,
                        ),
                      ).tr(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: regionList.length < 5 ? regionList.length : 5,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Get.to(
                          () => RegionListScreen(
                            regionId: regionList[index].id.toString(),
                          ),
                        );
                      },
                      child: CountryCard(
                        countryName: "${regionList[index].name}",
                        imagePath: "${regionList[index].image}",
                      ),
                    );
                  },
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
