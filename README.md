Wave - Full-Stack Real-Time Chat Application (Flutter + Django)
&lt;p align="center">
&lt;img src="https://raw.githubusercontent.com/Divodude/Wave/main/assets/logo.png" alt="Wave Logo" width="150"/>
&lt;/p>

&lt;p align="center">
A complete real-time chat application built with a Flutter frontend and a Django REST Framework backend with Channels for WebSocket communication.
&lt;/p>

&lt;p align="center">
&lt;img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&amp;logo=flutter&amp;logoColor=white" alt="Flutter">
&lt;img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&amp;logo=dart&amp;logoColor=white" alt="Dart">
&lt;img src="https://img.shields.io/badge/Django-4.x-092E20?style=for-the-badge&amp;logo=django&amp;logoColor=white" alt="Django">
&lt;img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&amp;logo=python&amp;logoColor=white" alt="Python">
&lt;/p>

About The Project
Wave is a full-stack, real-time messaging application. This repository is a monorepo containing two primary components in separate branches:

master branch: The backend API built with Django REST Framework and Django Channels to handle WebSocket connections for real-time chat.
main branch: The cross-platform mobile UI built with Flutter, which consumes the Django API.
✨ Features
Real-Time Two-Way Messaging: Instantaneous message delivery using WebSockets.
User Authentication: Secure user registration and login system.
Chat History: All messages are persisted in the database.
Clean, Modern UI: A user-friendly interface built with Flutter.
Scalable Backend: Asynchronous backend capable of handling multiple connections.
Backend Setup (Django REST Framework)
The backend is located on the master branch.

1. Clone the Backend Repository
Clone the master branch into a dedicated folder (e.g., wave-backend).

Bash

git clone --branch master https://github.com/Divodude/Wave.git wave-backend
cd wave-backend
2. Prerequisites
Python 3.10+
Pip & Virtualenv
3. Installation & Setup
Create and activate a virtual environment:
Bash

python -m venv venv
# On Windows
venv\Scripts\activate
# On macOS/Linux
source venv/bin/activate
Install dependencies from requirements.txt:
Bash

pip install -r requirements.txt
Apply database migrations:
Bash

python manage.py migrate
4. Running the Backend Server
Start the Django development server:
Bash

python manage.py runserver
The backend API will be running at http://127.0.0.1:8000/.
Frontend Setup (Flutter)
The frontend is located on the main branch.

1. Clone the Frontend Repository
Clone the main branch into a dedicated folder (e.g., wave-frontend).

Bash

git clone --branch main https://github.com/Divodude/Wave.git wave-frontend
cd wave-frontend
2. Prerequisites
Flutter SDK (version 3.x)
A code editor like VS Code or Android Studio
An Android/iOS emulator or a physical device
3. Installation & Setup
Get Flutter packages:
Bash

flutter pub get
4. Configure the API Endpoint
Before running the app, you may need to point it to your local backend server.

Look for the file where the base API URL is defined (e.g., in a lib/utils/constants.dart or lib/api/api_client.dart file).
Change the URL to your local machine's IP address (e.g., http://10.0.2.2:8000 for the Android emulator, or http://127.0.0.1:8000 for other platforms).
5. Running the Frontend App
Run the Flutter application:
Bash

flutter run
The app will build and launch on your connected device or emulator.
🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

Fork the Project
Create your Feature Branch (git checkout -b feature/AmazingFeature)
Commit your Changes (git commit -m 'Add some AmazingFeature')
Push to the Branch (git push origin feature/AmazingFeature)
Open a Pull Request
