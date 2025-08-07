import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

class DashLineView extends StatelessWidget {
  final double dashHeight;
  final double dashWith;
  final Color dashColor;
  final double fillRate; // [0, 1] totalDashSpace/totalSpace
  final Axis direction;

  DashLineView(
      {this.dashHeight = 1,
      this.dashWith = 8,
      this.dashColor = Colors.black,
      this.fillRate = 0.5,
      this.direction = Axis.horizontal});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxSize = direction == Axis.horizontal
            ? constraints.constrainWidth()
            : constraints.constrainHeight();
        final dCount = (boxSize * fillRate / dashWith).floor();
        return Flex(
          children: List.generate(dCount, (_) {
            return SizedBox(
              width: direction == Axis.horizontal ? dashWith : dashHeight,
              height: direction == Axis.horizontal ? dashHeight : dashWith,
              child: DecoratedBox(
                decoration: BoxDecoration(color: dashColor),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: direction,
        );
      },
    );
  }
}

class MussDotWidget extends StatelessWidget {
  final double dashWidth, emptyWidth, dashHeight;

  final Color dashColor;

  const MussDotWidget({
    this.dashWidth = 10,
    this.emptyWidth = 5,
    this.dashHeight = 2,
    this.dashColor = Colors.black,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(20, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              height: dashHeight,
              width: dashWidth,
              color: dashColor,
            ),
          ),
        );
      }),
    );
  }
}

Future<bool> getPermissions() async {
  final DeviceInfoPlugin info =
      DeviceInfoPlugin(); // import 'package:device_info_plus/device_info_plus.dart';
  final AndroidDeviceInfo androidInfo = await info.androidInfo;
  debugPrint('releaseVersion : ${androidInfo.version.release}');
  final int androidVersion = int.parse(androidInfo.version.release);
  bool havePermission = false;

  if (androidVersion >= 13) {
    final request = await [
      // Permission.videos,
      // Permission.photos,
      Permission.contacts,
    ].request();

    havePermission =
        request.values.every((status) => status == PermissionStatus.granted);
  } else {
    final request = await [
      // Permission.storage,
      Permission.contacts,
    ].request();
    havePermission =
        request.values.every((status) => status == PermissionStatus.granted);
    // final status = await Permission.storage.request();
    // havePermission = status.isGranted;
  }

  if (!havePermission) {
    // if no permission then open app-setting
    // await openAppSettings();
  }

  return havePermission;
}

showSnackBar(BuildContext context, String snackbarContent, Color? snackbarColor,
    double? snackbarMargin, double? snackbarElevation, int duration) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(snackbarContent),
      backgroundColor: snackbarColor,
      elevation: snackbarElevation,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(snackbarMargin!),
      duration: Duration(seconds: duration),
    ),
  );
}

AwesomeDialog awesomeDialog(BuildContext context, String title,
    String description, bool dismiss, DialogType type, Color? color,
    {VoidCallback? btnOkOnPress, VoidCallback? btnCancelOnPress}) {
  return AwesomeDialog(
    context: context,
    animType: AnimType.scale,
    dialogType: type,
    autoDismiss: dismiss,
    // body: Center(
    //   child: Text(message,
    //     style: TextStyle(fontStyle: FontStyle.italic),
    //   ),
    // ),
    customHeader: type == DialogType.info
        ? Icon(
            BootstrapIcons.check_circle_fill,
            size: 70,
            color: color,
          )
        : Icon(
            BootstrapIcons.x_circle_fill,
            size: 70,
            color: color,
          ),
    title: title,
    desc: description,
    btnOkColor: color,
    btnOkOnPress: btnOkOnPress != null ? () => btnOkOnPress() : () {},
    // btnCancelOnPress: btnCancelOnPress != null ? () => btnCancelOnPress!() : (){},
    onDismissCallback: null,
  );
}

Widget noInternet() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        'assets/no_internet.png',
        color: Colors.red,
        height: 100,
      ),
      Container(
        margin: const EdgeInsets.only(top: 20, bottom: 10),
        child: const Text(
          "No Internet connection",
          style: TextStyle(fontSize: 22),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: const Text("Check your connection, then refresh the page."),
      ),
      ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.green),
        ),
        onPressed: () async {
          // You can also check the internet connection through this below function as well
          // ConnectivityResult result = await (Connectivity().checkConnectivity());
          //  print(result.toString());
        },
        child: const Text("Refresh"),
      ),
    ],
  );
}

void showLoading([String? message]) {
  Get.dialog(
    WillPopScope(
      onWillPop: () async => true, // Prevent back button from closing the dialog
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Ensure the dialog covers the entire screen
        child: Container(
          color: ChanzoColors.primary.withOpacity(0.5),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Image.network(
                  'https://mir-s3-cdn-cf.behance.net/project_modules/disp/c3c4d331234507.564a1d23db8f9.gif', // Replace with your GIF URL
                  width: 70, // Adjust the size as needed
                  height: 70,
                ),
                // SizedBox(height: 8),
                Text(
                  message ?? 'Please wait...',
                  style: TextStyle(color: ChanzoColors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: false, // Make sure the dialog is non-dismissible
  );
}

Widget showShimmerLoader(int? _itemCount) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itemCount ?? 5,
      itemBuilder: (context, index) {
        return ListTile(
          title: Container(
            height: 20,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 16,
            color: Colors.white,
          ),
        );
      },
    ),
  );
}

//hide loading
void hideLoading() {
  if (Get.isDialogOpen!) Get.back();
}

Widget loading() {
  return const Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(ChanzoColors.primary),
    ),
  );
}
