# GitHub Copilot Instructions for FixPlayerEquip

## Repository Overview

This repository contains a SourceMod plugin for Counter-Strike (CS:GO/CS2) that optimizes the performance of `game_player_equip` entities by preventing lag when giving equipment and ammunition to players. The plugin intercepts equipment distribution and uses more efficient methods to stock player ammunition and armor.

### Core Functionality
- Hooks `game_player_equip` entity usage events
- Optimizes ammo distribution using direct SDK calls to `CCSPlayer::StockPlayerAmmo`
- Handles armor items (kevlar, assault suit) through direct property setting
- Prevents redundant ammo stocking operations

## Technical Environment

### Language & Platform
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11.0+ (supports both CS:GO and CS2)
- **Compiler**: SourcePawn Compiler (spcomp) via SourceKnight build system
- **Target Games**: Counter-Strike: Global Offensive, Counter-Strike 2

### Build System
- **Primary Build Tool**: SourceKnight (configured in `sourceknight.yaml`)
- **Build Command**: Uses GitHub Actions with `maxime1907/action-sourceknight@v1`
- **Output Directory**: `/addons/sourcemod/plugins` (compiled .smx files)
- **Dependencies**: Automatically downloaded SourceMod 1.11.0-git6917

### Project Structure
```
/addons/sourcemod/
├── scripting/
│   └── FixPlayerEquip.sp          # Main plugin source
├── gamedata/
│   └── FixPlayerEquip.games.txt   # Game signatures for SDK calls
└── plugins/                       # Compiled output (generated)
    └── FixPlayerEquip.smx
```

## Code Standards & Conventions

### SourcePawn Best Practices
- **Always use**: `#pragma semicolon 1` and `#pragma newdecls required`
- **Indentation**: Use tabs (4 spaces equivalent)
- **Variable Naming**:
  - Global variables: `g_` prefix (e.g., `g_hCCSPlayer_StockPlayerAmmo`)
  - Local variables: camelCase (e.g., `bGaveAmmo`, `iWeapon`)
  - Functions: PascalCase (e.g., `StockPlayerAmmo`, `OnEntityCreated`)
- **Memory Management**: Use `delete` instead of `CloseHandle()` for newer SourceMod versions
- **String Operations**: Use `StrEqual()` for exact matches, `strncmp()` for prefix matching

### Plugin Structure Requirements
```sourcepawn
// Required pragmas at top
#pragma semicolon 1
#pragma newdecls required

// Standard includes for CS plugins
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

// Global variables with g_ prefix
Handle g_hSomeSDKCall;

// Plugin info block
public Plugin myinfo = {
    name = "PluginName",
    author = "AuthorName", 
    description = "Description",
    version = "1.0.0"
}

// Required callbacks
public void OnPluginStart() { }
public void OnEntityCreated(int entity, const char[] classname) { }
```

### SDK Integration Patterns
- **GameData Loading**: Always check for `INVALID_HANDLE` and use `SetFailState()` on failure
- **SDK Call Preparation**: Use proper parameter types (`SDKType_CBaseEntity`, `SDKPass_Pointer`)
- **Entity Validation**: Check entity validity with `INVALID_ENT_REFERENCE`
- **Client Validation**: Validate client indices (`client > MaxClients || client <= 0`)

## Plugin-Specific Architecture

### Core Components

1. **SDK Call Setup** (`OnPluginStart`)
   - Loads gamedata from `FixPlayerEquip.games.txt`
   - Prepares `CCSPlayer::StockPlayerAmmo` SDK call
   - Handles late loading of existing entities

2. **Entity Hooking** (`OnEntityCreated`)
   - Automatically hooks new `game_player_equip` entities
   - Uses `SDKHook_Use` to intercept usage events

3. **Equipment Distribution** (`OnUse`)
   - Optimized loop through equipment items
   - Special handling for ammo, kevlar, and assault suit
   - Prevents redundant ammo operations with `bGaveAmmo` flag

### Performance Optimizations
- **Static Variables**: Uses `static int s_MaxEquip = -1` for one-time array size calculation
- **Ammo Batching**: Groups all ammo operations to prevent multiple SDK calls
- **Early Returns**: Validates clients before processing equipment

## Development Workflow

