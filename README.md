# SR Player
This app is an experiment utilizing the open API of SR and testing the AVPlayer. The project's goal is to list the available channels from SR in a view and play each channel individually from a detailed view. Additionally, it aims to implement a shared player on the list view for selected streams. The player should also support background playback and be controllable from the lock screen.

## Design
I chose to use native SwiftUI views exclusively, adhering to the default SwiftUI design. Instead of incorporating custom design elements, I decided to utilize only the colors and images provided by the API.

## Code optimization
I have formatted the code using the `SwiftFormat XCode extension`.

## App Architecture
The app follows the MVVM pattern, featuring a channel list view and a channel detail view. Both views implement an instance of MediaPlayerView, which provides the media player functionality.
The app includes two services:
- SRService: Provides data from the API.
- AudioService: Manages the audio player.

## Testing
Due to time constraints on this project, I decided to focus only to test ChannelListViewModel and the services.

## Finding
The simulator appears to have a bug that prevents remote controls from appearing on the lock screen. To test the app's behavior on the lock screen, you need to run it on a physical device.

Hope you like it!
