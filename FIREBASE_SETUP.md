# การตั้งค่า Firebase สำหรับบัญชีทดลอง

## ขั้นตอนการเปิดใช้งาน Anonymous Authentication

### 1. เข้า Firebase Console
- ไปที่ https://console.firebase.google.com
- เลือกโปรเจ็กต์ Kinroo

### 2. เปิดใช้งาน Anonymous Authentication
1. ไปที่ **Authentication** > **Sign-in method**
2. ในส่วน **Sign-in providers** ให้หา **Anonymous**
3. กดที่ **Anonymous** และเปิดใช้งาน (Enable)
4. กด **Save**

### 3. ตรวจสอบ Firestore Rules
ให้แน่ใจว่า Firestore Rules อนุญาตให้ Anonymous users เขียนข้อมูลได้:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // อนุญาตให้ผู้ใช้ที่ล็อกอิน (รวม Anonymous) เข้าถึงข้อมูลของตัวเอง
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // อนุญาตให้ผู้ใช้ที่ล็อกอิน (รวม Anonymous) เข้าถึงข้อมูลอาหาร
    match /food_history/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /food_history/{userId}/items/{itemId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Deploy Firestore Rules
รันคำสั่งนี้เพื่ออัปเดต Firestore Rules:
```bash
firebase deploy --only firestore:rules
```

### 5. ทดสอบการทำงาน
1. รันแอปและกดใช้งานบัญชีทดลอง
2. ตรวจสอบใน Firebase Console > Authentication > Users
3. ควรเห็นผู้ใช้ใหม่ที่มี Provider เป็น "Anonymous"
4. ตรวจสอบใน Firestore > Data ว่าข้อมูลถูกบันทึกหรือไม่

### 5. การ Debug
หากมีปัญหา ให้ตรวจสอบ:
- Firebase Console > Authentication > Users (มี Anonymous user หรือไม่)
- Firebase Console > Firestore > Data (มีข้อมูลถูกบันทึกหรือไม่)
- Debug Console ใน Flutter (มี error หรือไม่)

### หมายเหตุ
- Anonymous Authentication ไม่ต้องการการยืนยันตัวตน
- ข้อมูลจะหายเมื่อลบแอปหรือล้างข้อมูล
- สามารถอัปเกรดเป็นบัญชีปกติได้ในภายหลัง (ต้องพัฒนาฟีเจอร์เพิ่ม)