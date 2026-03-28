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
        if let Ok(settings) = LspSettings::for_worktree(language_server_id.as_ref(), worktree) {
            if let Some(binary_settings) = settings.binary.as_ref() {
                if let Some(path) = binary_settings.path.as_ref() {
                    let args = binary_settings
                        .arguments
                        .as_ref()
                        .map(|a| a.clone())
                        .unwrap_or_else(|| vec!["lsp".to_string()]);
                    return Ok(zed::Command {
                        command: path.clone(),
                        args,
                        env: Default::default(),
                    });
                }
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

        // Fallback: assume ohtml binary is in the project root
        let project_binary = format!("{}/ohtml", worktree.root_path());
        Ok(zed::Command {
            command: project_binary,
            args: vec!["lsp".to_string()],
            env: Default::default(),
        })
    }
}

zed::register_extension!(OhtmlExtension);
