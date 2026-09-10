import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wps_mobile/features/bongkar_kd/view/kd_bongkar_in_screen.dart';
import 'package:wps_mobile/features/bongkar_kd/view/kd_bongkar_selected_screen.dart';
import 'package:wps_mobile/features/bongkar_kd/view_model/kd_bongkar_detail_view_model.dart';
import 'package:wps_mobile/features/jenis_kayu/repository/jenis_kayu_repository.dart';
import 'package:wps_mobile/features/jenis_kayu/view_model/jenis_kayu_view_model.dart';
import 'package:wps_mobile/features/kayu_bulat/view/kayu_bulat_screen.dart';
import 'package:wps_mobile/features/kayu_bulat/view_model/kayu_bulat_attachment_view_model.dart';
import 'package:wps_mobile/features/kayu_bulat/view_model/kayu_bulat_view_model.dart';
import 'package:wps_mobile/features/qc_sawmill/view/qc_sawmill_header_screen.dart';
import 'package:wps_mobile/features/qc_sawmill/view_model/qc_sawmill_header_view_model.dart';
import 'core/auth/token_provider.dart';
import 'core/network/api_client.dart';
import 'features/login/view/login_screen.dart';
import 'features/mesin_sawmill/repository/mesin_sawmill_repository.dart';
import 'features/mesin_sawmill/view_model/mesin_sawmill_view_model.dart';
import 'features/stock_opname/view/stock_opname_list_screen.dart';
import 'features/mapping/view/mapping_lokasi_screen.dart';
import 'features/qc_spk_bj/view/qc_spk_header_screen.dart';
import 'features/qc_spk_bj/view_model/qc_spk_header_view_model.dart';
import 'features/nyangkut/view/nyangkut_menu_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/stock_opname/view_model/stock_opname_list_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_detail_view_model.dart';
import 'core/view_models/preview_label_view_model.dart';
import 'core/view_models/pdf_view_model.dart';
import 'core/view_models/pdf_view_model_st.dart';
import 'features/home/view_model/user_profile_view_model.dart';
import 'features/mapping/view_model/mapping_lokasi_view_model.dart';
import 'features/nyangkut/view_model/nyangkut_list_view_model.dart';
import 'features/nyangkut/view_model/nyangkut_detail_view_model.dart';
import 'features/bongkar_kd/view_model/kd_bongkar_view_model.dart';
import 'core/view_models/lokasi_view_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenProvider>(create: (_) => SharedPrefsTokenProvider()),
        ProxyProvider<TokenProvider, ApiClient>(
          update: (_, tp, __) => ApiClient(tokenProvider: tp),
        ),
        ChangeNotifierProvider(create: (_) => StockOpnameViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameInputViewModel()),
        ChangeNotifierProvider(create: (_) => PreviewLabelViewModel()),
        ChangeNotifierProvider(create: (_) => PDFViewModelS4S()),
        ChangeNotifierProvider(create: (_) => PDFViewModelST()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => MappingLokasiViewModel()),
        ChangeNotifierProvider(create: (_) => QcSpkHeaderViewModel()),
        ChangeNotifierProvider(create: (_) => NyangkutListViewModel()),
        ChangeNotifierProvider(create: (_) => NyangkutDetailViewModel()),
        ChangeNotifierProvider(create: (_) => LokasiViewModel()),
        ChangeNotifierProvider(create: (_) => KDBongkarViewModel()),
        ChangeNotifierProvider(create: (_) => KDBongkarDetailViewModel()),
        ChangeNotifierProvider(create: (_) => KayuBulatViewModel()),
        ChangeNotifierProvider(create: (_) => KayuBulatAttachmentViewModel()),
        ChangeNotifierProvider(create: (_) => QcSawmillHeaderViewModel()),
        // Jenis Kayu
        ProxyProvider<ApiClient, JenisKayuRepository>(
          update: (_, api, __) => JenisKayuRepository(api),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              JenisKayuViewModel(repo: ctx.read<JenisKayuRepository>()),
        ),
        // Mesin Sawmill
        ProxyProvider<ApiClient, MesinSawmillRepository>(
          update: (_, api, __) => MesinSawmillRepository(api),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              MesinSawmillViewModel(repo: ctx.read<MesinSawmillRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'WPS Mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            // Hilangkan warna ungu dengan set secondary ke warna yang sesuai
            secondary: Colors.lightBlue,
          ),
          useMaterial3: true,
          // Bisa tambahkan customisasi lain di sini
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/stockopname': (context) => StockOpnameListScreen(),
          '/mapping': (context) => MappingLokasiScreen(),
          '/qc-spk-bj': (context) => const QcSpkHeaderScreen(),
          '/nyangkut': (context) => NyangkutMenuScreen(),
          '/bongkarkd': (context) => KdBongkarSelectedScreen(),
          '/kayu-bulat': (context) => KayuBulatScreen(),
          '/qc-sawmill': (context) => QcSawmillHeaderScreen(),
        },
      ),
    );
  }
}
