# 🚨 แก้ไข Google Sign-In Error 10 (Developer Error)

## ปัญหาที่เกิดขึ้น
```
Google Sign-Up Error: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

## 🔍 สาเหตุ
Error 10 = Developer Error เกิดจาก SHA-1 fingerprint ไม่ตรงกันระหว่าง:
- Debug keystore: `FB:1F:10:F3:2C:4A:5F:B3:E8:8F:67:93:47:65:A6:EF:73:BA:65:0D`
- Release keystore: `70:EF:B7:55:85:34:70:1B:C8:1C:F7:7A:CE:D9:4B:D8:EB:6B:D5:08`

## ✅ วิธีแก้ไข

### 1. เพิ่ม SHA-1 Fingerprint ใน Firebase Console

1. ไปที่ [Firebase Console](https://console.firebase.google.com/)
2. เลือกโปรเจค `kinroo-8b3a0`
3. ไปที่ **Project Settings** (⚙️) > **Your apps**
4. เลือก Android app `com.kinroo.app`
5. คลิก **Add fingerprint**
6. เพิ่ม SHA-1 fingerprint สำหรับ debug:
   ```
   FB:1F:10:F3:2C:4A:5F:B3:E8:8F:67:93:47:65:A6:EF:73:BA:65:0D
   ```
7. คลิก **Save**

### 2. ดาวน์โหลด google-services.json ใหม่

1. หลังจากเพิ่ม SHA-1 แล้ว คลิก **Download google-services.json**
2. แทนที่ไฟล์เดิมใน `android/app/google-services.json`

### 3. ตรวจสอบ Google Cloud Console

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เลือกโปรเจค `kinroo-8b3a0`
3. ไปที่ **APIs & Services** > **Credentials**
4. ตรวจสอบ OAuth 2.0 Client IDs:
   - ต้องมี Android client สำหรับ `com.kinroo.app`
   - ต้องมี SHA-1 fingerprint ทั้ง debug และ release

### 4. Clean และ Rebuild

```bash
flutter clean
flutter pub get
flutter run --debug
```

## 🧪 การทดสอบ

### Debug Mode
```bash
flutter run --debug
```

### Release Mode
```bash
flutter run --release
```

## 📋 Checklist

- [ ] เพิ่ม debug SHA-1 fingerprint ใน Firebase
- [ ] ดาวน์โหลด google-services.json ใหม่
- [ ] ตรวจสอบ OAuth client ใน Google Cloud Console
- [ ] Clean และ rebuild แอพ
- [ ] ทดสอบ Google Sign-In

## 🔧 คำสั่งที่ใช้

### ดู SHA-1 fingerprint
```bash
# Debug keystore
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android

# Release keystore
keytool -list -v -keystore android/app/key.jks -alias key -storepass 258025 -keypass 258025
```

### Build commands
```bash
flutter clean
flutter pub get
flutter build apk --debug
flutter build appbundle --release
```

## 🎯 ผลลัพธ์ที่คาดหวัง

หลังจากทำตามขั้นตอนแล้ว Google Sign-In ควรทำงานได้ทั้งใน:
- Debug mode (ใช้ debug SHA-1)
- Release mode (ใช้ release SHA-1)
- Play Store (ใช้ Play Store SHA-1)

## 🚨 หมายเหตุสำคัญ

1. **ต้องมี SHA-1 fingerprint ครบทุก environment**:
   - Debug: `FB:1F:10:F3:2C:4A:5F:B3:E8:8F:67:93:47:65:A6:EF:73:BA:65:0D`
   - Release: `70:EF:B7:55:85:34:70:1B:C8:1C:F7:7A:CE:D9:4B:D8:EB:6B:D5:08`
   - Play Store: (จะได้หลังอัปโหลด)

2. **Package name ต้องตรงกัน**: `com.kinroo.app`

3. **ไม่ต้องใส่ clientId ใน GoogleSignIn constructor** สำหรับ Android