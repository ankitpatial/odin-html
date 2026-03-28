use zed_extension_api::{self as zed, settings::LspSettings};

struct OhtmlExtension;

impl zed::Extension for OhtmlExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        // Check user-configured path in settings
        let settings = LspSettings::for_worktree(language_server_id.as_ref(), worktree)?;
        if let Some(binary_settings) = settings.binary.as_ref() {
            if let Some(path) = binary_settings.path.as_ref() {
                return Ok(zed::Command {
                    command: path.clone(),
                    args: vec!["lsp".to_string()],
                    env: Default::default(),
                });
            }
        }

        // Check PATH for ohtml binary
        if let Some(path) = worktree.which("ohtml") {
            return Ok(zed::Command {
                command: path,
                args: vec!["lsp".to_string()],
                env: Default::default(),
            });
        }

        Err("ohtml binary not found in PATH. Build it with: cd src && odin build . -out:ohtml".to_string())
    }
}

zed::register_extension!(OhtmlExtension);
