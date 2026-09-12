# Rust FFI Architecture

## Purpose

This document records the architectural decisions for exposing the Rust emulator core to platform applications, starting with macOS through Swift and later Android.

The FFI layer is implemented using `safer-ffi`.

The primary goals are:

* Keep the Rust emulator core independent from platform-specific code.
* Expose a stable and simple C ABI.
* Keep memory ownership explicit.
* Avoid sharing mutable emulator state directly across threads.
* Support Rust-owned emulation, video, audio, and input handling.
* Make the same Rust FFI usable by both macOS and Android.
* Prefer correctness and simple ownership over premature zero-copy optimization.

---

# High-Level Architecture

```text
                         Rust

                ┌──────────────────────┐
                │    senaling-core     │
                │                      │
                │ Emulator             │
                │ CPU / PPU / APU      │
                │ Cartridge / ROM      │
                │ Emulation timing     │
                └──────────┬───────────┘
                           │ Rust API
                           ▼
                ┌──────────────────────┐
                │     senaling-ffi     │
                │      safer-ffi       │
                │                      │
                │ opaque handles       │
                │ FFI DTOs             │
                │ errors               │
                │ buffers              │
                │ lifecycle            │
                └───────┬────────┬─────┘
                        │ C ABI  │
              ┌─────────┘        └─────────┐
              ▼                            ▼
     ┌─────────────────┐          ┌─────────────────┐
     │ Swift Package   │          │ Android bridge  │
     │                 │          │ JNI / Kotlin    │
     │ Swift-native API│          │ Kotlin API      │
     └────────┬────────┘          └────────┬────────┘
              ▼                            ▼
          macOS App                    Android App
```

The Rust core must not depend on Swift, JNI, Metal, Android APIs, or `safer-ffi`.

Only the FFI crate knows about the ABI.

---

# Repository Structure

Recommended structure:

```text
senaling/
├── Cargo.toml
│
├── crates/
│   ├── senaling-core/
│   │   └── src/
│   │       ├── emulator.rs
│   │       ├── cpu.rs
│   │       ├── ppu.rs
│   │       ├── apu.rs
│   │       ├── cartridge.rs
│   │       └── ...
│   │
│   └── senaling-ffi/
│       ├── build.rs
│       └── src/
│           ├── lib.rs
│           ├── emulator.rs
│           ├── video.rs
│           ├── audio.rs
│           ├── input.rs
│           ├── error.rs
│           └── types.rs
│
├── swift/
│   └── Senaling/
│       ├── Package.swift
│       ├── Sources/
│       │   ├── CSenaling/
│       │   │   └── generated safer-ffi interface
│       │   └── Senaling/
│       │       ├── Emulator.swift
│       │       ├── EmulatorConfiguration.swift
│       │       ├── ControllerState.swift
│       │       ├── Video.swift
│       │       ├── Audio.swift
│       │       └── SenalingError.swift
│       └── Tests/
│
└── android/
    └── ...
```

Dependency direction:

```text
senaling-core
      ▲
      │
senaling-ffi
```

`senaling-core` must not depend on `senaling-ffi`.

---

# Core Design Principle

Do not ask:

> How do we expose this Rust type to Swift?

Instead ask:

> What operation does the foreign API need?

The C ABI is an interface protocol.

It is not intended to reproduce Rust's internal type system.

Rust concepts such as:

```text
Arc<T>
Box<T>
Vec<T>
String
dyn Trait
Result<T, E>
```

must generally remain implementation details.

---

# FFI Data Classification

Every value crossing the FFI boundary should belong to one of three categories.

## 1. Value Types

Small fixed-layout data.

Examples:

```text
EmulatorConfig
VideoFrameInfo
AudioInfo
ControllerState
Region
PixelFormat
```

Represent them as FFI-safe fixed-layout structures or enums.

Example:

```rust
#[derive_ReprC]
#[repr(C)]
pub struct VideoFrameInfo {
    pub width: u32,
    pub height: u32,
    pub stride: u32,
    pub frame_number: u64,
}
```

These types contain data only.

They must not contain Rust-owned types such as:

```rust
String
Vec<T>
Arc<T>
Box<T>
dyn Trait
```

unless specifically represented using an FFI-safe `safer-ffi` type.

---

## 2. Buffers

Examples:

* ROM bytes
* framebuffer pixels
* audio samples

Every buffer must explicitly define whether it is:

