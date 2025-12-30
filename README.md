# WinLoginAudit v2.0

Receive instant SUCCESSFUL or FAILED Windows login attempt notifications on your Telegram chat app (Android/iOS/Windows/macOS).

This project utilizes a Windows Scheduled Task to execute a PowerShell script whenever a successful (Event ID 4624) or failed (Event ID 4625) login event is recorded in the Windows Security event log.

The script parses the event log using dynamic XML mapping to ensure compatibility across different Windows versions (Windows 10, 11, and Windows Server). The gathered information is then sent to a Telegram Chat Bot via a secure POST request using TLS 1.2.

## Key Improvements
* **TLS 1.2/1.3 Support**: Native compatibility with modern Telegram API security requirements.
* **Dynamic XML Parsing**: Reliable data extraction that avoids errors caused by property index shifts in Windows updates.
* **Security Focused**: Designed to run under the SYSTEM context to monitor all users without requiring an active user session.
* **Robust Delivery**: Uses HTTP POST with JSON payloads to safely handle special characters in usernames or hostnames.

---

## Disclaimer

**IMPORTANT: READ BEFORE USE**
This software is provided "as is", without warranty of any kind, express or implied. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
* This script is for monitoring purposes only. 
* The author is not responsible for any service interruptions, data leaks due to Telegram API usage, or misconfigurations of the Windows Security Policy.
* Ensure you comply with local privacy laws (e.g., GDPR) when monitoring user login activities.

---

## Installation and Setup

### 1. Create a Telegram Bot
1. Search for `@botfather` on Telegram.
2. Send `/newbot` and follow the instructions to get your **API TOKEN**.
3. Create a new Group and add your bot to it.
4. Send a test message in the group.
5. Get your **Chat ID** by visiting: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
6. Copy the `id` from the `chat` object (usually starts with a minus sign for groups).
7. Paste the **Token** and **Chat ID** into the `$tokenID` and `$chatsID` variables in the `.ps1` script.

### 2. Configure Windows Security Policy
Windows must be told to log login attempts:
1. Run `secpol.msc`.
2. Navigate to **Local Policies > Audit Policy**.
3. Double-click **Audit logon events** and check both **Success** and **Failure**.
4. Double-click **Audit account logon events** and check both **Success** and **Failure**.

### 3. Enable PowerShell Script Execution
1. Open PowerShell as Administrator.
2. Run: `Set-ExecutionPolicy RemoteSigned -Force`

### 4. Import the Scheduled Task
1. Open **Task Scheduler**.
2. Click **Import Task...** and select the provided `.xml` file.
3. In the **Actions** tab, ensure the path to `LoginAudit.ps1` is correct.
4. In the **General** tab, ensure the task is set to run as **SYSTEM** with **Highest Privileges**.

---

## Technical Appendix: Logon Types Reference

The script maps the following Windows Logon Types to provide context in notifications:

| Type | Name | Description |
| :--- | :--- | :--- |
| 2 | Interactive | Local logon (physical keyboard and monitor). |
| 3 | Network | Connection to a shared folder or printer. |
| 4 | Batch | Scheduled task or batch server execution. |
| 5 | Service | Service started by the Service Control Manager. |
| 7 | Unlock | Desktop was unlocked (e.g., after a screensaver). |
| 8 | NetworkCleartext | Logon via basic authentication (e.g., IIS). |
| 9 | NewCredentials | Used with `runas /netonly`. |
| 10 | RemoteInteractive | Remote Desktop (RDP), Terminal Services, or ICA. |
| 11 | CachedInteractive | Logon with cached credentials (no Domain Controller contact). |
| 12 | CachedRemote | Remote logon using cached credentials. |

---

## Troubleshooting
* **No Notifications?** Verify that the "Security" log in Event Viewer shows Event IDs 4624 or 4625.
* **Connection Error?** Ensure the machine has outbound access to `api.telegram.org` on port 443.
* **Task Not Triggering?** Check the "History" tab in Task Scheduler. Ensure the "Event Trigger" XML matches your system's log structure.
