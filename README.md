# P_garbage - Ultra-Optimized Garbage Collector Job Script for QBox/QBCore

P_garbage is a highly optimized FiveM script that adds a garbage collector job to your server. The script utilizes `ox_lib` and `ox_target` to provide enhanced functionality and interaction while maintaining extremely low resource usage (0.00-0.02ms).

## Version 1.0.0 - Latest Updates

- Fixed bin tracking system to properly detect when all bins are empty
- Added improved zone creation logic to prevent premature zone changes
- Enhanced debug capabilities for easier troubleshooting
- Fixed translation issues and added missing locale strings
- Optimized resource usage and memory management
- Added MaxBinsPerZone configuration option for performance control

## Performance Optimizations

This script has been extensively optimized for minimal resource usage:

- Pre-computed hashes and values for faster comparisons
- Efficient data structures with minimal memory footprint
- Proper cleanup of resources to prevent memory leaks
- Optimized event handling with error checking
- Webhook batching to reduce API calls and prevent rate limiting
- Anti-exploit measures to prevent abuse
- Timeout handling to prevent infinite loops
- Proper entity management and cleanup
- Reduced string operations and concatenations
- Optimized loops and iterations
- Cached frequently accessed values
- Minimized network events
- Improved thread management
- Limited number of blips created for better performance

## Features

- Ultra-lightweight garbage collection job (0.00-0.02ms resource usage)
- Interactive targets using `ox_target`
- Job NPC that players interact with to start/end work
- Secure server-side Discord webhook logging with rate limiting
- Seamless integration with `ox_lib` and `ox_inventory`
- Configurable payment system
- Support for multiple languages (English and Finnish included)
- Optional job requirement
- Customizable blip and locations
- Anti-exploit measures
- Optimized for high-population servers
- Multiple garbage collection locations throughout the city
- Vehicle key system options
- Team-based work option with shared payments
- Comprehensive debug system for troubleshooting

## Requirements

- [qb-core](https://github.com/qbcore-framework/qb-core) or [QBox](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory) (optional)

## Installation

1. Download the resource
2. Place it in your server's resources folder
3. Add `ensure P_garbage` to your server.cfg
4. Configure the script in `shared/config.lua` to match your server's needs
5. Set up your Discord webhook URL in `server/webhook.lua`
6. Restart your server or start the resource

## Configuration

The script is highly configurable through the configuration files:

### General Configuration (`shared/config.lua`)
- `Config.Notify` - Choose notification system ('qb', 'ox', or 'other')
- `Config.Progress` - Choose progress bar style ('circle' or 'bar')
- `Config.Language` - Choose language ('en' or 'fi')
- `Config.Inventory` - Choose inventory system ('ox' or 'qb')
- `Config.VehicleKeys` - Choose vehicle key system ('qb' or 'qbx')
- `Config.Debug` - Configure debug options for troubleshooting

### Discord Webhook Configuration (`server/webhook.lua`)
- `WebhookConfig.Enabled` - Enable/disable Discord logging
- `WebhookConfig.URL` - Your Discord webhook URL (securely stored server-side)
- `WebhookConfig.Name` - Name that appears in Discord
- `WebhookConfig.Color` - Default embed color
- `WebhookConfig.Footer` - Footer text for embeds
- `WebhookConfig.IncludeCoordinates` - Include player coordinates in logs
- `WebhookConfig.IncludeIdentifiers` - Include detailed player identifiers

### Job Configuration
- `Config.RequireJob` - Set to true if you want to require a specific job
- `Config.Job` - Job name required if RequireJob is true
- `Config.RentalCost` - Cost to rent the garbage truck

### Payment Configuration
- `Config.PayPerBag` - Amount paid per bag collected
- `Config.MaxBags` - Maximum number of bags that can be collected before payment

### Vehicle Configuration
- `Config.VehicleModel` - Vehicle model to spawn for garbage collection
- `Config.VehicleSpawn` - Location where vehicle spawns

### Location & Blip Configuration
- `Config.JobClock` - Location of the job clock-in/out point
- `Config.Blip` - Blip settings (Show, Sprite, Color, Scale)

### NPC Configuration
- `Config.NPC.Model` - The model of the NPC job boss
- `Config.NPC.Coords` - The position and heading of the NPC
- `Config.NPC.Scenario` - The animation scenario for the NPC

### Zone Creation Configuration
- `Config.AutoCreateNewZone` - Automatically create new zones when all bins are empty
- `Config.BagsPerNewZone` - Used for periodic checks of bin status
- `Config.UseRandomZones` - Choose between random zones or predefined locations
- `Config.MaxBinsPerZone` - Maximum number of bins to create per zone for performance

### Team Work Configuration
- `Config.TeamWork.Enabled` - Enable team work functionality
- `Config.TeamWork.MaxTeamSize` - Maximum number of players in a team
- `Config.TeamWork.PaymentDistribution` - How payment is distributed in a team

### Garbage Locations
- Multiple predefined garbage collection locations throughout the city
- Each location has a center point, radius, and multiple bin coordinates

## Discord Logging

The script includes secure server-side Discord webhook logging with rate limiting for the following events:

- Player clocking in (starting work)
- Player collecting trash bags
- Player depositing trash bags in the garbage truck
- Player clocking out and receiving payment
- Potential exploit detection

Each log includes detailed information:
- Player name and server ID
- Citizen ID
- Current job
- Location coordinates
- Number of bags collected and payment amount (for payment logs)
- Timestamp

## Security Features

- Discord webhook URL is stored directly in the server-side webhook.lua file and never exposed to clients
- All webhook functionality runs exclusively on the server with rate limiting
- Anti-exploit measures to prevent payment abuse
- Secure event handling to prevent unauthorized access
- Input validation to prevent injection attacks
- Payment frequency checks to prevent rapid sequential payments
- Maximum payment validation to prevent unrealistic earnings

## Debug Features

The script includes comprehensive debugging capabilities:

- Enable/disable debug mode in the configuration
- Detailed bin status tracking and logging
- Zone creation debugging
- Bag collection and deposit logging
- Coordinate display for troubleshooting
- Console output for important events

## Usage

1. Go to the garbage job location (marked on the map if enabled)
2. Talk to the job NPC to clock in and start working
3. Collect trash bags from dumpsters around the city
4. Put the trash bags in your garbage truck
5. Once you've collected the maximum number of bags (or when you're done), return to the job NPC and clock out to receive payment

## Team Work

Players can work together in teams:

1. Create a team as a leader
2. Share the team code with friends
3. Team members join using the code
4. The leader starts the job and all members can collect bags
5. When the job is complete, payment is distributed based on the configured ratios

## Support

For support, please open an issue on the GitHub repository or contact the author.

## License

This resource is licensed under the MIT License. See the LICENSE file for details.
