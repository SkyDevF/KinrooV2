# การตั้งค่า Google Sign-In สำหรับ Play Store

## ✅ สิ่งที่ทำเสร็จแล้ว

1. **Package Name**: `com.kinroo.app` ✅
2. **SHA-1 Fingerprint**: `70:EF:B7:55:85:34:70:1B:C8:1C:F7:7A:CE:D9:4B:D8:EB:6B:D5:08` ✅
3. **Client ID**: ใช้ `620249493204-70365l3p950kro64detl4k2d3o01i8oo.apps.googleusercontent.com` ✅
4. **Firebase Configuration**: `google-services.json` มีการตั้งค่าที่ถูกต้องแล้ว ✅

## 🔧 ขั้นตอนที่ต้องทำเพิ่มเติม

### 1. ตรวจสอบ Google Cloud Console

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เลือกโปรเจค `kinroo-8b3a0`
3. ไปที่ **APIs & Services** > **Credentials**
4. ตรวจสอบว่า OAuth 2.0 Client ID มีการตั้งค่าดังนี้:
   - **Application type**: Android
   - **Package name**: `com.kinroo.app`
   - **SHA-1 certificate fingerprint**: `70:EF:B7:55:85:34:70:1B:C8:1C:F7:7A:CE:D9:4B:D8:EB:6B:D5:08`

### 2. เพิ่ม SHA-1 Fingerprint ของ Play Store (สำคัญมาก!)

เมื่ออัปโหลดแอพไปยัง Play Store, Google จะสร้าง SHA-1 fingerprint ใหม่ ต้องเพิ่มใน Firebase:

1. ไปที่ [Play Console](https://play.google.com/console/)
2. เลือกแอพ Kinroo
3. ไปที่ **Setup** > **App signing**
4. คัดลอก **SHA-1 certificate fingerprint** ของ **App signing key certificate**
5. กลับไปที่ [Firebase Console](https://console.firebase.google.com/)
6. เลือกโปรเจค `kinroo-8b3a0`
7. ไปที่ **Project Settings** > **Your apps** > **Android app**
8. คลิก **Add fingerprint** และเพิ่ม SHA-1 ของ Play Store
9. ดาวน์โหลด `google-services.json` ใหม่และแทนที่ไฟล์เดิม

### 3. ตรวจสอบ OAuth Consent Screen

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. ไปที่ **APIs & Services** > **OAuth consent screen**
3. ตรวจสอบว่าสถานะเป็น **Published** หรือ **In production**
4. เพิ่ม **Authorized domains** ถ้าจำเป็น

### 4. เปิดใช้งาน Google Sign-In API

1. ไปที่ **APIs & Services** > **Library**
2. ค้นหา "Google Sign-In API" หรือ "Google+ API"
3. คลิก **Enable**

## 🧪 การทดสอบ

### ทดสอบใน Development
```bash
flutter run --release
```

### ทดสอบหลังอัปโหลด Play Store
1. อัปโหลด AAB ไฟล์ไปยัง Play Console
2. ทดสอบผ่าน Internal Testing หรือ Closed Testing
3. ตรวจสอบว่า Google Sign-In ทำงานได้

## 🚨 ปัญหาที่อาจเกิดขึ้น

### 1. "Sign in failed" หรือ "12500 error"
- **สาเหตุ**: SHA-1 fingerprint ไม่ตรงกัน
- **แก้ไข**: เพิ่ม SHA-1 ของ Play Store ใน Firebase

### 2. "Developer Error" หรือ "10"
- **สาเหตุ**: Client ID ไม่ถูกต้อง
- **แก้ไข**: ตรวจสอบ Client ID ใน Google Cloud Console

### 3. "Network Error"
- **สาเหตุ**: Google Sign-In API ไม่ได้เปิดใช้งาน
- **แก้ไข**: เปิดใช้งาน API ใน Google Cloud Console

## 📝 หมายเหตุสำคัญ

1. **ใช้ Release Build**: Google Sign-In จะทำงานได้เฉพาะใน release mode เท่านั้น
2. **SHA-1 Fingerprint**: ต้องมีทั้ง development และ production fingerprint
3. **Package Name**: ต้องตรงกันทุกที่ (`com.kinroo.app`)
4. **Client ID**: ใช้ Android Client ID ไม่ใช่ Web Client ID

## 🔄 การอัปเดต google-services.json

หลังจากเพิ่ม SHA-1 ของ Play Store แล้ว:
1. ดาวน์โหลด `google-services.json` ใหม่จาก Firebase
2. แทนที่ไฟล์ใน `android/app/google-services.json`
3. Build แอพใหม่

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```