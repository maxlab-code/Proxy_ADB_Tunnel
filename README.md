# 📖 User Manual: Proxy ADB Tunnel Utility

> [!IMPORTANT]
> 🌐 Read this in other languages:
> [English](README.md) | [Русский](README.ru.md)


## 1. Purpose of the Utility
**Proxy ADB Tunnel** is a portable script bundle for Windows designed to seamlessly forward VPN traffic from an Android smartphone to a personal computer via a USB cable.

**Key benefits:**
* **ISP Isolation:** Unlike standard "USB tethering" mode, the traffic is not routed through network interfaces but is encapsulated within the Android Debug Bridge (ADB). This completely eliminates DNS leaks and restrictions from your internet service provider.
* **Full Automation:** The script automatically requests Administrator privileges, launches the NekoBox/NekoRay core in the background (in the system tray), and automatically restores the connection if the phone cable is physically reconnected.
* **Portability:** The utility uses relative paths. The entire program folder can be freely moved between drives or used from a flash drive without needing reconfiguration.

---

## 2. Directory Structure
For the utility to function correctly, the folders must be organized in the following order:

```text
📁 Any_Folder_Name/
 ├── 📁 nekoray/                 # NekoBox/NekoRay client folder
 │    ├── nekobox.exe            # (or nekoray.exe)
 │    └── ... (program files)
 │
 └── 📁 Proxy_ADB_Tunnel/        # Folder containing our utility
      ├── Tray_ADB_Proxy.ps1     # Main startup and management script (in the tray)
      └── Auto_Proxy.bat         # Background ADB port forwarding process
```

---

## 3. Initial Setup Process

### Step A: Preparing the Android Smartphone
1. Enable **USB Debugging** in the Developer Options on your phone.
2. Open your VPN application (Proxy, v2rayNG, or similar) and navigate to its settings.
3. Locate the **SOCKS5 Port** parameter and ensure it is set to `10808` (or change the port in the `Auto_Proxy.bat` file if your app uses a different one).
4. Start the VPN connection within the app.

### Step B: Preparing NekoBox on the PC
*This setup only needs to be performed once.*
1. Launch NekoBox manually.
2. In the top menu, select **Profile** -> **Add Profile** -> **SOCKS**.
3. Fill in the profile details:
   * **Name:** ADB Tunnel (or any name you prefer)
   * **Address:** `127.0.0.1`
   * **Port:** `10808` *(this local port is reserved by our script)*
4. Click **OK**.
5. Right-click on the newly created profile and select **Start**.
6. Check the **TUN Mode** box in the program's interface.
7. Completely close NekoBox (exit the application from the system tray).

---

## 4. Everyday Use

1. Connect your smartphone to the PC using a USB cable.
2. During the first connection to the PC, the phone may request debugging permission — tap "Always allow from this computer".
3. Enable tethering mode on your smartphone.
4. Run the `Tray_ADB_Proxy.ps1` file.
   * *Note:* If the system prompts for Administrator privileges (User Account Control / UAC) — click **"Yes"**. This is required for TUN Mode to work in NekoBox.
5. A command line icon will appear in the system tray (near the clock).
6. You're all set! The script will automatically launch NekoBox minimized and bring up the tunnel. All Windows traffic is now routed through your phone.

---

## 5. Utility Management (Tray Menu)
Right-clicking the icon in the system tray opens the management menu:

* **▶ Start auto-tunnel:** Force-starts the background process that waits for the cable and launches NekoBox if they were closed.
* **👁 Show / Hide console (or Double-click the icon):** Displays a window with ADB operation logs. This is useful for diagnostics: it shows whether the script is waiting for the phone or if the port has been successfully forwarded. Clicking it again hides the window in the background.
* **⏹ Stop:** Completely disables port forwarding, terminates background ADB processes, and closes NekoBox. The script itself remains active in the tray.
* **❌ Exit:** Stops all tunnel processes, closes NekoBox, and completely unloads the utility from the PC's memory.
