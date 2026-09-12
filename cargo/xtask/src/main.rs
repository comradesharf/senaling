use anyhow::{Context, Result, anyhow};

fn build_xcframework() -> Result<()> {
    let status = std::process::Command::new("cargo")
        .args(&["run", "--bin", "generate-headers", "--features", "headers"])
        .status()
        .with_context(|| "Failed to execute generate headers")?;

    if !status.success() {
        return Err(anyhow!("generate headers failed with status: {}", status));
    }

    std::fs::remove_dir_all("packages/SenalingCore/Frameworks/SenalingCoreFFI.xcframework")
        .or_else(|err| {
            if err.kind() == std::io::ErrorKind::NotFound {
                Ok(())
            } else {
                Err(err)
            }
        })?;

    let status = std::process::Command::new("xcodebuild")
        .args(&[
            "-create-xcframework",
            "-library",
            "target/debug/libsenaling_ffi.a",
            "-headers",
            "packages/SenalingCore/Sources/SenalingCoreFFI",
            "-output",
            "packages/SenalingCore/Frameworks/SenalingCoreFFI.xcframework",
        ])
        .status()
        .with_context(|| "Failed to execute xcodebuild")?;

    if !status.success() {
        return Err(anyhow!("xcodebuild failed with status: {}", status));
    }

    Ok(())
}

fn build_ffi() -> Result<()> {
    let status = std::process::Command::new("cargo")
        .args(&["build", "-p", "senaling-ffi"])
        .status()
        .with_context(|| "Failed to execute cargo build")?;

    if !status.success() {
        return Err(anyhow!("cargo build failed with status: {}", status));
    }

    Ok(())
}

fn build_mac_app() -> Result<()> {
    let status = std::process::Command::new("xcodebuild")
        .args(&[
            "-project",
            "./app/senaling-macOS/senaling-macOS.xcodeproj",
            "-scheme",
            "senaling-macOS",
        ])
        .status()
        .with_context(|| "Failed to execute xcodebuild")?;

    if !status.success() {
        return Err(anyhow!("xcodebuild failed with status: {}", status));
    }

    Ok(())
}

fn test_swift() -> Result<()> {
    let status = std::process::Command::new("swift")
        .args(&["test", "--package-path", "./packages/SenalingCore"])
        .status()
        .with_context(|| "Failed to execute swift")?;

    if !status.success() {
        return Err(anyhow!("swift failed with status: {}", status));
    }

    Ok(())
}

fn main() -> Result<()> {
    let command = std::env::args()
        .nth(1)
        .with_context(|| "No command provided")?;

    match command.as_str() {
        "format" => {
            let status = std::process::Command::new("cargo")
                .args(&["fmt", "--all"])
                .status()
                .with_context(|| "Failed to execute cargo fmt")?;

            if !status.success() {
                return Err(anyhow!("cargo fmt failed with status: {}", status));
            }

            let status = std::process::Command::new("swift")
                .args(&["format", ".", "--recursive", "--in-place"])
                .status()
                .with_context(|| "Failed to execute swift format")?;

            if !status.success() {
                return Err(anyhow!("swift format failed with status: {}", status));
            }
        }
        "build-ffi" => {
            build_ffi()?;
        }
        "build-xcframework" => {
            build_ffi()?;
            build_xcframework()?;
        }
        "build-mac-app" => {
            build_ffi()?;
            build_xcframework()?;
            build_mac_app()?;
        }
        "test" => {
            let status = std::process::Command::new("cargo")
                .args(&["test"])
                .status()
                .with_context(|| "Failed to execute cargo test")?;

            if !status.success() {
                return Err(anyhow!("cargo test failed with status: {}", status));
            }

            build_xcframework()?;
            test_swift()?;
        }
        _ => {
            return Err(anyhow!("Unknown command: {}", command));
        }
    }

    Ok(())
}
