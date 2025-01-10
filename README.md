# Chair Barricade Mod for Project Zomboid

## Description
A simple mod that adds the ability to fortify doors by propping chairs against them. When a chair is used to barricade a door, it increases the door's health by 300% and creates a physical barrier that prevents movement through the barricaded side.

## Features
- Use any chair to barricade doors
- Increases door health by 300%
- Creates physical barrier with placed chair
- Door becomes locked from both sides
- Visual feedback with chair prop against door

## Technical Notes
- Due to Project Zomboid's furniture system limitations, all barricade chairs are rendered as the standard wooden chair with green seat (furniture_seating_indoor_01_56-59), regardless of the chair type used
- Interior doors that cannot be locked by default in the base game cannot be barricaded
- Chair placement is determined by player position relative to the door
- Uses IsoThumpable for chair object to ensure proper collision
- Compatible with Build 41+

## Known Issues
- Some interior doors cannot be barricaded due to being "unlockable" in the base game
- Chair sprite is always the same regardless of input chair type
- Currently no way to remove chair barricades (planned for future update)

## Installation
1. Subscribe to the mod on Steam Workshop, or
2. Download and extract the mod to your Project Zomboid mods folder:
