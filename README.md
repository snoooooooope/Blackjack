# Blackjack

Notifications for combat events you should probably know about.

What originally started as a rewrite to the original SpellNotifications by Veev morphed into this dual SpellNotification / SpellAlerter monstrosity I have now.

## Features

- **Interrupt Tracking**: Visual and audio notifications when you interrupt enemy spells

- **Dispel & Purge Tracking**: Alerts for successful dispels/purges with spell information

- **Customizable Alerts**: 
  - Adjustable font, size, & sound effects
  - Icon configuration
  - Configurable alert duration
  - Position alerts anywhere

- **Configurable Filters**: 
  - Enable/disable specific spell tracking per class
  - Custom text and sound per spell
  - Whitelist/blacklist support


## Commands

- `/bj config` - Open configuration panel
- `/bj debug` - Toggle debug messages
- `/bj test` - Test visual and sound alerts

## Requirements

- ***[!!!ClassicAPI](https://gitlab.com/Tsoukie/classicapi/-/tree/main?ref_type=heads)*** (eventually will be removed once I add proper fallbacks)

## Credits

- [Tsoukie](https://gitlab.com/Tsoukie) ClassicAPI is a lifesaver
- [Veev](https://www.twitch.tv/veev) Original SpellNotifications addon
- [SoundAlerter maintainers](https://github.com/Cortes-Jeremy/SoundAlerter)
