![NVMKeychain_header](https://github.com/NVMNovem/NVMKeychain_swift/assets/44820440/edf93258-f496-48c7-88e6-55fc4af53fa5)


<h3 align="center">iOS · macOS · watchOS · tvOS</h3>

---

A pure Swift library that allows you to easily access the keychain.

This project is created and maintained by Novem.

---

- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

You can use The Swift Package Manager (SPM) to install NVMKeychain by adding the following description to your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/NVMNovem/NVMKeychain_swift", from: "1.0.0"),
    ]
)
```
Then run `swift build`. 

You can also install using SPM in your Xcode project by going to 
"Project->NameOfYourProject->Swift Packages" and placing "https://github.com/NVMNovem/NVMKeychain_swift" in the 
search field. Then select the option that is most suited for your needs.