```text
borrowed
copied
ownership-transferred
```

The default policy is:

> Copy unless profiling shows a meaningful performance problem.

---

## 3. Stateful Objects

Examples:

```text
Emulator
Decoder
Session
```

Stateful Rust objects must use opaque handles.

Example conceptually:

```text
EmulatorHandle*
```

Platform code must not know the layout of the Rust object.

---

# Main Emulator Ownership

There is one root object:

```text
EmulatorHandle
```

Swift owns the handle.

Rust owns the actual emulator state.

Conceptually:

```text
Swift Emulator
      │
      ▼
EmulatorHandle
      │
      ▼
Rust emulator infrastructure
      │
      ▼
EmulatorCore
```

The platform wrapper must not directly expose internal objects such as:

```text
CPU
PPU
APU
Memory
Cartridge
```

as independently owned handles unless a future feature requires it.

For now operations should remain on the emulator.

Example:

```text
emulator_set_controller_state()
emulator_reset()
emulator_copy_latest_frame()
emulator_read_audio()
```

instead of:

```text
emulator_cpu()
emulator_ppu()
emulator_memory()
```

---

# Emulator Thread Ownership

Rust owns the main emulation loop.

Swift does not repeatedly call something like:

```text
run_frame()
run_frame()
run_frame()
```

Instead:

```text
Swift
   │
   │ emulator_start()
   ▼
Rust EmulatorHandle
   │
   └── worker thread
          │
          ▼
      EmulatorCore
```

The Rust worker thread is responsible for:

```text
CPU execution
PPU execution
APU execution
timing
frame generation
audio generation
input sampling
```

---

# Mutable State Rule

The most important concurrency invariant is:

> Only the emulator thread mutates `EmulatorCore`.

Do not expose the core as:

```rust
Arc<Mutex<EmulatorCore>>
```

unless a future feature proves this necessary.

Avoid sharing direct mutable access to the emulator across threads.

Instead communicate with the emulator thread.

---

# Internal Communication

Different types of information use different synchronization mechanisms.

```text
                       Emulator Thread
                             ▲
                             │
Commands ────────────────────┤
                             │
Controller State ────────────┤
                             │
Video ───────────────────────┤
                             │
Audio ───────────────────────┤
```

The mechanisms should reflect the semantics of the data.

## Commands

Commands use a channel or equivalent message mechanism.

Examples:

```text
Stop
Reset
```

Possible future commands:

```text
Pause
Resume
LoadState
SetSpeed
```

The internal Rust representation may use:

```rust
enum Command {
    Stop,
    Reset,
}
```

This internal enum does not need to become part of the C ABI.

The FFI API can remain:

```text
emulator_stop()
emulator_reset()
```

---

# Controller Input

Controller input should represent current state rather than an unbounded event stream.

Preferred:

```rust
struct ControllerState {
    buttons: u32,
}
```

Example:

```text
A | LEFT | START
```

Rust samples the latest state when needed.

Conceptually:

```text
UI
 │
 │ updates
 ▼
ControllerState
 │
 │ sampled
 ▼
Emulator thread
```

This avoids queueing large numbers of button-down and button-up events.

---

# ROM Loading

Swift owns platform file access.

Example:

```swift
let data = try Data(contentsOf: url)
let emulator = try Emulator(rom: data)
```

The FFI call borrows the Swift memory only for the duration of the call.

Rust immediately copies the ROM bytes.

```text
Swift Data
    │
    │ temporary borrowed pointer
    ▼
FFI call
    │
    │ copy
    ▼
Rust Vec<u8>
```

After creation returns:

```text
Swift may release Data
Rust owns its ROM copy
```

Rust must never retain a pointer into Swift's `Data`.

---

# Video Architecture

Video may drop frames.

Therefore video should be designed as:

```text
latest frame wins
```

Do not queue every generated frame.

Bad:

```text
Frame 100
Frame 101
Frame 102
Frame 103
...
```

If rendering falls behind, this produces latency.

Instead:

```text
PPU
 │
 │ publishes
 ▼
Latest Frame Slot
 │
 │ replaces previous frame
 ▼
Renderer gets newest available frame
```

If frames 100, 101, and 102 are generated before the renderer consumes one, the renderer may receive frame 102 directly.

This behavior is intentional.

---

# Video V1 Strategy

Start with copying.

Recommended API concept:

```text
emulator_copy_latest_frame(
    handle,
    destination,
    destination_length
)
```

