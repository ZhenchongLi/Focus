# Refactor timer into a testable TimerModel + fix About/Help/version bugs

## Current state

The whole timer is one SwiftUI view. `ContentView` holds the timer state as
`@State` (`isRunning`, `isWorking`, `elapsedTime`, `workTime`, `breakTime`), runs
a `Timer` in `toggleTimer()`, and inside that timer's tick it checks for phase
transitions, plays sounds, sends notifications, and pushes the menu-bar title
into `AppDelegate`. None of this can be unit-tested without a run loop, an audio
device, and the notification center.

The sound is synthesized inline in `playAlertSound(type:)`. It builds a sine-wave
buffer and starts the engine with `try? engine.start()` on line 124, so if the
engine fails to start the app plays nothing and reports nothing. There is no way
to tell from outside whether the engine is alive.

There are also several smaller defects:

- `FocusApp.swift` declares `CommandGroup(replacing: .newItem) {}` and nothing
  else, so the menu has no About item and no Help item. `AppDelegate.showAboutWindow()`
  and `AppDelegate.openHelpWebsite()` exist but nobody calls them.
- `AboutView.swift:14` hardcodes `Text("Version 1.0.1")`. The real marketing
  version is `1.0.2`, so the About box is already wrong.
- `FocusApp.version = "1.0.2"` is a second hardcoded copy of the version that
  nothing reads. It can drift from `MARKETING_VERSION` the next time the version
  bumps.
- Three comments in `ContentView` describe test values that the code does not
  use. Line 18 says `90*60` is "30秒测试用", line 19 says the same for `20*60`,
  and line 238 says the `180...300` random interval is "测试用15秒间隔". The
  numbers are the real production numbers. Only the comments lie.

`FocusTests` is the Xcode stub with one empty `example()` test.

The Help URL `https://fists.cc/posts/products/focus/` is written out twice today:
once in `AppDelegate.openHelpWebsite()` and once in the `AboutView` Help button.

## Approach

Pull the timer's logic out of the view into a `TimerModel` that is an
`ObservableObject`, and pull the sound synthesis into a `SoundPlayer`. The view
keeps the layout and the buttons but drives everything through the model. The
two pieces a test can't reach (audio output, notification delivery) become
injected side effects, so the model can be driven in a test with fakes that just
record what was asked of them.

Durations, frequencies, harmonics, the envelope, and the notification text all
move verbatim. Nothing about the audible or visible behavior changes. The
refactor is the point; the numbers are frozen.

### TimerModel

Holds the same state the view holds today: `isRunning`, `isWorking`,
`elapsedTime`, `workTime` (`90*60`), `breakTime` (`20*60`). It owns the tick
logic that today lives in the `Timer` closure. The actual `Timer` scheduling can
stay, but the per-tick decision (advance time, detect a phase boundary, switch
phase, reset `elapsedTime`, fire side effects) becomes a plain method a test can
call directly without waiting a real second.

Side effects are injected as closures or a small protocol the model holds:
one for "play this sound" and one for "send this notification (title, body)".
Production wires these to the real `SoundPlayer` and the real
`UNUserNotificationCenter`. Tests wire them to recorders.

The menu-bar title and the time formatting become read-only computed values on
the model:

- `formatTime(_:)` is the same `HH:MM:SS` formatter that lives on `ContentView`
  today, moved as-is.
- the menu-bar title is a computed property that returns `"专注计时器"` when
  idle (not running, `elapsedTime == 0`), `"专注计时器 - 已暂停"` when paused
  (not running, `elapsedTime > 0`), and `"<phase label>: <formatted time>"`
  when running, where the phase label is `"工作中"` or `"休息中"`. This is the
  same three-way logic in `ContentView.updateMenuBarStatus()` today, just moved
  and returning a string instead of calling into `AppDelegate`.

The reminder scheduling (`scheduleRandomNotification`, `play10SecondAlert`) is
out of scope and stays where it is. Only its misleading comment is removed.

### SoundPlayer

A dedicated type that owns the `AVAudioEngine`, the player node, and the
sine-wave buffer building that is in `playAlertSound` today. It keeps the same
`AlertSoundType` cases and the same per-type frequency / amplitude / harmonic /
envelope math.

The start failure stops being swallowed. Instead of `try? engine.start()`, it
does a real `do/try/catch`, records the outcome, and exposes it. The model holds
at least `lastStartError` and `isEngineRunning` so a caller (or a test) can
inspect whether the engine came up. `play(_:)` checks engine state and returns
without scheduling a buffer if the engine is not running, so calling it after a
failed start is safe and silent rather than a crash.

