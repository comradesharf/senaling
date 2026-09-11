# AGENTS.md

## Scope

These rules apply to work involving:

* `senaling-core`
* `senaling-ffi`
* `safer-ffi`
* Swift bindings
* macOS integration
* Android/JNI integration
* emulator lifecycle
* audio/video transport
* controller input
* FFI memory ownership
* FFI threading and callbacks

The architecture is intentionally conservative.

Do not introduce additional ownership complexity, shared mutable state, or zero-copy mechanisms unless a concrete requirement or profiling result justifies it.

---

# Core Architecture

The dependency direction MUST remain:

```text
senaling-core
      ▲
      │
senaling-ffi
```

`senaling-core` MUST NOT depend on:

* `safer-ffi`
* Swift
* JNI
* Metal
* CoreAudio
* Android APIs
* Apple-specific APIs
* platform-specific FFI concerns

`senaling-ffi` is the translation layer between Rust domain types and the C ABI.

Platform wrappers sit above the C ABI.

```text
Rust Core
   ↓
Rust FFI / safer-ffi
   ↓
C ABI
   ↓
Swift wrapper / Android bridge
   ↓
Application
```

---

# Primary Design Principle

Agents MUST NOT begin by asking:

> How can this Rust type be exposed to Swift?

Instead ask:

> What operation does the foreign API require?

The FFI is an API protocol.

It is NOT a representation of the Rust type system.

Internal Rust types such as:

```text
Arc<T>
Box<T>
Vec<T>
String
dyn Trait
Result<T, E>
```

SHOULD remain internal unless an explicit FFI representation is required.

---

# Emulator Ownership

There MUST be one root emulator object exposed through an opaque handle.

Conceptually:

```text
EmulatorHandle*
```

The handle represents access to Rust-owned emulator infrastructure.

Platform code MUST NOT know the layout of the Rust emulator object.

The platform wrapper MAY expose a native object such as:

```swift
final class Emulator
```

but internally it owns only an opaque FFI handle.

---

# Mutable Emulator State

The most important invariant is:

> Only the Rust emulator thread may mutate `EmulatorCore`.

Agents MUST preserve this invariant.

Do NOT introduce shared direct access such as:

```rust
Arc<Mutex<EmulatorCore>>
```

without a concrete architectural reason.

Do NOT allow Swift, JNI, callback threads, audio threads, or rendering threads to mutate `EmulatorCore` directly.

Communication with the emulator MUST happen through dedicated mechanisms.

---

# Main Emulation Loop

Rust owns the main emulation loop.

The platform MUST NOT drive the emulator by repeatedly calling:

```text
run_frame()
run_frame()
run_frame()
```

The intended lifecycle is:

```text
platform
   │
   │ emulator_start()
   ▼
Rust worker thread
   │
   ▼
EmulatorCore
```

The Rust worker thread owns:

* CPU execution
* PPU execution
* APU execution
* emulator timing
* frame generation
* audio generation
* input sampling

---

# FFI Type Categories

Every FFI-facing value MUST be categorized as one of:

1. value type
2. buffer
3. stateful object

Do not mix these ownership models.

---

# Value Types

Small fixed-layout values SHOULD use FFI-safe structs or enums.

Examples:

```text
EmulatorConfig
ControllerState
VideoFrameInfo
AudioInfo
PixelFormat
Region
ErrorCode
```

Value DTOs MUST NOT accidentally expose internal Rust ownership.

Avoid native Rust fields such as:

```rust
String
Vec<T>
Arc<T>
Box<T>
dyn Trait
```

inside plain ABI structs unless explicitly wrapped in an appropriate FFI-safe representation.

FFI DTOs MUST be treated as transport types.

---

# Core Types and FFI DTOs

Core domain types and FFI types are separate concepts.

Agents SHOULD prefer:

```text
FfiEmulatorConfig
       │
       ▼ conversion
core::EmulatorConfig
```

rather than exposing the core type directly.

Duplication at this boundary is intentional.

Do not remove conversion layers merely because the structures currently have identical fields.

---

# Stateful Objects

Stateful Rust objects MUST use opaque handles.

Examples:

```text
Emulator
Decoder
Session
```

Do NOT expose their internal layouts as C structs.

Do NOT expose ownership-sensitive Rust internals directly.

---

# Child Objects

Do NOT expose CPU, PPU, APU, memory, cartridge, or similar internal components as independently owned handles unless there is a real requirement.

Prefer:

```text
emulator_reset()
emulator_copy_latest_frame()
emulator_read_audio()
```

over:

```text
emulator_cpu()
emulator_ppu()
emulator_memory()
```

If future debugging APIs require internal inspection, return snapshots where possible rather than borrowed child objects.

---

# Snapshots

