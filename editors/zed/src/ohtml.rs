use std::fs;
use zed_extension_api::{self as zed, settings::LspSettings};

struct OhtmlExtension {
    cached_binary_path: Option<String>,
}

const OLS_REPO: &str = "DanielGavin/ols";

impl OhtmlExtension {
    fn language_server_binary_path(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<String> {
        // 1. Check user-configured path in settings
        let settings = LspSettings::for_worktree(language_server_id.as_ref(), worktree)?;
        if let Some(binary_settings) = settings.binary.as_ref() {
            if let Some(path) = binary_settings.path.as_ref() {
                return Ok(path.clone());
            }
        }

        // 2. Check PATH
        if let Some(path) = worktree.which("ols") {
            return Ok(path);
        }

        // 3. Check cached download
        if let Some(path) = &self.cached_binary_path {
            if fs::metadata(path).map_or(false, |m| m.is_file()) {
                return Ok(path.clone());
            }
        }

        // 4. Download from GitHub releases
        zed::set_language_server_installation_status(
            language_server_id,
            &zed::LanguageServerInstallationStatus::CheckingForUpdate,
        );

        let release = zed::latest_github_release(
            OLS_REPO,
            zed::GithubReleaseOptions {
                require_assets: true,
                pre_release: false,
            },
        )
        .map_err(|e| format!("failed to fetch OLS releases: {e}"))?;

        let asset_name = match (zed::current_platform().0, zed::current_platform().1) {
            (zed::Os::Mac, zed::Architecture::Aarch64) => "ols-arm64-darwin",
            (zed::Os::Mac, zed::Architecture::X8664) => "ols-x86_64-darwin",
            (zed::Os::Linux, zed::Architecture::Aarch64) => "ols-arm64-unknown-linux-gnu",
            (zed::Os::Linux, zed::Architecture::X8664) => "ols-x86_64-unknown-linux-gnu",
            (zed::Os::Windows, zed::Architecture::X8664) => "ols-x86_64-pc-windows-msvc",
            (os, arch) => return Err(format!("unsupported platform: {os:?}/{arch:?}")),
        };

        let asset = release
            .assets
            .iter()
            .find(|a| a.name.starts_with(asset_name))
            .ok_or_else(|| format!("no OLS release asset for {asset_name}"))?;

        let version_dir = format!("ols-{}", release.version);
        let binary_path = format!("{version_dir}/{asset_name}");

        if !fs::metadata(&binary_path).map_or(false, |m| m.is_file()) {
            zed::set_language_server_installation_status(
                language_server_id,
                &zed::LanguageServerInstallationStatus::Downloading,
            );

            zed::download_file(
                &asset.download_url,
                &version_dir,
                zed::DownloadedFileType::Zip,
            )
            .map_err(|e| format!("failed to download OLS: {e}"))?;

            zed::make_file_executable(&binary_path)
                .map_err(|e| format!("failed to make OLS executable: {e}"))?;
        }

        self.cached_binary_path = Some(binary_path.clone());
        Ok(binary_path)
    }
}

impl zed::Extension for OhtmlExtension {
    fn new() -> Self {
        Self {
            cached_binary_path: None,
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        let path = self.language_server_binary_path(language_server_id, worktree)?;

        Ok(zed::Command {
            command: path,
            args: vec![],
            env: Default::default(),
        })
    }
}

zed::register_extension!(OhtmlExtension);
