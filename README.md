# 🖨️ InstPrint – Smart Student Printing App

InstPrint is a **smart, student-friendly printing solution** built with **Flutter** and **Firebase**.  
It allows students to upload documents, set per-page print options, and get **instant, accurate price calculations** based on shop rates fetched from Firestore.  

Designed for convenience — whether you're printing assignments or project reports, InstPrint makes it fast, fair, and flexible.  

---

## 🚀 Features

### 🧾 Core Functionality
- 📤 Upload **PDF / Word** files directly from your device  
- 📑 Set **page-wise color modes** (Color or B/W) manually  
- 🔄 Support for **single- & double-sided** printing logic (using `ceil(pages/2)`)  
- 💰 Dynamic **real-time price calculation** (integer-based, no decimals)  
- 🔒 Firebase **Authentication** (Email & Password login/register)  
- ☁️ Firebase **Firestore & Storage** integration for user data and file management  
- 🛒 Add multiple batches to **Cart** before checkout  
- 📍 Shop-based **rate fetching** from Firestore  

---

## 💡 Pricing Logic

All price calculations are done using **integer-only math** for accuracy and simplicity.  

| Option | Source | Description |
|--------|---------|-------------|
| `bw_single_page_price` | Firestore | Black & White print (per page) |
| `color_single_page_price` | Firestore | Color print (per page) |
| `binding_price` | Firestore | Optional binding cost |
| `punch_price`, `staple_price` | Free (`₹0`) |
| `double_sided_discount` | Firestore (optional) | Reduces cost for duplex printing |


## 🧠 Tech Stack

| Layer | Technology |
|-------|-------------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **State Management** | setState / Provider (as per your setup) |
| **Database** | Cloud Firestore |
| **Authentication** | Firebase Auth |
| **Hosting** | Flutter App (Android + Web compatible) |

---
## 🧭 App Flow

1. **Login / Register**
   - User signs up using email & password.
   - Details stored in Firestore under `users` collection.

2. **File Upload Page**
   - User selects a document.
   - Chooses color/BW options, sides, and optional binding.
   - Real-time price calculation shown dynamically.

3. **Manual Per-Page Selection**
   - Each page can be set to “Color” or “B/W”.
   - UI highlights color pages (light red background).

4. **Cart Page**
   - Displays all added print batches.
   - Option to add another file or proceed to payment.

---
---

## 🎨 UI Highlights

- Modern **amber + white theme**  
- Clean, boxed option containers  
- Collapsible tiles for manual per-page selection  
- Dialogs & dropdowns for user-friendly customization  
- Loading animations for smooth experience  

---
