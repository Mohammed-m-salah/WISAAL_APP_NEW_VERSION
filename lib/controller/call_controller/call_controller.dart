import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wissal_app/model/audio_call_model.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/call_page/audio_call_page.dart';

class CallController extends GetxController {
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;
  final uuid = Uuid();

  String? lastShownCallId;

  @override
  void onInit() {
    super.onInit();
    listenToIncomingCalls();
  }

  /// الاستماع للمكالمات الواردة
  void listenToIncomingCalls() {
    final currentUserId = auth.currentUser?.id;
    if (currentUserId == null) return;

    getCallNotification().listen((callList) {
      // نفس الكود الحالي
      for (final callData in callList) {
        final isNew = callData.id != lastShownCallId;
        final isDialing = callData.status == 'dialing';
        final isForCurrentUser = callData.reciverUid == currentUserId;

        if (isDialing && isNew && isForCurrentUser) {
          lastShownCallId = callData.id;
          _showIncomingCallSnackbar(callData);
          break;
        }
      }
    }, onError: (err) {
      print("❌ خطأ في الاستماع للمكالمات: $err");

      // إعادة المحاولة بعد 5 ثوانٍ
      if (err.toString().contains('timedOut')) {
        Future.delayed(const Duration(seconds: 5), () {
          print("🔄 إعادة محاولة الاتصال...");
          listenToIncomingCalls();
        });
      }
    });
  }

  /// عرض Snackbar للمكالمة الواردة
  void _showIncomingCallSnackbar(AudioCallModel callData) {
    Get.snackbar(
      "📞 مكالمة واردة من ${callData.callerName}",
      "اضغط للرد أو إنهاء المكالمة",
      duration: const Duration(minutes: 1),
      backgroundColor: Colors.amber.shade700,
      icon: const Icon(Icons.call, color: Colors.white),
      barBlur: 0,
      isDismissible: false,
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      onTap: (snack) {
        _goToAudioCallPage(callData);
        Get.closeCurrentSnackbar();
      },
      mainButton: TextButton(
        onPressed: () {
          endCall(callData.id!);
          Get.closeCurrentSnackbar();
        },
        child: const Text('❌ إنهاء', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> callAction(UserModel receiver, UserModel caller) async {
    final String id = uuid.v6();

    final newCall = AudioCallModel(
      id: id,
      callerName: caller.name,
      callerPic: caller.profileimage,
      callerEmail: caller.email,
      callerUid: caller.id,
      reciverUid: receiver.id,
      reciverName: receiver.name,
      reciverPic: receiver.profileimage,
      reciverEmail: receiver.email,
      status: 'dialing',
    );

    try {
      await db.from('notification').insert(newCall.toJson());
      print("📤 تم إرسال المكالمة");

      // إنهاء تلقائي إذا لم يُرد عليها
      Future.delayed(const Duration(seconds: 30), () async {
        final call = await db
            .from('notification')
            .select('status')
            .eq('id', id)
            .maybeSingle();

        if (call != null && call['status'] == 'dialing') {
          await endCall(id);
        }
      });
    } catch (e) {
      print("❌ فشل إرسال المكالمة: $e");
      Get.snackbar("خطأ", "تعذر إرسال المكالمة");
    }
  }

  /// إنهاء المكالمة
  Future<void> endCall(String callId) async {
    try {
      await db
          .from('notification')
          .update({'status': 'ended'}).eq('id', callId);

      print("✅ تم إنهاء المكالمة");
    } catch (e) {
      print("❌ فشل إنهاء المكالمة: $e");
      Get.snackbar("خطأ", "تعذر إنهاء المكالمة");
    }
  }

  /// فتح صفحة المكالمة
  void _goToAudioCallPage(AudioCallModel callData) {
    final caller = UserModel(
      id: callData.callerUid,
      name: callData.callerName,
      email: callData.callerEmail,
      profileimage: callData.callerPic,
    );

    Get.to(() => AudioCallPage(target: caller));
  }

  /// بث حي للإشعارات من Supabase
  Stream<List<AudioCallModel>> getCallNotification() {
    return db
        .from('notification')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false)
        .map((eventList) =>
            eventList.map((json) => AudioCallModel.fromJson(json)).toList());
  }
}
