import 'dart:convert';
import 'package:http/http.dart' as http;

class SMSNotificationService {
  static const String _apiKey = 'e58d3fa9-d0b6-4e29-9862-21e2d4e8a69c';
  static const String _baseUrl = 'https://api.textbee.dev/api/v1';
  
  // You'll need to replace this with your actual device ID from textbee.dev dashboard
  // To get your device ID:
  // 1. Go to https://textbee.dev
  // 2. Install the TextBee app on your Android device
  // 3. Link your device using the API key: e58d3fa9-d0b6-4e29-9862-21e2d4e8a69c
  // 4. Get your device ID from the dashboard
  static const String _deviceId = '68f8c6f76a418a16ec0e960a'; // TextBee device ID
  
  /// Sends SMS notification to user upon successful login
  static Future<bool> sendLoginSuccessSMS({
    required String phoneNumber,
    required String userName,
    String? loginTime,
  }) async {
    try {
      // Format phone number to include country code if not present
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        // Add +1 for US numbers if no country code is provided
        // You may need to adjust this based on your target audience
        if (formattedPhone.length == 10) {
          formattedPhone = '+1$formattedPhone';
        } else if (!formattedPhone.startsWith('+')) {
          formattedPhone = '+$formattedPhone';
        }
      }

      // Create the message
      String message = 'Welcome back to NutriCare, $userName! You have successfully logged in.';
      if (loginTime != null) {
        message += ' Login time: ${DateTime.parse(loginTime).toString().split('.')[0]}';
      }

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'recipients': [formattedPhone],
        'message': message,
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl/gateway/devices/$_deviceId/send-sms'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SMS sent successfully to $formattedPhone');
        print('📱 SMS Response: ${response.body}');
        return true;
      } else {
        print('❌ Failed to send SMS. Status: ${response.statusCode}');
        print('📱 Error Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ SMS sending error: $e');
      return false;
    }
  }

  /// Sends a custom SMS message
  static Future<bool> sendCustomSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Format phone number
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.length == 10) {
          formattedPhone = '+1$formattedPhone';
        } else if (!formattedPhone.startsWith('+')) {
          formattedPhone = '+$formattedPhone';
        }
      }

      final Map<String, dynamic> requestBody = {
        'recipients': [formattedPhone],
        'message': message,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/gateway/devices/$_deviceId/send-sms'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Custom SMS sent successfully to $formattedPhone');
        return true;
      } else {
        print('❌ Failed to send custom SMS. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Custom SMS sending error: $e');
      return false;
    }
  }

  /// Validates if the service is properly configured
  static bool isConfigured() {
    return _deviceId != 'YOUR_DEVICE_ID' && _deviceId.isNotEmpty;
  }

  /// Gets the current device ID (for debugging)
  static String getDeviceId() {
    return _deviceId;
  }
}
