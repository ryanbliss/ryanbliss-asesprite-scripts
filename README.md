
## Ryan's Asesprite scripts

To use, copy the script(s) you want to use into your Asesprite scripts folder. For more information, view [here](https://community.aseprite.org/t/aseprite-scripts-collection/3599).

### layer toggle visibility

[layer-toggle-visibility.lua](layer-toggle-visibility.lua) looks for common layer / group names and allows you to toggle the visibility of all at once. Useful if you have common frame animations for things like `body -> idle -> up`, `arm -> idle -> up`, etc.

### layer replace

[layer-replace-with-lookup-map.lua](layer-replace-with-lookup-map.lua) is designed for use with [aarthificial's pixel art animation strategy](https://www.youtube.com/watch?v=nYch_TIkq6w&t=435s). It automates replacing each pixel with a unique color value.

Credit to [christopherwk210](https://github.com/christopherwk210), whose [color-overlay.lua](https://github.com/christopherwk210/aseprite-scripts/blob/master/image/color-overlay.lua) script served as the foundation for `layer-replace-with-lookup-map`.

### export spritesheets

[export-spritesheets.lua](export-spritesheets.lua) is a modified version of [PKGaspi's](https://github.com/PKGaspi/AsepriteScripts) script. These are just so I can override some defaults for my project (e.g., I always want to create a spritesheet).
