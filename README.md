# hori-mini-wired-gamepad-remote-play

Spoof OSX version of PS4 Remote play into thinking that the Hori Mini Wired Gamepad is a Dualshock 4 controller.

## Building

### Prerequisites

You need to have the official PS4 Remote play, and XCode Command Line Tools installed.  [Instructions here](http://railsapps.github.io/xcode-command-line-tools.html)

### Installing

```
git clone https://github.com/sperrichon/hori-mini-wired-gamepad-remote-play
cd hori-mini-wired-gamepad-remote-play
./build/compile-lib.sh # out/iohid_wrap.dylib created
```

### Testing

If everything went well, run this script to test Remote Play:

```
./build/run.sh
```

**Note**: The script assumes Remote play is installed at `/Applications/RemotePlay.app`. If this is not the case, you'll need to modify run.sh accordingly. 

### Creating wrapper

Once compiled, you can create a wrapper which makes running Remote Play more comfortable

```
./build/make-wrapper.sh # out/RemotePlayWrapper.app created
```

The wrapper searches for RemotePlay.app first in its own `Contents/Resources` folder, and fallbacks to `/Applications`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

* Inspiration, and parts of the code directly comes from [ShockEmu](https://github.com/daeken/ShockEmu) which allows using Remote Play with keyboard+mouse

* How to override library functions on OSX: [http://tlrobinson.net/blog/2007/12/overriding-library-functions-in-mac-os-x-the-easy-way-dyld_insert_libraries/](http://tlrobinson.net/blog/2007/12/overriding-library-functions-in-mac-os-x-the-easy-way-dyld_insert_libraries/)