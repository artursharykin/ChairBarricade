# Chair Barricade Mod for Project Zomboid

![Steam Subscribers](https://img.shields.io/steam/subscriptions/3404288341?style=for-the-badge&color=blue&logo=steam&label=Workshop%20Subs) ![Steam Favorites](https://img.shields.io/steam/favorites/3404288341?style=for-the-badge&color=blue&logo=steam&label=Favorites)

## Description
A simple mod that adds the ability to fortify doors by propping chairs against them. When a chair is used to barricade a door, it increases the door's health by an adjustable amount and creates a physical barrier that prevents movement through the barricaded side.

## Features
- Use any chair to barricade doors
- Increases door health by an adjustable amount
- Select door health multiplier in Sandbox settings
- Creates physical barrier with placed chair
- Door becomes locked from both sides
- Visual feedback with chair prop against door

## Technical Notes
- The mod now uses the actual chair sprite you picked up, preserving the visual appearance of your barricade
- All doors can now be barricaded and locked, including interior doors
- Chair placement is determined by player position relative to the door
- Uses IsoThumpable for chair object to ensure proper collision
- When removing a barricade, you get back the exact chair type you used
- Compatible with Build 41 & 42

## Recent Updates (v1.2.0)
- **Fixed**: Resolved Build 42 crash issues with improved null safety checks
- **Added**: Support for player-crafted chairs and furniture items
- **Fixed**: Enhanced sprite handling with safe fallbacks to prevent crashes
- **Improved**: Better chair detection that works with all chair types including custom/modded ones

## Previous Updates (v1.1.0)
- **Fixed**: All doors can now be closed and locked, including previously "unlockable" interior doors
- **Fixed**: Chairs now display with their actual appearance instead of always being green wooden chairs
- **Fixed**: Removing a barricade now returns the correct chair type to your inventory
- **Improved**: Enhanced door locking logic to work with all door types in the game

## Installation
1. Subscribe to the mod on Steam Workshop, or
2. Download and extract the mod to your Project Zomboid mods folder
