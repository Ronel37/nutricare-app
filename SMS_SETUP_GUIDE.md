# SMS Setup Guide for NutriCare App

This guide will help you set up SMS notifications using textbee.dev for your NutriCare app.

## Prerequisites

- Android device (required for textbee.dev)
- Your API key: `e58d3fa9-d0b6-4e29-9862-21e2d4e8a69c`

## Setup Steps

### 1. Set up TextBee Account and Device

1. **Create Account**: Go to [textbee.dev](https://textbee.dev) and create an account
2. **Install App**: Download the TextBee Android app from [dl.textbee.dev](https://dl.textbee.dev)
3. **Link Device**: 
   - Open the TextBee app on your Android device
   - Enter your API key: `e58d3fa9-d0b6-4e29-9862-21e2d4e8a69c`
   - Or scan the QR code from the dashboard
4. **Get Device ID**: 
   - Go to your TextBee dashboard
   - Find your device ID (it will be something like `device_123456`)
   - Copy this device ID

### 2. Configure the App

1. **Update Device ID**: 
   - Open `lib/services/sms_notification_service.dart`
   - Replace `YOUR_DEVICE_ID` with your actual device ID from step 1
   - Save the file

2. **Test the Setup**:
   - You can test the SMS service using the test utility
   - Update the phone number in `lib/services/sms_test_service.dart` with your own number
   - Run the test to verify everything works

### 3. User Experience

Once configured, users can:

1. **Add Phone Number**: 
   - Go to Settings → Profile Settings
   - Add their phone number with country code (e.g., +1234567890)
   - Save their profile

2. **Receive SMS Notifications**:
   - When users successfully log in, they'll receive an SMS notification
   - The message will be: "Welcome back to NutriCare, [Name]! You have successfully logged in."

## Features Implemented

### ✅ SMS Service (`lib/services/sms_notification_service.dart`)
- Sends login success SMS notifications
- Supports custom SMS messages
- Handles phone number formatting
- Error handling and logging

### ✅ Profile Settings (`lib/pages/user/profile_settings.dart`)
- Users can add/update their phone number
- Form validation for phone numbers
- Integration with Firestore user data

### ✅ Login Integration (`lib/services/database.dart`)
- SMS notifications sent on successful login
- Only sends SMS if user has phone number
- Non-blocking (login continues even if SMS fails)

### ✅ Settings Integration (`lib/pages/user/settings_page.dart`)
- Added "Profile Settings" option
- Easy access to phone number management

## Testing

### Manual Testing
1. Set up your device ID in the SMS service
2. Add a phone number to your profile
3. Log out and log back in
4. Check if you receive the SMS notification

### Programmatic Testing
Use the test service in `lib/services/sms_test_service.dart`:

```dart
// Test login SMS
await SMSTestService.testSMSService();

// Test custom SMS
await SMSTestService.testCustomSMS();
```

## Troubleshooting

### Common Issues

1. **"SMS Service not configured"**
   - Make sure you've updated the device ID in `sms_notification_service.dart`
   - Verify your device is linked in the TextBee dashboard

2. **"No phone number found"**
   - Users need to add their phone number in Profile Settings
   - Phone number should include country code (e.g., +1 for US)

3. **SMS not received**
   - Check if your Android device with TextBee app is online
   - Verify the phone number format is correct
   - Check the console logs for error messages

### Debug Information

The app will log SMS-related information to the console:
- ✅ Success messages when SMS is sent
- ❌ Error messages if SMS fails
- ℹ️ Info messages for missing phone numbers

## Security Notes

- The API key is embedded in the code for simplicity
- In production, consider using environment variables or secure storage
- Phone numbers are stored in Firestore with user data
- SMS sending is non-blocking to prevent login failures

## Next Steps

1. Complete the setup steps above
2. Test with your own phone number
3. Deploy and test with real users
4. Monitor SMS delivery and user feedback

## Support

If you encounter issues:
1. Check the console logs for error messages
2. Verify your TextBee device is online and linked
3. Test with a simple phone number first
4. Contact textbee.dev support if needed

