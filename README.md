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
