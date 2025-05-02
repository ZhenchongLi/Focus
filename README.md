# Focus - Productivity Timer for macOS

A minimalist productivity timer that uses behavioral psychology principles to help maintain focus.

## Features

- **Variable Ratio Reinforcement**: Random alert sounds between 3-5 minutes create stronger engagement
- **BRAC Cycles**: 90-minute work sessions followed by 20-minute breaks align with natural human ultradian rhythms
- **Attention Reset**: Alert sounds help users regain focus when distracted
- **Simple Interface**: Just Start and Reset buttons - no complex settings

## How It Works

1. Click **Start** to begin a focus session
2. The app will:
   - Play random alert tones every 3-5 minutes (with 10s reminder)
   - After 90 minutes, automatically start a 20-minute break
3. Click **Reset** at any time to stop the current session

## Behavioral Science Principles

This app implements two key psychological concepts:

1. **Variable Ratio Reinforcement (变比率强化)**:
   - Random timing creates stronger engagement than fixed intervals
   - Similar to how slot machines use random rewards

2. **Basic Rest-Activity Cycle (BRAC)**:
   - 90-minute work / 20-minute rest cycles
   - Matches natural human ultradian rhythms for optimal productivity

## Project Benefits

### Scientific Foundations

- **Variable Ratio Reinforcement (变比率强化)**:
  - Random timing (3-5 minutes) creates stronger engagement than fixed intervals
  - Mimics effective behavioral conditioning techniques

- **Basic Rest-Activity Cycle (BRAC)**:
  - 90-minute work / 20-minute rest periods
  - Aligns with natural human ultradian rhythms
  - Optimizes cognitive performance throughout the day

- **Attention Reset (Replay)**:
  - Alert sounds help regain focus when distracted
  - Provides gentle reminders to return to task

### Cognitive Benefits

- Enhanced focus and concentration through timely reminders
- Prevention of mental fatigue via structured breaks
- Improved memory and attention through focus/break cycles
- Increased productivity by working with natural energy rhythms
- Reduced decision fatigue with automatic session management

## Requirements

- macOS 12.0 or later
- Xcode 14+ (for development)

## Installation

1. Clone this repository
2. Open `Focus.xcodeproj` in Xcode
3. Build and run the project

## Packaging

To create a distributable Focus.app bundle:

1. In Xcode, select Product > Archive
2. Wait for the archive to complete
3. In the Organizer window, select your archive
4. Click "Distribute App"
5. Choose "Copy App" as the distribution method
6. Select a destination folder
7. The Focus.app bundle will be created in your chosen location

## Customization

To change the alert sounds:
1. Replace sound files in `Assets.xcassets`
2. Update references in `ContentView.swift`