The platform owns the destination buffer.

Rust copies the latest framebuffer into it.

No Rust framebuffer pointer is retained by Swift.

This provides simple ownership and prevents use-after-free errors.

---

# Future Video Optimization

The likely macOS renderer is Metal.

V1 should not attempt zero-copy integration with Metal.

Initial data flow:

```text
Rust framebuffer
      │
      │ copy
      ▼
Swift/platform buffer
      │
      ▼
Metal texture/upload
```

If profiling later shows the copy is significant, the design may evolve toward shared/staging buffers.

Do not optimize this before measurements justify it.

---

# Video Metadata

Do not assume the framebuffer is always:

```text
width × height × 4
```

Expose a descriptor.

Example:

```rust
#[repr(C)]
pub struct VideoFrameInfo {
    pub width: u32,
    pub height: u32,
    pub stride: u32,
    pub frame_number: u64,
    pub format: PixelFormat,
}
```

Possible formats might include:

```text
RGBA8888
BGRA8888
```

The exact format must be part of the ABI contract.

---

# Audio Architecture

Audio differs fundamentally from video.

Video:

```text
dropping frames is acceptable
```

Audio:

```text
dropping samples is normally unacceptable
```

Therefore audio uses a ring buffer.

```text
Emulator/APU thread
        │
        │ produces samples
        ▼
┌────────────────────────┐
│      Audio Ring        │
│                        │
│ samples samples ...    │
└────────────────────────┘
        │
        │ consumes
        ▼
Platform audio subsystem
```

The emulator is the producer.

The platform audio callback is the consumer.

---

# Audio API

Prefer a pull API:

```text
emulator_read_audio(
    handle,
    output,
    frame_count
)
```

instead of Rust continuously invoking Swift callbacks with audio data.

Conceptually:

```text
Rust emulator thread
        │
        ▼
    ring buffer
        ▲
        │
 CoreAudio callback
```

This design also maps naturally to Android audio APIs.

---

# Audio Format Contract

The audio representation must be explicitly documented.

Recommended initial format:

```text
sample format: f32
channel layout: interleaved
sample rate: configuration-defined
channel count: explicitly reported
```

Example:

```rust
#[repr(C)]
pub struct AudioInfo {
    pub sample_rate: u32,
    pub channels: u32,
}
```

For example:

```text
48000 Hz
2 channels
interleaved f32
```

The meaning of the output buffer must not be implicit.

---

# Platform Callbacks

Callbacks may later be needed for:

```text
frame available
state changed
logging
errors
```

Rust callbacks may occur on Rust-owned threads.

Therefore:

> Platform callbacks must assume they are not running on the Swift MainActor or Android UI thread.

Callbacks must perform minimal work and return quickly.

Do not run rendering, heavy allocation, filesystem access, or blocking operations directly inside an emulator callback.

---

# Callback ABI Pattern

Prefer a standard C callback representation:

```c
typedef void (*callback)(
    void *context,
    ...
);
```

The pair:

```text
function pointer
+
context pointer
```

should be used rather than making platform-specific closure behavior part of the conceptual ABI.

This works well for:

```text
Swift
JNI
C++
other future bindings
```

---

# Callback Lifetime Rule

Callback shutdown must be explicit.

A callback context must not be freed while Rust may still invoke the callback.

Shutdown order:

```text
1. Request emulator stop
2. Emulator worker exits
3. Join emulator worker
4. Guarantee no more callbacks
5. Release callback context
6. Destroy Rust handle
```

This ordering is required to avoid use-after-free.

---

# Swift API

The Swift package must expose a Swift-native API.

Application code should never normally interact directly with generated C functions or raw Rust pointers.

Example high-level API:

```swift
public final class Emulator {
    public init(
        rom: Data,
        configuration: EmulatorConfiguration = .default
    ) throws

    public func start() throws
    public func stop()

    public func setControllerState(_ state: ControllerState)

    public func copyLatestFrame(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Bool

    public func readAudio(
        into buffer: UnsafeMutableBufferPointer<Float>
    ) -> Int
}
```

Raw FFI calls belong inside the Swift package implementation.

---

# Platform-Specific Components

Do not place Metal or CoreAudio directly into the low-level FFI wrapper.

Recommended layering:

```text
Senaling
├── Emulator
├── ControllerState
├── VideoFrameInfo
├── AudioInfo
└── SenalingError

Apple application/platform layer
├── MetalRenderer
└── AudioRenderer
```

