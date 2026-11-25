# Sahyadri Digital Bank — Setup & Build Instructions

## Folder Contents
- `lib/config.dart`, `lib/api_service.dart`, `lib/main.dart` -> Flutter app source files
- `pubspec.yaml` -> Flutter dependencies (`http`)
- `backend/api.py` -> FastAPI server connecting to your existing `SRC/db.py`
- `sql/02_create_serving_views.sql` -> SQL views (`v_all_transactions`, `v_account_summary`, `v_branch_daily_summary`)

## Quick Start

### 1. Database Views
Execute `sql/02_create_serving_views.sql` in SQLYog (local `dev`) and promote to Aiven (`test` and `prod`).

### 2. Backend API
Copy `backend/api.py` into your ingestion project's `SRC/` folder (next to `db.py`) and run:
```powershell
pip install fastapi uvicorn pydantic
$env:APP_ENV="prod"
uvicorn api:app --host 0.0.0.0 --port 8000
```

### 3. Initialize & Build Flutter APK inside `sahyadri_bank/`
1. Extract this ZIP directly into your `sahyadri_bank` folder (overwrite `pubspec.yaml` and `lib/main.dart` if prompted).
2. Run inside `sahyadri_bank/`:
```powershell
flutter create . --project-name sahyadri_bank --org com.sandy226700
flutter pub get
```
3. Ensure `<uses-permission android:name="android.permission.INTERNET"/>` is inside `android/app/src/main/AndroidManifest.xml`.
4. Build the release APK:
```powershell
flutter build apk --release `
  --dart-define=APP_ENV=PROD `
  --dart-define=API_URL=http://127.0.0.1:8000 `
  --dart-define=DEV_USER=sandy226700 `
  --dart-define=DEV_PASS=SahyadriProd@2026
```

## Unlocking Developer Ops Mode in App
Tap **Sahyadri Digital Bank** in the top app bar **3 times** (or tap the lock icon) and sign in with your `DEV_USER` and `DEV_PASS` credentials.
