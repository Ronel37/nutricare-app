import 'package:nutricare_app/services/sms_notification_service.dart';

class SMSTestService {
  /// Test the SMS service with a sample phone number
  static Future<void> testSMSService() async {
    print('🧪 Testing SMS Service...');
    
    // Check if service is configured
    if (!SMSNotificationService.isConfigured()) {
      print('❌ SMS Service not configured!');
      print('📱 Please update the device ID in sms_notification_service.dart');
      print('🔧 Current device ID: ${SMSNotificationService.getDeviceId()}');
      return;
    }
    
    print('✅ SMS Service is configured');
    
    // Test with a sample phone number (replace with your own for testing)
    String testPhoneNumber = '+1234567890'; // Replace with your actual phone number
    String testUserName = 'Test User';
    
    print('📱 Testing SMS to: $testPhoneNumber');
    
    try {
      bool result = await SMSNotificationService.sendLoginSuccessSMS(
        phoneNumber: testPhoneNumber,
        userName: testUserName,
        loginTime: DateTime.now().toIso8601String(),
      );
      
      if (result) {
        print('✅ SMS test successful!');
      } else {
        print('❌ SMS test failed');
      }
    } catch (e) {
      print('❌ SMS test error: $e');
    }
  }
  
  /// Test custom SMS
  static Future<void> testCustomSMS() async {
    print('🧪 Testing Custom SMS...');
    
    if (!SMSNotificationService.isConfigured()) {
      print('❌ SMS Service not configured!');
      return;
    }
    
    String testPhoneNumber = '+1234567890'; // Replace with your actual phone number
    String testMessage = 'Hello from NutriCare! This is a test SMS message.';
    
    print('📱 Testing custom SMS to: $testPhoneNumber');
    print('💬 Message: $testMessage');
    
    try {
      bool result = await SMSNotificationService.sendCustomSMS(
        phoneNumber: testPhoneNumber,
        message: testMessage,
      );
      
      if (result) {
        print('✅ Custom SMS test successful!');
      } else {
        print('❌ Custom SMS test failed');
      }
    } catch (e) {
      print('❌ Custom SMS test error: $e');
    }
  }
}

