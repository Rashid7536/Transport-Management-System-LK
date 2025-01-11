# Leaflet - TMS

A comprehensive Flutter application that provides a user-friendly and efficient solution for managing transportation networks, including bus stands, routes, and real-time bus information. The system offers features such as real-time bus tracking, route calculation using Dijkstra's algorithm, secure bus registration, and cross-platform compatibility. This Transportation Management System aims to enhance the commuting experience for users and streamline the management of transportation resources for bus owners and authorities.

# Transportation Management System

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Introduction
This repository contains the source code for a Transportation Management System (TMS) developed using Flutter. The system aims to provide a comprehensive solution for managing transportation networks, including bus stands, routes, and real-time bus information.

## Features
- Real-time bus tracking and information
- Efficient route calculation using Dijkstra's algorithm
- User-friendly interface for commuters and bus owners
- Secure bus registration and management system for bus owners
- Cross-platform compatibility

## Getting Started

## Installation
1. Clone the repository:
git clone https://github.com/rashid7536/Transport-Management-System-LK.git

2. Install the required dependencies:
You can check the pubspec.yaml for dependencies

3. Set up the backend API if required.
This project was running on firebase, in order to deploy on your device, you will need to create a firebase database structure as follows and link your firebase account with the flutter app, this will require the flutterfire-cli through node

4. Run the project
use flutter run to run either on Web or on Android, most libraries doesnt work with Web, with Android its perfectly compatible.

5. Additional Data to run
- You can change bus routes by editing the files in assets/geoJson, those take geoJson data and plot on the map
- If you want to use the Shortest Path Algorithm, you will need to run a seperate python script in the background to calculate the queries added into the database, else the progressive bar will close after 60s of checking data in the database as a timeout exception.

## Usage
1. Open the project in Android Studio or your preferred IDE (VSCODE is better).
2. Run the app on a compatible device or emulator.
3. Link firebase realtime database to the app
4. Explore the features and functionalities of the app.

## Contributing
Contributions to the project are welcome. Please follow the standard contribution guidelines and open a pull request with your changes.

## License
This project is licensed under the [MIT License](LICENSE).

## Contact
If you have any questions or suggestions, please contact:
- Rashid Aman <Rashidaman05@gmail.com> - Sole Author of the App
- Asel Wickramathialke - Crowd Counting, implemented Seperately
- Pasan Senarath - Hardware 
