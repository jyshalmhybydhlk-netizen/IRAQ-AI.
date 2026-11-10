# IRAQ AI – ذكاء العراق

المشروع يجمع واجهة Flutter وخادم Python/FastAPI في حزمة واحدة.

## تشغيل Backend

```bash
cd backend
python -m venv .venv
# Windows: .venv\\Scripts\\activate
# Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

ثبّت Ollama وشغّل `ollama pull qwen2.5:3b` لاستخدام نموذج محلي. أو اضبط مزوداً سحابياً في `backend/.env`؛ لا تضع المفتاح داخل Flutter.

## بناء Flutter Android والويب

يتطلب Flutter SDK. من جذر المشروع:

```bash
flutter create --platforms=android,web --project-name iraq_ai --org iq.iraqai .
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
```

المحاكي Android يتصل افتراضياً بـ `http://10.0.2.2:8000`. للهاتف الحقيقي أدخل IP الحاسبة والمنفذ 8000 من إعدادات التطبيق. استخدم HTTPS عند النشر العام.

## GitHub Actions

بعد رفع الملفات إلى مستودع GitHub، شغّل Actions باسم Build IRAQ AI. سيختبر Backend وFlutter ويبني APK ونسخة الويب كـ Artifacts.

هذه نسخة MVP: لا تتضمن حسابات مستخدمين أو لوحة إدارة أو نموذجاً مدرباً خصيصاً. `/health` يفحص API فقط، ونجاحه لا يعني أن النموذج متاح.