Mutable internal state SHOULD usually be exposed as copied snapshots.

Example:

```text
CpuState
VideoFrameInfo
AudioInfo
```

A snapshot MUST remain valid independently of later emulator mutations.

Do NOT return borrowed pointers to internal mutable state unless the lifetime contract is extremely explicit and necessary.

---

# ROM Loading

The platform owns file access.

For macOS, Swift SHOULD load ROM bytes.

For Android, the Android/platform layer SHOULD load ROM bytes.

The FFI call may borrow the platform buffer only during the call.

Rust MUST copy the ROM bytes before returning.

Required ownership model:

```text
Platform buffer
    │
    │ borrowed during FFI call
    ▼
FFI
    │
    │ copy
    ▼
Rust-owned Vec<u8>
```

Rust MUST NOT retain a pointer into Swift `Data`, JVM memory, or other platform-owned ROM storage.

---

# Buffer Policy

Every buffer API MUST document whether its memory is:

* borrowed
* copied
* ownership-transferred

If the ownership mode is not clear, the API is incomplete.

The default policy is:

> Prefer copying until profiling proves it is too expensive.

Do NOT introduce zero-copy complexity speculatively.

---

# Video Policy

Video is lossy.

Dropping video frames is allowed.

The video subsystem MUST use:

> latest frame wins

Do NOT use an unbounded frame queue.

Do NOT require every generated frame to be rendered.

If frames 100, 101, and 102 are generated before the renderer consumes a frame, consuming frame 102 directly is acceptable.

This is intentional.

---

# Video V1

Initial video transport SHOULD use copying.

Preferred conceptual API:

```text
emulator_copy_latest_frame(
    handle,
    destination,
    destination_length
)
```

The platform owns the destination buffer.

Rust copies the latest frame into it.

Swift MUST NOT retain pointers into the internal Rust framebuffer.

JNI/platform code MUST NOT retain pointers into the internal Rust framebuffer.

---

# Video Metadata

Video frame layout MUST NOT be implicit.

A frame descriptor SHOULD include enough information to interpret the data.

Recommended fields:

```text
width
height
stride
pixel format
frame number
```

Do NOT assume forever that:

```text
length == width * height * 4
```

Pixel format MUST be part of the contract.

---

# Metal

Metal is a platform rendering concern.

`senaling-core` MUST NOT depend on Metal.

`senaling-ffi` MUST NOT contain Metal-specific behavior unless a future optimization layer is explicitly introduced.

V1 SHOULD use:

```text
Rust framebuffer
      ↓ copy
platform-owned buffer
      ↓
Metal upload
```

Do NOT introduce shared Metal memory or zero-copy framebuffer integration without profiling.

---

# Audio Policy

Audio is NOT lossy in the same way as video.

Dropping audio samples is normally unacceptable.

Audio MUST NOT use the latest-frame pattern.

Audio SHOULD use a ring buffer.

Required conceptual model:

```text
Emulator/APU
    │ producer
    ▼
Audio Ring Buffer
    │ consumer
    ▼
Platform audio subsystem
```

---

# Audio Consumption

Audio SHOULD use a pull model.

Preferred conceptual API:

```text
emulator_read_audio(
    handle,
    output,
    frame_count
)
```

The platform audio callback asks Rust for samples.

Do NOT make the emulator thread synchronously perform heavy platform audio work.

Do NOT require the emulator thread to wait for Swift or JNI audio callbacks.

---

# Audio Format Contract

The audio ABI MUST explicitly define:

* sample type
* sample rate
* number of channels
* channel/interleaving layout
* meaning of returned count

Recommended initial representation:

```text
sample type: f32
layout: interleaved
sample rate: explicit
channels: explicit
```

Do not expose an unlabeled `float*` and assume the consumer knows its meaning.

---

# Input Policy

Controller input SHOULD represent the latest complete controller state.

Prefer:

```text
ControllerState {
    buttons: bitflags
}
```

over an unbounded stream of individual button events.

The emulator samples the current controller state when needed.

Intermediate controller updates MAY collapse.

Example:

```text
state A
state A+LEFT
state LEFT
```

If the emulator only observes the latest meaningful state, that is acceptable.

---

# Commands

Lifecycle and discrete emulator actions SHOULD use a command/message mechanism internally.

Examples:

```text
Stop
Reset
```

Future examples:

```text
Pause
Resume
SetSpeed
LoadState
```

The internal Rust command enum does NOT need to be exposed through the C ABI.

The public ABI SHOULD expose explicit operations such as:

```text
emulator_stop()
emulator_reset()
```

---

# Threading

The emulator worker thread owns mutable emulator state.

Platform callbacks MUST assume they can occur on a non-main thread.

Swift code MUST NOT assume a Rust callback executes on `MainActor`.

