use serde::{Deserialize, Serialize};
use std::net::{TcpStream, ToSocketAddrs};
use std::process::{Command, Stdio};
use std::time::Duration;

const KEYRING_SERVICE: &str = "mcp-mssql-manager";

#[derive(Debug, Serialize, Deserialize)]
pub struct SecretPayload {
    profile_id: String,
    password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TestConnectionPayload {
    server: String,
    port: String,
    database: String,
    user: String,
    password: String,
    package_name: String,
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
fn test_mcp_connection(payload: TestConnectionPayload) -> TestResult {
    let host = payload.server.trim();
    let port = payload.port.trim();
    let package_name = payload.package_name.trim();

    if host.is_empty() || port.is_empty() {
        return failed("Server and port are required before testing.");
    }

    let address = format!("{host}:{port}");
    let socket_addresses = match address.to_socket_addrs() {
        Ok(addresses) => addresses.collect::<Vec<_>>(),
        Err(error) => return failed(format!("Cannot resolve {address}: {error}")),
    };

    let Some(first_address) = socket_addresses.first() else {
        return failed(format!("Cannot resolve {address}: no socket address found."));
    };

    if let Err(error) = TcpStream::connect_timeout(first_address, Duration::from_secs(5)) {
        return failed(format!("TCP connection to {address} failed: {error}"));
    }

    let npx_status = Command::new("npx")
        .arg("--version")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    match npx_status {
        Ok(status) if status.success() => TestResult {
            success: true,
            message: format!(
                "TCP connection to {address} succeeded. npx is available. MCP package `{package_name}` can be launched for database `{}` with user `{}`.",
                payload.database.trim(),
                payload.user.trim(),
            ),
        },
        Ok(status) => failed(format!(
            "TCP connection to {address} succeeded, but `npx --version` exited with code {:?}.",
            status.code()
        )),
        Err(error) => failed(format!(
            "TCP connection to {address} succeeded, but `npx` is not available: {error}"
        )),
    }
}

fn failed(message: impl Into<String>) -> TestResult {
    TestResult {
        success: false,
        message: message.into(),
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