Later Android can provide:

```text
Android renderer
Android audio subsystem
```

without changing the Rust emulator interface.

---

# Lifecycle

The emulator follows roughly:

```text
Created
   │
   ▼
Running
   │
   ▼
Stopped
   │
   ▼
Destroyed
```

Pause is not currently needed.

It may be added later without changing the general architecture.

---

# Stop Semantics

`emulator_stop()` must be deterministic.

It should:

```text
request worker shutdown
       ↓
emulation loop exits
       ↓
worker thread joined
       ↓
video/audio production stops
       ↓
callbacks can no longer occur
       ↓
return
```

`stop()` should be safe to call multiple times.

Example:

```text
stop()
stop()
stop()
```

should not crash.

---

# Destroy Semantics

Destroying the emulator must automatically stop it if necessary.

Conceptually:

```text
emulator_destroy()
    │
    ├── stop if running
    ├── join worker
    ├── release buffers
    └── release handle
```

The Swift wrapper should expose deterministic cleanup.

Example:

```swift
public func close()
```

and also:

```swift
deinit {
    close()
}
```

The platform may call `close()` explicitly.

---

# Opaque Handle Policy

Even though only one emulator is expected to exist today, do not use global singleton emulator state.

Avoid:

```rust
static mut EMULATOR: ...
```

or globally shared emulator instances.

Continue using:

```text
EmulatorHandle*
```

This makes:

```text
testing
future multi-instance support
ownership
cleanup
```

much easier.

---

# FFI Struct Policy

FFI DTOs and Rust domain types are separate concepts.

Example:

```text
FfiEmulatorConfig
      │
      │ conversion
      ▼
core::EmulatorConfig
```

Do not expose internal domain structures just because they currently happen to be FFI compatible.

Duplication at this boundary is intentional.

The FFI layer acts as a compatibility and translation layer.

---

# Error Handling

The Rust core currently uses `anyhow`.

This is acceptable internally.

`anyhow::Error` must not cross the ABI.

Errors should be translated into stable error categories.

Example:

```rust
#[repr(i32)]
pub enum ErrorCode {
    Ok = 0,
    InvalidArgument = 1,
    InvalidRom = 2,
    Io = 3,
    InvalidState = 4,
    AlreadyRunning = 5,
    Internal = 1000,
}
```

Diagnostic messages may accompany the code.

Example:

```text
code:
    InvalidRom

message:
    "NES header contains an invalid magic value"
```

Platform code branches on the code.

It must never branch on error message text.

Bad:

```swift
if message == "Invalid ROM" {
    ...
}
```

Good:

```swift
switch code {
case .invalidRom:
    ...
}
```

---

# Panic Policy

A Rust panic must never unwind across the C ABI.

FFI entry points should contain unexpected failures where practical and convert them into an internal error.

Architectural invariant:

```text
Rust panic
    X
    X must not cross
    X
C ABI
```

Normal expected errors must use Rust error handling rather than panics.

---

# Strings

Strings are acceptable for:

```text
errors
diagnostics
metadata
non-hot-path configuration
```

Strings should not be used for frequently interpreted ABI state such as:

```text
buttons
pixel formats
regions
state values
audio formats
```

Prefer enums, integers, flags, and structured values.

---

# Static Linking

The current deployment decision is to use static linking for the Rust library where practical.

For macOS:

```text
Rust static library
       ↓
XCFramework / SwiftPM binary integration
       ↓
Swift package
       ↓
macOS application
```

For Android, the Rust core may be statically linked into the JNI/native bridge even if the resulting Android package ultimately contains a `.so`.

The architectural goal is:

> The Rust core is incorporated into the platform bridge rather than loaded as an independently versioned runtime component.

---

# Build Ownership

Cargo owns Rust generation and build orchestration.

`safer-ffi` generates the FFI header/interface.

SwiftPM does not trigger Cargo automatically.

The intended flow is:

```text
Cargo build
    │
    ├── Rust library
    └── generated FFI interface

        ↓

Swift package consumes generated artifacts
```

Debug and Release Rust builds should correspond to platform build configurations.

---

# ABI Compatibility

The Swift package and Rust library are not independently distributed.

They are built and shipped together as part of the application.

Therefore strict long-term binary compatibility is not currently required.

Breaking FFI changes are acceptable when the whole application is rebuilt together.

A simple version function may still be useful:

