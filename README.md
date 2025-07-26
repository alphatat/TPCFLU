TPCFLU - Universal Pomodoro Timer

A distraction-free Pomodoro timer built with Flutter, supporting Android, iOS, web, and desktop platforms. This is a rewrite of the TPC.10min app, maintaining its core philosophy of simplicity and focus.

Features





Distraction-Free: No status bar, navigation bar, numbers, or letters—just visual and acoustic feedback.



Pomodoro Cycle: Alternates between 25-minute work sessions and 5-minute breaks, running continuously until the app is closed.



Cross-Platform: Works on Android, iOS, web, and desktop.



Sound Feedback: Plays a sound at the start of each work or break session.



No Pause Option: Designed to keep you focused without interruptions.

Usage





Launch the app and press the large red button to start the timer.



The timer screen shows a circular progress indicator:





Bright red for work sessions (25 minutes).



Bright green for break sessions (5 minutes).



Dimmed sections indicate elapsed or upcoming time.



A sound plays when a new session begins.



Close the app to stop the timer (no pause functionality by design).

Setup Instructions





Clone the Repository:

git clone https://github.com/alphatat/TPCFLU.git
cd TPCFLU



Install Dependencies:

flutter pub get



Add Sound Asset:





Place a tick.mp3 file in the assets/sounds/ directory. You can use any short sound file (e.g., a tick or chime).



Ensure the file is referenced in pubspec.yaml under assets.



Run the App:

flutter run

To build for specific platforms:





Web: flutter run -d chrome



Desktop: flutter run -d windows (or macos, linux)



Mobile: Connect a device or emulator and run flutter run

Dependencies





Flutter - UI toolkit for cross-platform development.



just_audio - For cross-platform sound playback.

License

This project is licensed under the GNU General Public License (GPL). See the LICENSE file for details.

Created with ❤️ by alphatat