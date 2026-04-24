import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    final adsService = context.read<AdsService>();
    adsService.loadBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    final adsService = context.watch<AdsService>();
    final bannerAd = adsService.bannerAd;

    if (bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }

  @override
  void dispose() {
    final adsService = context.read<AdsService>();
    adsService.disposeBannerAd();
    super.dispose();
  }
}