### Version helper

Replace the hardcoded `"Version 1.0.1"` in `AboutView` with a value read from a
bundle's `CFBundleShortVersionString`. Because `Bundle.main` inside a unit test
resolves to the test host rather than the app under test, the read goes through
a small helper that takes a bundle (or its info dictionary) as input. Production
passes `Bundle.main`; the test passes a stub dictionary so it can assert the
formatting without depending on which bundle resolves at runtime.

The unused `FocusApp.version = "1.0.2"` is removed. If anything still needs a
version string it reads it from the bundle through the same helper. Nothing
keeps a second hardcoded copy.

### Help URL constant

Expose the Help URL as one constant. Both the Help menu command and the
`AboutView` Help button read it. A test pins its value. Wiring the actual menu
commands (`.commands` in `FocusApp`) is not unit-testable and is verified by a
screenshot of the running app, per the issue's open questions.

## Acceptance criteria → tests

### Criterion 1 — menu has a custom About item that opens AboutView
- Call chain: none (verified by running app / screenshot). The menu command in
  `FocusApp.commands` calls `appDelegate.showAboutWindow()`, which opens an
  `NSWindow`. That path needs AppKit and a window server.
- Test entry: off chain — a menu command and an `NSWindow` cannot be exercised
  in a unit test without a running app. Functional evidence is a screenshot.
