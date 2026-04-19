# Ops Scripts

## 1) Install dependencies (once)

```powershell
npm.cmd --prefix scripts install
```

## 2) Migrate old tutor geo data

Set service account credential path first:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="D:\path\to\service-account.json"
$env:FIREBASE_PROJECT_ID="aplikasi-educonnect-id"
```

Dry run:

```powershell
npm.cmd --prefix scripts run migrate:tutors:geo:dry
```

Apply changes:

```powershell
npm.cmd --prefix scripts run migrate:tutors:geo:apply
```

## 3) Deploy Firestore/Storage rules and indexes

If interactive login is available:

```powershell
firebase login
.\scripts\deploy_rules_indexes_storage.ps1 -ProjectId "aplikasi-educonnect-id"
```

If using CI token:

```powershell
$env:FIREBASE_TOKEN="YOUR_TOKEN"
.\scripts\deploy_rules_indexes_storage.ps1 -ProjectId "aplikasi-educonnect-id"
```
