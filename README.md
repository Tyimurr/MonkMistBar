# MonkMistBar

**MonkMistBar** is a lightweight and highly customizable World of Warcraft addon specifically designed for Mistweaver Monks. it provides a clean, visual status bar to track the charges of **Renewing Mist** with precision.

## Features

- **Dynamic Tracking:** Automatically detects and displays 2 or 3 charges based on your selected talents.
- **Intelligent Anchoring:** Snap the bar to default Action Bars, the "Essential Cooldown Viewer," or any other UI element using the built-in **Custom Frame Picker**.
- **Auto-Width:** The bar can automatically scale its width to match the size of its anchor frame for a seamless UI look.
- **Fully Customizable:** - Change textures, colors, and transparency (LibSharedMedia support).
  - Adjust spacing, borders, and position with pixel-perfect accuracy.
- **Performance Optimized:** Built using modern WoW events instead of heavy API polling in the `OnUpdate` loop to ensure zero impact on your FPS.
- **Modern UI:** Integrates perfectly into the standard Blizzard Options panel.

## Installation

1. Download the latest release.
2. Extract the folder into your WoW directory: `World of Warcraft/_retail_/Interface/AddOns/`.
3. Start the game and ensure the addon is enabled in your Addon List.

## Usage

You can access the settings through the standard Blizzard Options menu (Options -> Addons -> MonkMistBar) or by using the chat command:

`/mmb`

## Credits & Special Thanks

- **Author:** Tyimur
- **Inspiration:** A huge thanks to **Spazhealer** for the display concept and **baremetalxd** for the inspiration to master the Mistweaver class.
- **Libraries:** Powered by LibStub, LibSharedMedia-3.0, and LibSFDropDown.
