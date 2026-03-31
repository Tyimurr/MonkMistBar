# MonkMistBar (v1.2.0)

**MonkMistBar** is a lightweight, high-performance World of Warcraft addon specifically designed for Mistweaver Monks. It provides a highly customizable visual status bar to track **Renewing Mist** charges with pixel-perfect precision and advanced combat reliability.

## IMPORTANT

Development for this addon has ended. All its features have been fully integrated into ArcUI.

Status: No known bugs and fully optimized for all classes.

Note: While the initial setup requires a bit more effort to configure, it performs significantly better and offers much more stability.

Thank you for all your support over the years!

Download ArcUI: https://www.curseforge.com/wow/addons/arc-ui

## Features

- **Advanced Combat Reliability (New in v1.2.0):** Features "Timer Autonomy" logic and a smart API-Sync filter. The bar tracks charges internally during high-combat activity to prevent flickering or incorrect "0 charge" states caused by server lag.
- **Dynamic Tracking:** Automatically detects and displays 2 or 3 charges based on your selected talents (e.g., Dancing Mist).
- **Intelligent Anchoring:** Snap the bar to default Action Bars, the "Essential Cooldown Viewer," or any other UI element using the built-in **Custom Frame Picker**.
- **Auto-Width:** The bar can automatically scale its width to match the size of its anchor frame for a seamless UI look.
- **Dynamic Haste Support:** Timer animations update instantly when your haste changes during procs or Bloodlust.
- **Fully Customizable:** - Change textures, colors, and transparency (LibSharedMedia support).
  - Adjust spacing, borders, and position with precision.
- **General Settings:** Toggleable Debug Mode for troubleshooting and a customizable Login Welcome Message.
- **Performance Optimized:** Built using modern WoW events to ensure zero impact on your FPS even in 20-man mythic raids.

## Installation

1. Download the latest release (v1.2.0).
2. Extract the folder into your WoW directory: `World of Warcraft/_retail_/Interface/AddOns/MonkMistBar`.
3. Start the game and ensure the addon is enabled in your Addon List.

## Usage

Access the settings through the standard Blizzard Options menu (Options -> Addons -> MonkMistBar) or by using the chat command:

`/mmb`

## Credits & Special Thanks

- **Author:** Tyimur
- **Inspiration:** A huge thanks to **Spazhealer** for the display concept and **baremetalxd** for the inspiration to master the Mistweaver class.
- **Libraries:** Powered by LibStub, LibSharedMedia-3.0, and LibSFDropDown.
