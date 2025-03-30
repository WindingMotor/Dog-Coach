# DogCoach - FRC Team 2106 Match Time Announcer

DogCoach is a Flutter application for FRC that provides match time announcements and before the match robot alignment visualization during FRC competitions.

## Features

- **Match Time Announcements**: Audible announcements at key match times (2:00, 1:00, 0:30, 0:15, and final countdown)
- **NetworkTables Integration**: Connects to the robot via NT4 to receive match time and robot position data
- **Auto Pose Alignment**: Visual display showing robot position relative to target during disabled
- **Customizable Settings**: Adjust server address, volume, and alignment tolerances

## Screenshot


<img src="https://github.com/WindingMotor/Dog-Coach/blob/main/screenshots/main.png" width="250" height="auto">

<img src="https://github.com/WindingMotor/Dog-Coach/blob/main/screenshots/align.png" width="250" height="auto">


## Installation

### Prerequisites

- Flutter SDK 
- Dart SDK 
- Android Studio or VS Code with Flutter extensions

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/WindingMotor/Dog-Coach
   cd dogcoach
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Usage

### Initial Setup

1. Launch the app and tap the settings icon in the top left corner
2. Enter your robot's IP address (default is 10.21.6.2) or localhost for simulation
3. Adjust volume and alignment tolerances as needed
4. Save settings

### Connecting to the Robot

1. Press the "Connect" button to establish a connection to your robot
2. The connection status indicator will turn green when successfully connected
3. Match time will automatically display when received from NetworkTables

### Audio Announcements

The app will automatically announce the following match times:
- 2:00 (match start)
- 1:00 (one minute remaining)
- 0:30 (thirty seconds remaining)
- 0:15 (start of endgame)
- Final countdown (14 seconds to 1 second)

For audio Announcements to work the `coach_audio` folder must be coped to your documents directory!

### Disabled Auto Pose Alignment

During disabled periods, the alignment display will show:
- Current X, Y position relative to target
- Current rotation relative to target
- Visual indicators showing alignment status (green when within tolerance)

## Robot Code Configuration

### NetworkTables Topics

The application subscribes to the following NT4 topics:
- `/SmartDashboard/MatchTime` - Current match time in seconds
- `/SmartDashboard/Disabled` - Boolean indicating if robot is disabled
- `/SmartDashboard/CurrentX` - Current X position of robot
- `/SmartDashboard/CurrentY` - Current Y position of robot
- `/SmartDashboard/CurrentRotation` - Current rotation of robot
- `/SmartDashboard/TargetX` - Target X position
- `/SmartDashboard/TargetY` - Target Y position
- `/SmartDashboard/TargetRotation` - Target rotation

### Audio Files

Place WAV audio files in the `coach_audio` directory in your documents with the following names:
- `120.wav` - 2 minute announcement
- `60.wav` - 1 minute announcement
- `30.wav` - 30 second announcement
- `endgame.wav` - Endgame announcement (plays at 15 seconds)
- `14.wav` through `1.wav` - Countdown announcements

## Building for Release

```bash
flutter build --release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- FRC Team 2106 The Junkyard Dogs
- mjansen4857 for NT4 libary

---
