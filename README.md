# printer_ui_win

A Flutter desktop application for Windows that connects to local or network printers and listens for printing jobs from a remote server via WebSockets.

## Table of Contents

- [Description](#description)
- [Client Usage](#client-usage)
- [Developer Usage](#developer-usage)
  - [Basic Requirements](#basic-requirements)
  - [Run Project in Development](#run-project-in-development)
  - [Build for Windows](#build-for-windows)

## Description

This project is a Windows desktop application built with Flutter. Its primary function is to act as a bridge between a web-based backend system and a physical printer. It automatically detects local and network printers, establishes a persistent connection to a server using WebSockets (Pusher), and listens for incoming print jobs (like receipts or invoices). When a new job is received, it formats the ticket and sends it to the selected printer.

## Client Usage

For end-users who just want to use the application:

1.  **Download**: Get the latest release of the application. This will typically be a `.zip` file containing an executable (`.exe`) and other necessary files.
2.  **Extract**: Unzip the downloaded file to a folder on your computer (e.g., `C:\Program Files\PrinterUI`).
3.  **Run**: Double-click the `printer_ui_win.exe` file to start the application.
4.  **Configuration**: On the first run, the application may ask for configuration details, such as a company CUIT, to identify itself with the backend server.
5.  **Select Printer**: The application will display a list of detected local and network printers. Select the printer you want to use for printing tickets.
6.  **Ready**: The application will now run in the background, ready to receive and print jobs automatically. A notification will appear confirming the connection is established.

## Developer Usage

Instructions for developers who want to contribute to or build the project from the source.

### Basic Requirements

- **Flutter SDK**: Version `^3.8.1` or higher. Check with `flutter --version`.
- **IDE**: Visual Studio Code or Android Studio/IntelliJ with the Flutter & Dart plugins.
- **Visual Studio**: For building the Windows application, you need Visual Studio with the "Desktop development with C++" workload installed.
- **Git**: For cloning the repository.

### Run Project in Development

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/palma001/printer.git
    cd printer_ui_win
    ```

2.  **Create Environment File:**
    Create a `.env` file in the root of the `printer_ui_win` project directory. This file is used to configure application settings. Add the following variables:

    ```
    # Font settings for rich text printing on local printers
    RECEIPT_FONT_SIZE=8
    RECEIPT_FONT_NAME=Consolas

    # Paper size for network printers ("58" or "80")
    RECEIPT_PAPER_SIZE=58
    ```

3.  **Install Dependencies:**
    Run the following command to fetch all the required packages.

    ```bash
    flutter pub get
    ```

4.  **Run the App:**
    Make sure you are on a Windows machine. Then, run the app in debug mode.
    ```bash
    flutter run -d windows
    ```

### Build for Windows

1.  **Build the Executable:**
    Run the following command to create a release build for Windows.

    ```bash
    flutter build windows
    ```

2.  **Find the Build Files:**
    The compiled executable and all necessary supporting files will be located in the `build\windows\runner\Release` directory. You can zip this folder and distribute it.

3.  **(Optional) Create an Installer:**
    To create a user-friendly installer (`.msi` or `.exe`), you can use a third-party tool like Inno Setup or NSIS. Point the installer script to the contents of the `build\windows\runner\Release` directory.
