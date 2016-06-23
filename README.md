## Building

### Requirements

* Xcode 7.3.1
* Cocoapods 1.0.1

```bash
cd path/to/HappyCow
pod install
open HappyCow.xcworkspace
```

The build & run normally.

## Notes

- The app is using currencylayer.com instead of jsonrates.com since the latter does not work and is not maintained anymore.
- For the sake of 1-click running, even though it is not a good practice, I included the pods in the repository.
- The latest version of RestKit (0.26.0, Nov 13, 2015) seems to suffer from an incompatibility with AFNetwork and/or Cocoapods 1.0.1. The temporary workaround described in this thread has been adopted: https://github.com/RestKit/RestKit/issues/2356#issuecomment-223503376 (the only minor difference is that I forked those branches to make sure they remain unchanged and therefore the project is guaranteed to compile).
