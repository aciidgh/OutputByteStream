import PackageDescription

let package = Package(
    name: "OutputByteStream",
    targets: [
        Target(name: "Basic", dependencies: ["POSIX"]),
        Target(name: "POSIX", dependencies: ["libc"]),
    ]
)
