import 'package:telephony/telephony.dart';

class SMSService {
  final Telephony telephony = Telephony.instance;

  void startListening(
      Function(String message, String sender) onMessageReceived) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (message.body != null && message.address != null) {
          onMessageReceived(message.body!, message.address!);
        }
      },
      listenInBackground: false,
    );
  }

  Future<void> requestPermissions() async {
    await telephony.requestSmsPermissions;
  }
}
