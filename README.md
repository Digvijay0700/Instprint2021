🖨️ InstPrint – Smart Student Printing App

InstPrint is a smart, student-friendly printing solution built with Flutter and Firebase.
It allows students to upload documents, set per-page print options, and get instant, accurate price calculations based on shop rates fetched from Firestore.

Designed for convenience — whether you're printing assignments or project reports, InstPrint makes it fast, fair, and flexible.

🚀 Features

🧾 Core Functionality

📤 Upload PDF / Word files directly from your device

📑 Set page-wise color modes (Color or B/W) manually

🔄 Support for single- & double-sided printing logic (using ceil(pages/2))

💰 Dynamic real-time price calculation (integer-based, no decimals)

🔒 Firebase Authentication (Email & Password login/register)

☁️ Firebase Firestore & Storage integration for user data and file management

🛒 Add multiple batches to Cart before checkout

📍 Shop-based rate fetching from Firestore

💡 Pricing Logic

All price calculations are done using integer-only math for accuracy and simplicity.

Option

Source

Description

bw_single_page_price

Firestore

Black & White print (per page)

color_single_page_price

Firestore

Color print (per page)

binding_price

Firestore

Optional binding cost

punch_price, staple_price

Free (₹0)

Free services (Punching, Stapling)

double_sided_discount

Firestore (optional)

Reduces cost for duplex printing (e.g., ₹1 off per sheet)

🧮 Formula Example:

total_price = (bw_pages * bw_rate + color_pages * color_rate) 
              + binding_price 
              + punch_price 
              + staple_price 
              * number_of_prints 
              - double_sided_discount (if applicable)


🧠 Tech Stack

Layer

Technology

Frontend

Flutter (Dart)

Backend

Firebase (Auth, Firestore, Storage)

State Management

setState / Provider (as per your setup)

Database

Cloud Firestore

Authentication

Firebase Auth

Deployment

Flutter App (Android + Web compatible)

📂 Firestore Structure Example

shopkeepers (collection)
└── <shopId> (document)
    ├── name: "XYZ Print Shop"
    ├── rates: {
    │   "bw_single_page_price": 2,
    │   "color_single_page_price": 10,
    │   "binding_price": 15,
    │   "punch_price": 0,
    │   "staple_price": 0
    │ }
    └── ...


🧭 App Flow

Login / Register

User signs up using email & password.

Details stored in Firestore under users collection.

File Upload Page

User selects a document.

Chooses color/BW options, sides, and optional binding.

Real-time price calculation shown dynamically.

Manual Per-Page Selection

Each page can be set to “Color” or “B/W”.

UI highlights color pages (light red background).

Cart Page

Displays all added print batches.

Option to add another file or proceed to payment.

🎨 UI Highlights

Modern amber + white theme

Clean, boxed option containers

Collapsible tiles for manual per-page selection

Dialogs & dropdowns for user-friendly customization

Loading animations for smooth experience

🏗️ Project Setup

1️⃣ Clone the Repository

git clone [https://github.com/](https://github.com/)<your-username>/InstPrint.git
cd InstPrint