### Building the Plugin
```bash
# Build using SourceKnight (automated in CI)
sourceknight build

# Manual compilation (if needed)
spcomp -i"path/to/include" FixPlayerEquip.sp
```

### Testing Checklist
- [ ] Plugin compiles without warnings
- [ ] No memory leaks (check with SourceMod profiler)
- [ ] Handles invalid entities gracefully
- [ ] Works with late loading (server restart)
- [ ] Performance impact minimal (test with multiple `game_player_equip` entities)

### Common Modification Patterns

#### Adding New Equipment Types
```sourcepawn
// In OnUse() function, add new else-if block
else if(StrEqual(sWeapon, "item_newtype", false))
{
    // Handle new equipment type
    SetEntProp(client, Prop_Send, "m_propertyName", value);
}
```

#### Adding SDK Calls
```sourcepawn
// In OnPluginStart(), after existing SDK setup
StartPrepSDKCall(SDKCall_Player);
if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NewFunction"))
{
    // Handle error
}
// Configure parameters and store handle
```

#### Entity Hook Extensions
```sourcepawn
// In OnEntityCreated(), add new entity types
if(StrEqual(classname, "new_entity_type"))
{
    SDKHook(entity, SDKHook_SomeEvent, SomeCallback);
}
```

## Error Handling & Debugging

### Required Error Checks
- **GameData Loading**: Always validate gamedata file loading
- **SDK Call Preparation**: Check each PrepSDKCall step
- **Entity Operations**: Validate entity references before use
- **Client Operations**: Verify client indices and connection status

### Common Issues & Solutions
- **"PrepSDKCall_SetFromConf failed"**: Check gamedata signatures match game version
- **Entity not found**: Verify entity classname spelling and game compatibility  
- **Client errors**: Add proper client validation (`IsClientInGame()`, index bounds)
- **Memory leaks**: Use `delete` instead of `CloseHandle()` for modern SourceMod

### Debugging Tools
- **Console Commands**: Use `sm_dump_classes` to verify entity classnames
- **GameData Debugging**: Check SourceMod error logs for signature failures
- **Performance Profiling**: Use SourceMod's built-in profiler for optimization

## CI/CD Integration

### Automated Build Process
- **Trigger**: Push to any branch, pull requests, manual dispatch
- **Build Matrix**: Ubuntu 24.04 (primary target)
- **Artifact Output**: Compiled plugin + gamedata in package structure
- **Release**: Automatic releases for tagged versions and main branch

### Release Management
- **Versioning**: Update version in plugin info block
- **Tagging**: Use semantic versioning (e.g., `v1.0.1`)
- **Package Contents**: Includes compiled `.smx` file and gamedata

## Dependencies & Compatibility

### SourceMod Version Requirements
- **Minimum**: SourceMod 1.11.0
- **Recommended**: Latest stable release
- **Include Files**: sourcemod, sdktools, sdkhooks, cstrike

### Game Compatibility
- **Counter-Strike: Global Offensive**: Full support
- **Counter-Strike 2**: Full support (signatures updated for CS2)
- **Other Source Games**: Not applicable (CS-specific functionality)

### Extension Dependencies
- **SDKTools**: Required for entity manipulation
- **SDKHooks**: Required for entity event hooking
- **CStrike**: Required for CS-specific constants and functions

## Security & Best Practices

### Input Validation
- Always validate client indices and entity references
- Check string lengths before operations
- Verify entity classnames match expected values

### Memory Management
- Use `delete` for handle cleanup in modern SourceMod
- Avoid memory leaks in loops and error paths
- Cache expensive operations (like array size calculations)

### Performance Considerations
- Minimize operations in frequently called functions (like `OnUse`)
- Use static variables for one-time calculations
- Batch similar operations to reduce SDK call overhead
- Consider the impact on server tick rate

## Contribution Guidelines

### Code Review Focus Areas
- [ ] Proper error handling for all SDK operations
- [ ] Memory management follows modern SourceMod practices
- [ ] Performance impact assessment
- [ ] Compatibility with existing functionality
- [ ] Code style consistency with existing codebase

### Testing Requirements
- Test on both CS:GO and CS2 (if applicable)
- Verify no performance regression
- Test edge cases (invalid entities, disconnected clients)
- Confirm gamedata signatures work across game updates

This plugin is critical for server performance optimization, so changes should be thoroughly tested and reviewed for both correctness and performance impact.