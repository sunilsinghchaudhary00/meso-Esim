
import 'package:esimtel/core/bloc/api_state.dart';
import 'package:esimtel/utills/appColors.dart';
import 'package:esimtel/views/homeModule/getUsageModule/views/countryCard.dart';
import 'package:esimtel/views/navbarModule/bloc/navbar_bloc.dart';
import 'package:esimtel/views/packageModule/packagesList/controller/packagelistcontorller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../../../packageModule/packagesList/bloc/country_bloc/countriesListbloc.dart';
import '../../../packageModule/packagesList/model/countryListModel.dart';
import '../../../packageModule/packagesList/view/packageListScreen.dart';

class PopularDistinctios extends StatelessWidget {
  PopularDistinctios({super.key});
  final navController = Get.find<BottomNavController>();
  final packageListController = Get.find<PackageListController>();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountryBloc, ApiState<CountryListModel>>(
      builder: (context, state) {
        if (state is ApiLoading) {
          return SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return CountryCard(countryName: "India", imagePath: " ");
              },
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
        } else if (state is ApiFailure) {
          return SizedBox();
        } else if (state is ApiSuccess<CountryListModel>) {
          final countries = state.data.data ?? [];
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular destinations",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ).tr(),
                    InkWell(
                      onTap: () {
                        debugPrint("Popular degignation click");
                        navController.jumpToTab(1);
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
                  itemCount: countries.length < 5 ? countries.length : 5,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Get.to(
                          () => PackageListScreen(
                            id: countries[index].id.toString(),
                          ),
                        );
                      },
                      child: CountryCard(
                        countryName: "${countries[index].name}",
                        imagePath: "${countries[index].image}",
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
