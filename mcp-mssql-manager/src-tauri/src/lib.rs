use serde::{Deserialize, Serialize};

const KEYRING_SERVICE: &str = "mcp-mssql-manager";

#[derive(Debug, Serialize, Deserialize)]
pub struct SecretPayload {
    profile_id: String,
    password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TestResult {
    success: bool,
    message: String,
}

#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("keyring error: {0}")]
    Keyring(#[from] keyring::Error),
}

impl serde::Serialize for AppError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

#[tauri::command]
fn save_profile_password(payload: SecretPayload) -> Result<(), AppError> {
    let entry = keyring::Entry::new(KEYRING_SERVICE, &payload.profile_id)?;
    entry.set_password(&payload.password)?;
    Ok(())
}

#[tauri::command]
fn read_profile_password(profile_id: String) -> Result<String, AppError> {
    let entry = keyring::Entry::new(KEYRING_SERVICE, &profile_id)?;
    Ok(entry.get_password()?)
}

#[tauri::command]
fn delete_profile_password(profile_id: String) -> Result<(), AppError> {
    let entry = keyring::Entry::new(KEYRING_SERVICE, &profile_id)?;
    match entry.delete_credential() {
        Ok(()) => Ok(()),
        Err(keyring::Error::NoEntry) => Ok(()),
        Err(err) => Err(AppError::Keyring(err)),
    }
}

#[tauri::command]
fn test_mcp_connection() -> TestResult {
    TestResult {
        success: false,
        message: "MCP process test is not implemented yet. UI and secure storage are ready for wiring.".to_string(),
    }
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            save_profile_password,
            read_profile_password,
            delete_profile_password,
            test_mcp_connection
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
