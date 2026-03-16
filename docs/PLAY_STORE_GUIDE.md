# Google Play Store Publishing Guide — Jyotish AI

## Prerequisites

1. **Google Play Developer Account** ($25 one-time fee) at https://play.google.com/console
2. **Android keystore** for signing the release APK/AAB
3. **Privacy Policy URL** — hosted on your website
4. **App icons** — 512×512 PNG (high-res) and adaptive icon assets
5. **Feature graphic** — 1024×500 PNG
6. **Screenshots** — Minimum 2 per device type (phone, tablet)

---

## Step 1: Generate a Signing Key

```bash
keytool -genkey -v -keystore ~/jyotish-ai-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias jyotish-ai
```

Create `flutter_app/android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=jyotish-ai
storeFile=/path/to/jyotish-ai-release.jks
```

**IMPORTANT:** Never commit keystore or key.properties to version control.

---

## Step 2: Configure Release Signing

Edit `flutter_app/android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## Step 3: Update AndroidManifest.xml Permissions

Ensure `flutter_app/android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## Step 4: Build the App Bundle

```bash
cd flutter_app

# Clean build
flutter clean
flutter pub get

# Build release AAB (preferred for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Step 5: Create Play Store Listing

### App Details
- **App name:** Jyotish AI — Vedic Astrology
- **Short description (80 chars):** AI-powered Vedic astrology. Generate kundali charts. Get intelligent readings.
- **Full description (4000 chars):**

```
Jyotish AI is a self-learning Vedic astrology intelligence system that combines ancient wisdom with modern artificial intelligence.

FEATURES:
• Accurate Kundali Generation — Compute birth charts using precise astronomical calculations with Lahiri, Raman, or KP ayanamsa systems.
• South Indian Chart Visualization — Beautiful, interactive chart display with all 9 grahas.
• AI-Powered Interpretations — Ask questions about your chart and receive intelligent answers grounded in classical texts.
• Multiple Tradition Support — Parashara, Jaimini, Classical Hora, Prasna, and more.
• Yoga Detection — Automatic identification of Pancha Mahapurusha, Raja, Gajakesari, Neecha Bhanga, and other yogas.
• Vimshottari Dasha Timeline — Visual dasha period tracker with current period highlighting.
• Knowledge Library — Browse the classical texts that power the AI.
• Divisional Charts — D1 through D12 divisional chart calculations.
• Nakshatra Analysis — Complete 27-nakshatra analysis with pada and lord information.

TRADITIONS:
Knowledge is drawn from classical texts including Brihat Parasara Hora Shastra, Phaladipika by Mantreshwara, Prasna Marga, and other revered sources. The AI respects tradition boundaries and never mixes incompatible systems.

DISCLAIMER:
Astrological interpretations are provided for educational and entertainment purposes only. They should not be used as a substitute for professional advice.
```

### Category & Tags
- **Category:** Entertainment or Education
- **Tags:** astrology, vedic, kundali, horoscope, jyotish, birth chart

### Content Rating
- Complete the content rating questionnaire (select "Reference/Educational")
- IARC rating will typically be "Everyone" or "Everyone 10+"

---

## Step 6: Privacy & Compliance

1. **Privacy Policy:** Host the PRIVACY_POLICY.md as a webpage and enter the URL.
2. **Data Safety Form:** Complete the data safety section in Play Console:
   - Data collected: Email, name, birth data, location (for birth place)
   - Data shared: No data shared with third parties
   - Data encrypted: Yes (in transit)
   - Data deletion: Users can request deletion
3. **Permissions Declaration:** Explain why each permission is needed.
4. **Content Policy:** Ensure the disclaimer about astrological advice is visible in the app.

---

## Step 7: Upload & Submit

1. Go to Play Console → Create App
2. Fill in all listing details
3. Upload the AAB file under "Production" release track
4. Complete all policy declarations
5. Submit for review

### Review Timeline
- Initial review: 3–7 days
- Updates: Usually 1–3 days

### Common Rejection Reasons to Avoid
- Missing privacy policy
- Insufficient app description
- Missing content rating
- Permissions not justified
- Misleading claims about astrological accuracy (always include disclaimer)

---

## Step 8: Post-Launch

1. **Monitor:** Check crash reports in Play Console and Firebase Crashlytics.
2. **Respond:** Reply to user reviews promptly.
3. **Update:** Push regular updates with new books and improved interpretations.
4. **Analytics:** Track user engagement to prioritize features.

---

## Android App Configuration Summary

| Setting | Value |
|---------|-------|
| applicationId | `com.jyotishai.app` |
| minSdkVersion | 21 (Android 5.0) |
| targetSdkVersion | 34 (Android 14) |
| compileSdkVersion | 34 |
| versionCode | 1 |
| versionName | 1.0.0 |