Android code MUST NOT assume a callback executes on the UI thread.

Thread hopping is the responsibility of the platform wrapper or application layer.

---

# Callback Policy

Callbacks SHOULD be minimized.

Use callbacks only when they provide a clear benefit.

A callback MUST:

* do minimal work
* return quickly
* avoid blocking the emulator thread
* avoid heavy filesystem access
* avoid long-running rendering operations
* avoid UI work directly
* avoid waiting on unrelated locks

A callback MAY signal that new data is available.

---

# Callback ABI

If callbacks are required, prefer the standard C pattern:

```c
typedef void (*callback)(
    void *context,
    ...
);
```

Use:

```text
function pointer
+
context pointer
```

This SHOULD be preferred over platform-specific closure semantics in the conceptual ABI.

---

# Callback Lifetime

A callback context MUST NOT be destroyed while Rust may still invoke it.

Required shutdown ordering:

```text
1. Request emulator stop
2. Emulator loop exits
3. Join worker thread
4. Guarantee callbacks have stopped
5. Release callback context
6. Destroy handle
```

Do not reorder these steps in a way that creates use-after-free risk.

---

# Lifecycle

Supported baseline lifecycle:

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

Pause is currently out of scope.

Do not add pause semantics unless required by a real feature.

---

# Stop Semantics

`emulator_stop()` MUST be deterministic.

When it returns:

* the emulation worker has exited
* the worker has been joined
* no new video should be produced
* no new audio should be produced
* no emulator callbacks should still be generated

`stop()` SHOULD be idempotent.

Calling it repeatedly MUST NOT cause undefined behavior.

---

# Destroy Semantics

`emulator_destroy()` MUST safely destroy a running emulator.

If necessary it MUST internally stop and join the worker first.

Conceptually:

```text
destroy
   │
   ├── stop if needed
   ├── join thread
   ├── disable callbacks
   ├── release buffers
   └── free handle
```

---

# Swift Cleanup

The Swift wrapper SHOULD expose deterministic cleanup.

Recommended:

```swift
func close()
```

`deinit` SHOULD call `close()` as a fallback.

`close()` SHOULD be safe to call multiple times.

The Swift wrapper MUST prevent using a destroyed handle.

---

# Global State

Do NOT introduce a global emulator singleton in Rust.

Forbidden unless explicitly justified:

```rust
static mut EMULATOR: ...
```

Avoid:

```rust
static EMULATOR: Mutex<Option<...>>
```

for ordinary emulator ownership.

Use an `EmulatorHandle` even though only one emulator instance is currently expected.

---

# Error Handling

`anyhow` MAY be used internally.

`anyhow::Error` MUST NOT cross the C ABI.

Errors crossing the ABI MUST be mapped to stable error categories.

Recommended examples:

```text
Ok
InvalidArgument
InvalidRom
Io
InvalidState
AlreadyRunning
Internal
```

Diagnostic text MAY accompany an error code.

Platform code MUST branch on the error code.

Platform code MUST NOT branch on human-readable error strings.

---

# Panic Policy

A Rust panic MUST NOT unwind through the C ABI.

Expected failures MUST use normal error handling.

FFI entrypoints SHOULD contain unexpected panics where practical and map them to an internal failure.

Never intentionally use panic as an FFI error mechanism.

---

# Strings

Strings are acceptable for:

* diagnostics
* errors
* metadata
* non-hot-path configuration

Strings SHOULD NOT be used for hot or structured state such as:

* button identifiers
* pixel formats
* emulator region
* audio format
* lifecycle state

Prefer:

* enums
* integer values
* bitflags
* structured DTOs

---

# Swift Wrapper

Application code SHOULD NOT call generated safer-ffi C bindings directly.

Raw FFI access belongs inside the Swift package.

The Swift package MUST expose a Swift-native API.

Target shape:

```swift
public final class Emulator {
    public init(
        rom: Data,
        configuration: EmulatorConfiguration = .default
    ) throws

    public func start() throws
    public func stop()
    public func close()

    public func reset()

    public func setControllerState(
        _ state: ControllerState
    )

    public func copyLatestFrame(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Bool

    public func readAudio(
        into buffer: UnsafeMutableBufferPointer<Float>
    ) -> Int
}
```

Exact names may evolve, but ownership semantics MUST remain consistent with this document.

---

# Platform-Specific Layers

The low-level wrapper SHOULD remain platform-neutral where practical.

Apple-specific concerns such as:

```text
Metal
CoreAudio
AVAudioEngine
SwiftUI
AppKit
```

belong above the basic emulator wrapper.

Android-specific concerns such as:

```text
AAudio
Oboe
OpenGL
Vulkan
Android lifecycle APIs
```

