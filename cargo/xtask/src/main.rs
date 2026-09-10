use anyhow::{Context, Result, anyhow};

fn build_xcframework() -> Result<()> {
    let status = std::process::Command::new("cargo")
        .args(&["build", "-p", "senaling-core"])
        .status()
        .with_context(|| "Failed to execute cargo build")?;

    if !status.success() {
        return Err(anyhow!("cargo build failed with status: {}", status));
    }

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
            "target/debug/libsenaling_core.a",
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

fn build_core() -> Result<()> {
    let status = std::process::Command::new("cargo")
        .args(&["build", "-p", "senaling-core"])
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

fn main() -> Result<()> {
    let command = std::env::args()
        .nth(1)
        .with_context(|| "No command provided")?;

    match command.as_str() {
        "build-core" => {
            build_core()?;
        }
        "build-xcframework" => {
            build_core()?;
            build_xcframework()?;
        }
        "build-mac-app" => {
            build_core()?;
            build_xcframework()?;
            build_mac_app()?;
        }
        _ => {
            return Err(anyhow!("Unknown command: {}", command));
        }
    }

    Ok(())
}
