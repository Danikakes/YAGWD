# Yet Another Game WatchDog - Complete Guide
For transparency sake, I used Claude to clean up this code and generate readable documentation because I am not great at that.
## 🎯 What This Does

This system **completely automates** the monitor build process:
- ✅ Auto-encrypts your Dropbox token
- ✅ Auto-injects all your settings
- ✅ Auto-builds the EXE
- ✅ Ready to distribute immediately

**No manual editing of script files needed!**

---

## 🚀 Quick Start (3 Steps)

### Step 1: Edit build-config.ini

Open `build-config.ini` in Notepad and fill in:

```ini
# Your game/app name
AppName=MyAwesomeGame

# Path to your game exe (relative to where monitor will be)
ExePath=MyGame.exe

# Your Dropbox access token (will be encrypted automatically)
DropboxAccessToken=sl.B1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0
```

### Step 2: Run the Build

```cmd
auto-build.bat
```

That's it! The script will:
1. ✓ Read your config
2. ✓ Encrypt your Dropbox token
3. ✓ Generate the monitor script
4. ✓ Convert to EXE
5. ✓ Give you `monitor-app.exe`

### Step 3: Distribute

Put `monitor-app.exe` in the same folder as your game and ship it!

---

## 📝 Detailed Configuration

### build-config.ini Reference

```ini
# ============================================================
# APPLICATION SETTINGS
# ============================================================

# The name shown in the monitor window
AppName=MyGame

# Path to exe (relative to monitor location)
# Examples:
#   MyGame.exe          (same folder)
#   bin/MyGame.exe      (game in subfolder)
#   ../MyGame.exe       (monitor in subfolder)
ExePath=MyGame.exe

# Where to save logs (optional, default is ./logs)
LogDirectory=

# ============================================================
# DROPBOX SETTINGS
# ============================================================

# Your Dropbox access token
# Get from: https://www.dropbox.com/developers/apps
# This will be ENCRYPTED before being embedded
DropboxAccessToken=sl.your_token_here

# ============================================================
# CRASH REPORTING SETTINGS
# ============================================================

# Seconds to wait after crash for final logs (default: 3)
CrashWaitSeconds=3

# Show log file location after crash (default: true)
ShowLogLocation=true

# ============================================================
# BUILD SETTINGS
# ============================================================

# Output filename (default: monitor-app.exe)
OutputExeName=monitor-app.exe

# Path to icon file (.ico format)
# Leave empty for default Windows icon
# Example: icon.ico, assets/icon.ico
IconFile=

# EXE metadata
CompanyName=YourCompany
ProductName=Game Monitor
CopyrightYear=2024
Version=2.0.0.0
```

---

## 🎮 Example Configurations

### Example 1: Simple Same-Folder Setup

```ini
AppName=SpaceShooter
ExePath=SpaceShooter.exe
DropboxAccessToken=sl.B1a2b3c4...
QuietTimeoutSeconds=2
```

**Result:** Monitor looks for `SpaceShooter.exe` in the same folder.

### Example 2: Game in Subfolder

```ini
AppName=RPGGame
ExePath=bin/RPGGame.exe
DropboxAccessToken=sl.B1a2b3c4...
```

**Result:** Monitor looks for game at `bin/RPGGame.exe` relative to monitor location.

### Example 3: Custom Everything

```ini
AppName=MyMMO
ExePath=MyMMO.exe
LogDirectory=game_logs
DropboxAccessToken=sl.B1a2b3c4...
QuietTimeoutSeconds=3
ShowLogLocation=true
OutputExeName=MyMMO-Monitor.exe
IconFile=mmo-icon.ico
CompanyName=AwesomeGames Studio
ProductName=MyMMO Crash Reporter
CopyrightYear=2024
Version=1.5.0.0
```

---

## 🔒 Security Features

### What Gets Encrypted
- ✅ Dropbox token is encrypted with AES-256
- ✅ Encryption happens automatically during build
- ✅ Token is never stored in plain text in the EXE

### What to Keep Private
**DO distribute:**
- ✅ `monitor-app.exe` (or your custom name)

**DO NOT distribute:**
- ❌ `build-config.ini` (contains unencrypted token!)
- ❌ `monitor-template.ps1`
- ❌ `build-monitor.ps1`
- ❌ `monitor-app-generated.ps1`
- ❌ Any `.ps1` or `.ini` files

---

## 🧪 Testing

After building:

```cmd
# Test with the included test app
monitor-app.exe

# The monitor will:
# 1. Look for your game at the configured ExePath
# 2. Launch it
# 3. Monitor for crashes
# 4. Upload crash reports if user agrees
```

### Test Without Your Game

Create a simple test file called `MyGame.exe.bat`:

```batch
@echo off
echo Game is running...
timeout /t 5 /nobreak >nul
echo Game crashed!
exit /b 1
```

Rename it to match your `ExePath` setting, then run the monitor.

---

## 💡 Advanced Features

### Crash Quiet Detection

The monitor intelligently waits for the console to become quiet after a crash:

```ini
QuietTimeoutSeconds=2   # Wait until 2 seconds of silence (default)
QuietTimeoutSeconds=1   # More aggressive (1 second)
QuietTimeoutSeconds=5   # Very patient (5 seconds)
```

