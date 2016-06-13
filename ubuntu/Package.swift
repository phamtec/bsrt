
import PackageDescription

let package = Package(
    name: "YourSocketIOProject",
    dependencies: [
        .Package(url: "https://github.com/socketio/socket.io-client-swift", majorVersion: 6)
    ]
)