also belong above the Rust core and base FFI protocol.

---

# Static Linking

Rust SHOULD be statically incorporated into the platform bridge where practical.

For macOS:

```text
Rust static library
      ↓
XCFramework / SwiftPM integration
      ↓
Swift package
      ↓
macOS app
```

For Android, the Rust core may be statically linked into a JNI/native shared library used by the APK.

Do not interpret the static-linking decision as requiring Android to contain no `.so`.

---

# Build Ownership

Cargo owns Rust builds and generated FFI artifacts.

`safer-ffi` header/interface generation is triggered by Cargo.

SwiftPM MUST NOT be treated as the owner of the Rust build.

Expected flow:

```text
cargo build
   │
   ├── compile Rust
   └── generate FFI artifacts
          ↓
Swift package consumes outputs
```

Debug and Release Rust artifacts SHOULD match the platform build configuration.

---

# ABI Stability

The Swift package and Rust library are shipped together as part of the application.

Long-term binary compatibility across independently distributed versions is NOT currently required.

Breaking FFI changes are allowed if all dependent platform code is rebuilt together.

Do not add complicated ABI compatibility machinery unless distribution requirements change.

A simple diagnostic version function MAY exist:

```text
senaling_ffi_version()
```

---

# Initial Public FFI Surface

Agents SHOULD keep V1 small.

Preferred core FFI types:

```text
EmulatorHandle
EmulatorConfig
ControllerState
VideoFrameInfo
AudioInfo
ErrorCode
```

Preferred operations:

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

Do not expand the FFI surface merely because a Rust method exists.

---

# Explicitly Deferred Features

Unless a task explicitly requires one of these, agents SHOULD NOT introduce:

* child CPU handles
* child PPU handles
* child APU handles
* direct memory handles
* exposed `Arc<T>`
* shared `Mutex<EmulatorCore>`
* debugger FFI
* save states
* pause/resume
* hot ROM swapping
* zero-copy Metal buffers
* complicated callback object graphs
* Swift implementations of Rust traits
* JNI implementations of Rust traits
* multi-emulator global coordination

---

# Testing Requirements

Tests SHOULD be divided into three layers.

## Rust Core Tests

Test domain behavior without FFI.

Examples:

* ROM parsing
* CPU behavior
* PPU behavior
* APU behavior
* controller logic
* emulator state transitions

---

## Rust FFI Tests

Test the ABI contract.

At minimum cover:

```text
create
start
stop
destroy
reset
ROM copy semantics
video copying
audio reads
invalid arguments
error mapping
repeated stop
destroy while running
```

---

## Swift Integration Tests

Test the real Swift wrapper.

Important lifecycle cases:

```text
create → close
create → start → stop → close
start → stop → stop
destroy/close without explicit stop
invalid ROM
repeated creation/destruction
```

Where practical, run lifecycle tests repeatedly to expose ownership bugs.

Example intent:

```text
create and destroy thousands of times
```

---

# Sanitizer Guidance

FFI and concurrency changes SHOULD be validated with sanitizers where practical.

Useful tools include:

```text
Address Sanitizer
Thread Sanitizer
```

Memory ownership bugs and callback races should be treated as high-priority correctness failures.

---

# Review Checklist

Before merging a new FFI API, verify:

* Who owns every pointer?
* How long is every pointer valid?
* Can the platform retain it?
* Who frees it?
* What thread executes the operation?
* Can it block?
* Can the emulator thread safely call it?
* Does it expose core implementation details unnecessarily?
* Could a copied DTO work instead?
* Is an opaque handle more appropriate?
* Could video data be dropped?
* Must audio data be preserved?
* Can destruction race with callbacks?
* Can the API panic across FFI?
* Is the error category stable?
* Is a string being used where an enum or bitflag would be better?
* Is zero-copy actually necessary?
* Does the design also make sense for Android?

If these questions are unanswered, the API design is not complete.

---

# Final Architecture Contract

The architecture is governed by these decisions:

```text
Rust owns the emulator loop.

Rust owns mutable emulator state.

Only the emulator worker mutates EmulatorCore.

Platform code owns file access.

ROM data is copied into Rust.

Controller input is latest-state based.

Commands are message based.

Video is latest-frame based and lossy.

Audio is ring-buffered and normally lossless.

Audio is consumed using a pull API.

Stateful Rust objects use opaque handles.

Small values use FFI DTOs.

FFI DTOs are separate from core domain models.

Callbacks are minimal and non-blocking.

Rust panics never cross the ABI.

Rust-created resources are destroyed by Rust.

Platform-specific rendering/audio stays outside the core.

Copying is preferred over zero-copy until profiling proves otherwise.
```

Any implementation that contradicts these rules should be treated as an architectural change and justified explicitly before proceeding.