- Test: none (screenshot evidence per the issue's open questions)

### Criterion 2 — Help menu item opens the help URL
- Call chain: none (verified by running app / screenshot). The unit-testable
  part is that both the menu command and the About button read one shared URL
  constant; that is covered by criterion 12.
- Test entry: off chain — same reason as criterion 1. The menu wiring needs a
  running app.
- Test: none (screenshot evidence; the constant itself is pinned by criterion 12)

### Criterion 3 — AboutView shows the bundle's CFBundleShortVersionString
- Call chain: AboutView body → version helper(bundle) → reads
  `CFBundleShortVersionString` from the bundle's info dictionary
- Test entry: the version helper. The test calls it with a stub info dictionary
  rather than going through the SwiftUI view, because the view's rendered text is
  not readable in a unit test and the issue calls for passing the bundle/info as
  input.
- Test: `test_version_reads_short_version_string_from_bundle` in
  `FocusTests/FocusTests.swift`

### Criterion 4 — no hardcoded marketing-version string that can drift
- Call chain: none (direct source-file read)
- Test entry: a test scans the source files (or asserts on the helper) to
  confirm no `"1.0.x"` literal version string remains. The cleanest assertion is
  that the version helper returns the bundle value and the old
  `FocusApp.version` constant is gone. Removal of the literal is also visible in
  the diff.
- Test: `test_version_helper_is_only_version_source` in
  `FocusTests/FocusTests.swift`

### Criterion 5 — misleading "测试用" comments removed from ContentView
- Call chain: none (direct source-file read)
- Test entry: off chain — comment removal is a source edit verified in the diff,
  not behavior. No assertion can read a comment that no longer exists.
- Test: none (diff review)

### Criterion 6 — ContentView drives its timer through TimerModel
- Call chain: ContentView → `@StateObject`/`@ObservedObject` TimerModel →
  start/pause/reset/tick
- Test entry: off chain for the wiring itself (a SwiftUI view's `@StateObject`
  ownership is not unit-testable). The behavioral payoff is that `TimerModel`
  exists and is driven independently of the view, which criteria 7–13 exercise
  directly on the model.
- Test: covered transitively by `test_work_phase_completes_into_break` and the
  other TimerModel tests below; the view-to-model wiring is diff review

### Criterion 7 — work phase reaching workTime starts break, resets, fires sound + notification
- Call chain: TimerModel.tick (repeated until `elapsedTime` reaches `workTime`)
  → phase-boundary branch → switch to break, reset `elapsedTime` to 0, call
  injected sound side effect with `.workToBreak`, call injected notification side
  effect with the break title and body
- Test entry: TimerModel.tick, with recording fakes injected for the two side
  effects. The test advances the model to the boundary and asserts on the
  recorded calls plus the model state.
- Test: `test_work_phase_completes_into_break` in `FocusTests/FocusTests.swift`

### Criterion 8 — break phase reaching breakTime starts work, resets, fires sound + notification
- Call chain: TimerModel.tick (repeated until `elapsedTime` reaches `breakTime`
  while in break phase) → phase-boundary branch → switch to work, reset
  `elapsedTime` to 0, call injected sound side effect with `.breakToWork`, call
  injected notification side effect with the work title and body
- Test entry: TimerModel.tick, with recording fakes injected. The test starts
  the model in the break phase and advances to the boundary.
- Test: `test_break_phase_completes_into_work` in `FocusTests/FocusTests.swift`

### Criterion 9 — formatTime renders a TimeInterval as HH:MM:SS
- Call chain: TimerModel.formatTime(_:)
- Test entry: TimerModel.formatTime directly. A pure function with no
  dependencies.
- Test: `test_format_time_renders_hh_mm_ss` in `FocusTests/FocusTests.swift`

### Criterion 10 — idle menu-bar title is "专注计时器"
- Call chain: TimerModel menu-bar-title computed property, with the model in the
  idle state (not running, `elapsedTime == 0`)
- Test entry: the title property directly on a freshly constructed model.
- Test: `test_menu_title_idle` in `FocusTests/FocusTests.swift`

### Criterion 11 — paused menu-bar title is "专注计时器 - 已暂停"
- Call chain: TimerModel menu-bar-title computed property, with the model in the
  paused state (not running, `elapsedTime > 0`)
- Test entry: the title property after putting the model into the paused state.
- Test: `test_menu_title_paused` in `FocusTests/FocusTests.swift`

### Criterion 12 — running menu-bar title is "<phase label>: <time>"
- Call chain: TimerModel menu-bar-title computed property → formatTime, with the
  model running. Same test file also pins the shared help URL constant for
  criteria 2 and 12's URL requirement.
- Test entry: the title property with the model running at a known
  `elapsedTime`, asserting e.g. `"工作中: 00:00:05"`. A second assertion pins the
  help URL constant's value.
- Test: `test_menu_title_running` and `test_help_url_constant` in
  `FocusTests/FocusTests.swift`

### Criterion 13 — sine-wave synthesis lives in SoundPlayer, not the view
- Call chain: SoundPlayer.play(_:) → buffer build → engine schedule
- Test entry: off chain for "lives in SoundPlayer" as a structural fact (diff
  review). The behavior is exercised by criterion 14's test, which constructs a
  `SoundPlayer` directly.
- Test: covered by `test_sound_player_records_start_outcome` (construction +
  play); the "not inside the view" part is diff review

### Criterion 14 — SoundPlayer surfaces start failures and play is safe after failure
- Call chain: SoundPlayer init → engine start (do/try/catch, records outcome
  into `lastStartError` / `isEngineRunning`) → play(.workToBreak) (guards on
  engine state, no crash if the engine is down)
- Test entry: SoundPlayer construction directly. The test builds a
  `SoundPlayer`, calls `play(.workToBreak)`, and asserts no crash and that the
  start outcome is recorded (either `isEngineRunning` is true, or
  `lastStartError` is set). It does not assert the engine started, because a
  headless test host may have no audio device.
- Test: `test_sound_player_records_start_outcome` in
  `FocusTests/FocusTests.swift`

### Criterion 15 — placeholder example() test replaced with real tests
- Call chain: none (direct source-file read)
- Test entry: off chain — this is satisfied by the existence of the tests above
  and the removal of `example()`. Verified in the diff.
- Test: the suite of tests above replaces `example()`

## Risks & trade-offs

The two menu commands have no automated test. A screenshot is weaker evidence
than a unit test, and a future refactor could break the menu wiring without any
test failing. The mitigation is thin: only the help URL constant is pinned, so
at least the destination can't silently change. The menu plumbing itself is on
the honor system.

The version helper takes a bundle or info dictionary instead of reading
`Bundle.main` directly. That is one indirection added purely so the unit test
can run, since `Bundle.main` resolves to the test host. It is a small wart in
the production call site in exchange for a real assertion.

The `SoundPlayer` test asserts the start outcome is *recorded*, not that the
engine started. On a machine with no audio device the engine legitimately fails
to start, so the test can't demand success. This means the test would still pass
if a bug made the engine always fail to start, as long as the failure is
recorded. It catches the swallowed-error regression, not a broken engine.

Moving the timer tick out of the `Timer` closure into a callable method means
the production path still schedules a real `Timer`, but the tested path calls
the tick method directly. The real scheduling (one tick per second, invalidate
on pause/reset) is not covered by the tick tests; it stays diff-reviewed, the
same coverage it has today.