```text
senaling_ffi_version()
```

for diagnostics.

---

# Initial FFI Surface

V1 should remain intentionally small.

Recommended exported concepts:

```text
EmulatorHandle

EmulatorConfig
ControllerState
VideoFrameInfo
AudioInfo
ErrorCode
```

Recommended exported operations:

```text
emulator_create
emulator_start
emulator_stop
emulator_destroy

emulator_reset

emulator_set_controller_state

emulator_copy_latest_frame

emulator_read_audio
```

Additional functionality should only be added as required.

---

# Features Intentionally Deferred

Do not implement these unless a real requirement appears:

```text
child CPU/PPU/APU handles
Arc exposed through FFI
shared mutable emulator core
save states
debugger API
pause/resume
zero-copy Metal framebuffer
complex platform callbacks
hot ROM swapping
Swift-created polymorphic Rust implementations
multi-emulator coordination
```

The current architecture should allow these to be added later without redesigning the core ownership model.

---

# FFI Rules

These rules should be treated as architectural requirements.

1. Stateful Rust objects use opaque handles.

2. Small fixed-layout data uses FFI-safe value DTOs.

3. FFI DTOs and core Rust domain types are separate.

4. Rust owns mutable emulator state.

5. Only the emulator worker thread mutates `EmulatorCore`.

6. Swift does not directly mutate internal emulator objects.

7. ROM data is copied into Rust during emulator creation.

8. Video uses a latest-frame model.

9. Video frames may be dropped.

10. Audio uses a ring buffer.

11. Audio data should normally not be dropped.

12. Audio is consumed through a pull/read API.

13. Controller input represents current state.

14. No unbounded queue should be used for video.

15. No pointer may be retained beyond its documented lifetime.

16. Objects allocated by Rust are destroyed using Rust-provided APIs.

17. Callback code must assume an arbitrary Rust thread.

18. Callback code must not block the emulator thread.

19. Destroying an emulator must stop and join its worker thread.

20. `stop()` should be idempotent.

21. Destroying a running emulator must safely stop it first.

22. Rust panics must not unwind through the C ABI.

23. `anyhow` errors must be converted into FFI error codes.

24. Platform code must branch on error codes, not error messages.

25. Avoid global emulator state even when only one emulator currently exists.

26. Prefer copying over zero-copy until profiling demonstrates a need.

27. Platform-specific rendering and audio APIs stay outside the Rust core.

28. The same conceptual FFI should support macOS and Android.

---

# Concurrency Model Summary

```text
                          Swift / Android
                               │
             ┌─────────────────┼─────────────────┐
             │                 │                 │
             │ commands        │ controller      │ video/audio
             ▼                 ▼                 ▲
      Command channel      current state         │
             │                 │                 │
             └────────────┬────┘                 │
                          ▼                      │
                ┌──────────────────┐             │
                │ Emulator Thread  │             │
                │                  │             │
                │ EmulatorCore     │             │
                │ CPU / PPU / APU  │             │
                └───────┬────┬─────┘             │
                        │    │                   │
                     video  audio                │
                        │    │                   │
                        ▼    ▼                   │
                  latest     ring                │
                  frame     buffer               │
                    │         │                  │
                    └─────────┴──────────────────┘
```

---

# Stream Semantics

| Data             | Direction       | Mechanism           | Loss Allowed                      |
| ---------------- | --------------- | ------------------- | --------------------------------- |
| Commands         | Platform → Rust | channel             | No                                |
| Controller state | Platform → Rust | latest state        | Intermediate updates may collapse |
| ROM              | Platform → Rust | copy on creation    | No                                |
| Video            | Rust → Platform | latest-frame buffer | Yes                               |
| Audio            | Rust → Platform | ring buffer         | Normally no                       |
| Errors           | Rust → Platform | result/error code   | No                                |

---

# Final Architecture Decision

The emulator architecture is based on one central rule:

> The Rust emulator thread is the sole owner of mutable emulator state.

Platform applications communicate with it through a small FFI protocol.

The initial communication model is:

```text
ROM
    copy into Rust

Commands
    message/channel based

Controller
    latest state

Video
    latest-frame, lossy, initially copied

Audio
    ring-buffered, continuous, platform pulls samples
```

The FFI layer remains platform-neutral and is shared conceptually by macOS and Android.

Optimization such as zero-copy Metal integration will only be introduced after profiling shows that the simpler copying architecture is insufficient.