**How it works:**
- After the app crashes, the monitor keeps watching console output
- When no output has been received for X seconds, it captures the crash report
- Maximum wait time: 30 seconds (prevents hanging forever)

**Recommended:** 2-3 seconds works for most applications.

### Why This Is Better Than Fixed Delays

```
❌ Old way: Wait 5 seconds (might be too long or too short)
✅ New way: Wait until app is actually done logging

Example timeline:
00:00 - App crashes
00:01 - Still writing error logs...
00:03 - Last log written
00:05 - 2 seconds of silence detected → Capture crash report!
```

### Log Directory

```ini
LogDirectory=           # Uses ./logs (default)
LogDirectory=logs       # Same as default
LogDirectory=C:/logs    # Absolute path
LogDirectory=../logs    # Relative path
```

### Custom Output Name

```ini
OutputExeName=monitor-app.exe          # Default
OutputExeName=MyGame-CrashReporter.exe # Custom name
```

### Custom Icon

```ini
IconFile=                # No icon (default Windows icon)
IconFile=icon.ico        # Icon in same folder
IconFile=assets/icon.ico # Icon in subfolder
```

**Icon Requirements:**
- Must be `.ico` format (not PNG/JPG!)
- Recommended: 256x256 pixels or multi-size
- See `ICON-GUIDE.md` for detailed instructions

---

## 🔧 Troubleshooting

### "Config file not found"
→ Make sure `build-config.ini` is in the same folder as `auto-build.bat`

### "Missing required fields"
→ You must fill in at least: `AppName`, `ExePath`, and `DropboxAccessToken`

### "Failed to encrypt token"
→ Check that your Dropbox token is valid (starts with `sl.`)

### "PS2EXE not found"
→ The script will auto-install it, but you need internet connection

### Monitor can't find game
→ Check the `ExePath` in your config - it's relative to where the monitor is

### Still getting 400 errors
→ The template includes the fix - if you still get errors, your Dropbox token might be expired

---

## 📊 Build Output Example

```
[1/6] Reading build configuration...
  ✓ App Name: SpaceShooter
  ✓ Exe Path: SpaceShooter.exe
  ✓ Dropbox Token: Provided

[2/6] Validating configuration...
  ✓ All required fields present

[3/6] Encrypting Dropbox token...
  ✓ Token encrypted successfully

[4/6] Generating monitor script...
  ✓ Script generated: monitor-app-generated.ps1

[5/6] Checking for PS2EXE module...
  ✓ PS2EXE already installed

[6/6] Converting to EXE...
  ✓ Conversion successful

============================================================
BUILD SUCCESSFUL!
============================================================

Output file: monitor-app.exe
File size: 847 KB

Configuration Summary:
  App Name: SpaceShooter
  Monitored EXE: SpaceShooter.exe
  Log Directory: .\logs
  Quiet Timeout: 2 seconds (waits for console silence)
  Dropbox: Enabled (Encrypted)

Next Steps:
  1. Test the EXE: .\monitor-app.exe
  2. Distribute monitor-app.exe with your game
  3. Place it in the same directory as SpaceShooter.exe
```

---

## 🎯 Steam Distribution Workflow

### 1. Build Phase (You)
```
1. Edit build-config.ini
2. Run auto-build.bat
3. Get monitor-app.exe
```

### 2. Integration (You)
```
YourGame/
├── MyGame.exe
├── monitor-app.exe    ← Include this
├── data/
└── ...
```

### 3. User Experience (Players)
```
Option A: Double-click monitor-app.exe
  → Launches and monitors MyGame.exe
  → Asks to submit if crash occurs

Option B: Still works with direct launch
  → Player can still run MyGame.exe directly
  → No monitoring, but game still works
```

### 4. You Receive
```
Dropbox/crash_reports/
├── MyGame_crash_2024-02-13_14-30-45.txt
├── MyGame_crash_2024-02-13_15-22-11.txt
└── ...
```

---

## 🔄 Updating for New Versions

When you need to update (new token, different settings):

```
1. Edit build-config.ini
2. Run auto-build.bat
3. Distribute new monitor-app.exe via Steam update
```

**That's it!** No manual script editing needed.

---

## 📦 Complete File List

**Files you work with:**
- `build-config.ini` - Your settings (edit this)
- `auto-build.bat` - Run this to build
- `monitor-app.exe` - Distribute this

**Files in the package (don't edit):**
- `build-monitor.ps1` - Build automation script
- `monitor-template.ps1` - Template for generated monitor
- `test-crash-app.bat` - For testing

**Files to keep private:**
- `build-config.ini` - Has your unencrypted token!
- All `.ps1` files - Source code

---

## ✅ Final Checklist

Before Steam release:

- [ ] Generated Dropbox token with `files.content.write` permission
- [ ] Filled out `build-config.ini` completely
- [ ] Ran `auto-build.bat` successfully
- [ ] Tested `monitor-app.exe` works
- [ ] Verified crash reports upload to Dropbox
- [ ] Placed monitor in correct location relative to game
- [ ] Removed `build-config.ini` from Steam build
- [ ] Removed all `.ps1` files from Steam build
- [ ] Tested on a clean machine
- [ ] Added privacy notice to Steam page

---

**This is the easiest way to get a professional crash reporter for Steam!**
