# CostReveal-SACH-Engine
CostReveal — SACH Engine: An offline-resilient FinTech prototype that reveals the true cost of loans through AI-assisted extraction, human validation, and deterministic financial analysis.

## 🚀 How to Run CostReveal

CostReveal can be run on:
1. Android physical device
2. Chrome / Flutter Web

- **Gemini** is used for Camera/Voice AI extraction.
- **Manual Entry** and **Demo Mode** work perfectly without Gemini.
- The financial calculation engine is fully local and deterministic.
- API keys must **NEVER** be committed to Git. Never paste a real API key into this file. Replace placeholders locally in your command prompt.

---

## 📋 Prerequisites

Please ensure the following tools are available and compatible with the project's `pubspec.yaml`:
- Flutter
- Dart
- Android device (or emulator) for mobile testing
- Google Chrome for Flutter Web
- Git
- Gemini API key (only if Camera/Voice AI extraction is being tested)

---

## 1. Clone the repository

```cmd
git clone https://github.com/vishwasbhattgaonkar1512-cmd/CostReveal-SACH-Engine.git
cd CostReveal-SACH-Engine
```

---

## 2. Install Flutter dependencies

Install the project's declared Flutter dependencies by running:

```cmd
flutter pub get
```

---

## 🔐 3. Configure Gemini API Key (Windows CMD)

The Gemini API key is required for:
- Camera → Gemini extraction
- Voice → Gemini extraction

*Note: Manual Entry and Demo Mode remain usable without the Gemini API.*

Set the temporary session variable in Windows CMD:

```cmd
set GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Verify that the variable exists without exposing it:

```cmd
if defined GEMINI_API_KEY (echo GEMINI_API_KEY is SET) else (echo GEMINI_API_KEY is NOT SET)
```

The key is passed securely into Flutter using:
`--dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%`

> **IMPORTANT:** Never use `echo %GEMINI_API_KEY%` as it will expose your secret in the terminal.

---

## Clear the temporary API key

To clear the variable for the current CMD session:

```cmd
set GEMINI_API_KEY=
```

Verify it is cleared:

```cmd
if defined GEMINI_API_KEY (echo GEMINI_API_KEY is SET) else (echo GEMINI_API_KEY is NOT SET)
```

---

## 📱 Run on Android Physical Device

1. Connect your Android phone through USB.
2. Enable **Developer Options** on the device.
3. Enable **USB debugging**.
4. Accept the RSA authorization prompt on the phone if shown.
5. Run the following command to find your device ID:
   ```cmd
   flutter devices
   ```
   *Your Android device should appear in the list.*
6. Run the application:
   ```cmd
   flutter run -d DEVICE_ID --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
   ```
   *(Example device ID only — use the ID returned by `flutter devices` on your machine)*
   ```cmd
   flutter run -d 10BEAG2L5N004FS --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
   ```

If Flutter automatically selects the connected device, you can use the simpler form:
```cmd
flutter run --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
```

---

## Run Android without Gemini

If you want to test Manual Entry, Human Validation, Calculation, True Cost, Evidence Trace, RBI Draft, PDF, or Demo Mode, you do not need Gemini configured:

```cmd
flutter run -d DEVICE_ID
```

---

## 🌐 Run in Chrome

First, confirm Chrome is available:
```cmd
flutter devices
```

Run in Chrome with Gemini:
```cmd
flutter run -d chrome --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
```

Run in Chrome without Gemini (for Manual/Demo testing):
```cmd
flutter run -d chrome
```

> **IMPORTANT:** Flutter Web may have platform/plugin limitations compared to Android.
> - Android Camera/Voice behavior should be validated on a physical Android device.
> - The core UI and local calculation flow can be tested in Chrome where supported.

---

## 🧪 Demo Mode — Offline Testing

Demo Mode is intended for situations with no internet, Gemini unavailability, API quota/rate-limit problems, hackathon demonstrations, or deterministic offline testing.

To use Demo Mode, run the app normally, then select **Demo Mode** from the interface. Demo Mode does not require a Gemini API key.

---

## ✍️ Manual Entry — Offline Fallback

Manual Entry can be used when Gemini is unavailable, internet is unavailable, API quota is exhausted, or Camera/Voice extraction is simply not required.

**Flow:**
Manual Entry → Human Validation → Calculate → True Cost → Evidence Trace → RBI Draft → PDF

The deterministic financial calculation remains completely local.

---

## 🏆 Recommended Hackathon Run

This practical sequence reduces dependency on live AI during a presentation:

1. Connect Android device.
2. Set Gemini API key in CMD.
3. Run: `flutter devices`
4. Run: `flutter run -d DEVICE_ID --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%`
5. Test **Manual Entry** first.
6. Test **Camera → Gemini**.
7. Test **Voice → Gemini**.
8. Verify human validation.
9. Verify True Cost.
10. Verify Evidence Trace.
11. Verify RBI Draft.
12. Verify PDF.
13. Test **Demo Mode**.
14. If Gemini/network fails at any point, switch to Manual Entry or Demo Mode.

---

## 🛠️ Troubleshooting

### Device not detected
Run `flutter devices`.
Check: USB cable, USB debugging settings, Android authorization prompt, and device connection.

### Gemini unavailable
Check if the API key is set:
```cmd
if defined GEMINI_API_KEY (echo GEMINI_API_KEY is SET) else (echo GEMINI_API_KEY is NOT SET)
```
Rerun with: `flutter run -d DEVICE_ID --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%`
If Gemini remains unavailable, use Manual Entry or Demo Mode.

### HTTP 429 / rate limit
Use Manual Entry or Demo Mode and retry later.

### Network unavailable
Use Manual Entry or Demo Mode.

### Flutter dependency issue
Run:
```cmd
flutter pub get
```

### Chrome/plugin issue
Some native plugins/features may behave differently on Web. Use a physical Android device for final Camera/Voice validation.

---

## 🔐 API Key Security

> **WARNING:** NEVER commit a Gemini API key to Git.
> NEVER put a real API key in README.md, Dart source files, screenshots, Git commits, or public repositories.

Use the temporary CMD environment variable:
```cmd
set GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```
And pass it using:
`--dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%`

If a key is accidentally exposed publicly, immediately revoke/rotate it through the provider's key management interface.

---

## ⚡ Quick Run Commands

**Windows CMD Setup:**
```cmd
set GEMINI_API_KEY=YOUR_GEMINI_API_KEY
if defined GEMINI_API_KEY (echo GEMINI_API_KEY is SET) else (echo GEMINI_API_KEY is NOT SET)
flutter devices
```

**Android:**
```cmd
flutter run -d DEVICE_ID --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
```

**Chrome:**
```cmd
flutter run -d chrome --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
```

**Without Gemini:**
```cmd
flutter run -d DEVICE_ID
```
*(or)*
```cmd
flutter run -d chrome
```

**Clear temporary key:**
```cmd
set GEMINI_API_KEY=
```
