# Productivity Helper
An application to track one's productivity during work sessions.

## Usage
This application helps you track your productivity during a work session by
pressing buttons depending on what you are doing. To begin your work session,
press the "Start Working" button. You will be prompted to specify the activity
you are working on. You can change the current activity by hitting the
"Change Activity" button. If you go on a break, hit the "Go On Break" button.
Make sure to hit "End Break" when you get back. Finally, if you aren't
officially going on a break but notice yourself getting the urge to slack off,
hit the "Slack Off" button so you can track how much time you waste. When you
are ready to get back to work, hit the button again (which is renamed
"Get Back to Work!" until you do so). The idea is that a break represents a
reasonable interruption of work, such as answering a coworker, taking a phone
call, restroom, etc., whereas slacking off is non-work time that is not spent on
useful activities, such as Facebook, browsing non-work-related sites, etc.

Note: Hitting the "Change Activity" button does not automatically switch you to
that activity, if you are currently in break or slacking off mode!

A timer at the top displays the overall time in the current session, and another
below it displays the contiguous time spent in the current activity, or
break/slacking off (it resets to zero after each state change).

The application logs the time periods that you spend in each activity, or on
break / slacking off, in a text file located at
"~/Documents/Productivity Helper/Statistics.txt". You can view visualizations of
this information by clicking View > Statistics in the top menu
(or Command-Shift-S). You can also open the Statistics.txt file directly from
the File menu, or using the shortcut Command-Shift-O.

The visualization is a HTML file that opens in Google Chrome. The scripts to
load the data and generate the graphics were written in D3.js. Upon launching
the application, a Python HTTP server is launched in the background, to allow
the statistics file to be loaded properly using D3. This server runs on port
8008 in the "~/Documents/Productivity Helper/" directory and is not
automatically killed when the app shuts down. You can access the
visualization at any time the server is running by going to
localhost:8008/Stats.html in your browser (preferably Chrome, as the JavaScript
code is not currently written to be compatible with other browsers). If you
would like to shut down the visualization server for any reason, you may run
the kill\_server.sh script (but please do not do so while the main application
is running).

Note: Feel free to close your computer while the application is running!

## Installation
To download this application on Mac, clone the git directory and open the
.xcodeproj file and build it in XCode (hit the triangular "play" button in the
top left). You can then click and hold the application icon and select
"Keep in Dock", so you do not need to open XCode again. If desired, you can also
set the application to Open at Login (the same way). In the future, this
application will be made available in ready-to-use format, so that users do not
need XCode or have to build it themselves. (Note: This application requires
Mac OS X 10.10 or above, as well as a reasonably up-to-date version of
Google Chrome.)

## Appearance
The user interface is currently fairly barebones. There are plans to improve it,
especially including extensive improvements and additions to the data
visualization!

Screenshot of the main application:  
![Loading application screenshot...](https://raw.githubusercontent.com/nimz/productivity-helper/master/readme-images/main-screenshot.png)

The main application floats on top of other windows, so that the user does not
forget to log their activities. The window may be resized. Some preferences can
be set in the Preferences pane, with more to be added soon.

Screenshot of an example graphic on the data visualization page:  
![Loading visualization screenshot...](https://raw.githubusercontent.com/nimz/productivity-helper/master/readme-images/viz-screenshot.png)

## Suggestions
Comments or suggestions? Add them [here](https://docs.google.com/document/d/1kkbP_bXsXUXItFyJ904AYzuie57umbViFR10OKT3MgM/).

For the moment, please reserve creation of issues to report actual bugs
(although even bugs can also be put in the Google Doc instead).

Enjoy!
