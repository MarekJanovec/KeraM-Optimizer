<div align="center">

# KeraM Optimizer v1.0

**Enterprise-Grade Windows Network Stack, NDIS Hardware & Security Hardening Suite**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://github.com/MarekJanovec/KeraM-Optimizer)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/MarekJanovec/KeraM-Optimizer)
[![UI Framework](https://img.shields.io/badge/UI-.NET%20WPF%20%2F%20XAML-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://github.com/MarekJanovec/KeraM-Optimizer)
[![License: MIT](https://img.shields.io/badge/License-MIT-10B981?style=for-the-badge)](LICENSE)

</div>

---

## Overview

**KeraM Optimizer** is a stateless, low-level Windows networking and kernel tuning utility built on a native `.NET WPF` runspace. Engineered for system administrators, network engineers, and competitive power users, it provides deterministic control over the Windows TCP/IP stack (`tcpip.sys`), NDIS miniport driver properties, 802.11ax/be WLAN polling behavior, local DNS/Hosts sinkholing, and Event Tracing for Windows (ETW) packet capture.

---

## ⚡ Quick Start (Stateless RAM Execution)

Run the following command in an **elevated (Administrator) PowerShell** console to bootstrap and launch KeraM Optimizer directly from memory:

```powershell
irm https://raw.githubusercontent.com/MarekJanovec/KeraM-Optimizer/main/KeraM-GUI.ps1 | iex
```

> **Note:** When executed via `irm | iex`, KeraM operates ephemerally. Runtime logs and registry backups are written to an isolated `%TEMP%\KeraM` workspace without polluting your working directory.

---

## 📸 Interface Showcase

| 1. TCP/IP & Kernel Stack | 2. NIC & Wi-Fi 6E Tuning |
| :---: | :---: |
| <img width="100%" alt="TCP-IP-KERNEL" src="https://github.com/user-attachments/assets/feb541bb-42eb-4dd2-bdeb-2cebba0903fb" /> | <img width="100%" alt="NIC-WIFI" src="https://github.com/user-attachments/assets/4f0e3d46-0bc3-4a15-bce3-5e9182a0b1f6" /> |
| **3. Security & Sinkholes** | **4. Live Diagnostic Tools** |
| <img width="100%" alt="SECURITY" src="https://github.com/user-attachments/assets/9ae98b70-3afc-4bdf-926b-e148190a7e70" /> | <img width="100%" alt="TOOLS" src="https://github.com/user-attachments/assets/4d31187d-3626-4cbe-ab08-cb5849137ca7" /> |

---

## ⚙️ Core Architecture & Modules

### 1. TCP/IP Stack & Kernel Scheduling
* **Nagle's Algorithm Mitigation:** Configures `TCPNoDelay=1`, `TcpAckFrequency=1`, and `TcpDelAckTicks=0` per interface to eliminate delayed ACK coalescing.
* **RFC 1323 Header Stripping:** Disables TCP Timestamps to remove 12 bytes of header overhead per packet.
* **Congestion Control & Multi-Core Scaling:** Enables the `CUBIC` congestion provider alongside Receive-Side Scaling (`RSS`) and Explicit Congestion Notification (`ECN`).
* **Ephemeral Port Expansion:** Extends dynamic user ports (`MaxUserPort=65534`) and reduces `TIME_WAIT` socket recycling (`TcpTimedWaitDelay=30s`).
* **MMCSS & Timer Resolution:** Removes the Windows Multimedia Class Scheduler throttling limit (`NetworkThrottlingIndex=0xFFFFFFFF`), sets `SystemResponsiveness=0`, elevates GPU/CPU thread scheduling priorities, and enforces the invariant TSC platform clock over HPET to minimize DPC latency.

### 2. NDIS Physical Adapter (NIC) & 802.11ax/be WLAN Tuning
* **Power State & Flow Control:** Disables IEEE 802.3az Energy Efficient Ethernet (`*EEE`), Green Ethernet, USB/PCIe Selective Suspend, and MAC-layer Flow Control pauses.
* **Offload & Coalescing Bypass:** Disables Interrupt Moderation (`*InterruptModeration=0`), Large Send Offload (`*LsoV2IPv4`/`IPv6`), and Receive Segment Coalescing (`RSC`) to prevent driver-induced packet batching and micro-stuttering.
* **Ring Buffer Geometry:** Calibrates NIC descriptor rings (`*ReceiveBuffers=512`, `*TransmitBuffers=128`) for high-tickrate UDP streams.
* **Wi-Fi 6E Anti-Lag Engine:** Suspends periodic WLAN AutoConfig background spectrum scanning and locks NDIS `RoamAggressiveness` to its lowest threshold to eliminate cyclic latency spikes.
* **DiffServ QoS Marking:** Injects group policy DSCP `46` (Expedited Forwarding) rules for latency-sensitive binaries (`cs2.exe`, `FiveM.exe`, `VALORANT-Win64-Shipping.exe`) and unlocks the 20% `Psched` bandwidth reservation cap.

### 3. Security Hardening & Sinkholes
* **Layer-2/3 Broadcast Suppression:** Disables NetBIOS over TCP/IP (`NBT-NS`) via WMI/CIM and Link-Local Multicast Name Resolution (`LLMNR`) via GPO to prevent local network reconnaissance and MitM spoofing (e.g., *Responder*).
* **Outbound SMB & Telemetry Firewall:** Deploys host-level firewall rules blocking outbound TCP/UDP ports `135`, `137–139`, and `445` to prevent WAN NTLM hash leakage, alongside IP-level blocks for known telemetry endpoints.
* **Idempotent Hosts Sinkhole:** Injects a managed `0.0.0.0` sinkhole block into `%SystemRoot%\System32\drivers\etc\hosts` (with automatic `.bak` preservation) to blackhole 22 Microsoft diagnostic domains at the resolution layer with zero CPU overhead.
* **DNS Leak Mitigation (SMHNR):** Disables Windows Smart Multi-Homed Name Resolution (`DisableSmartNameResolution=1`) and parallel `A`/`AAAA` queries, paired with an automated ICMP RTT benchmark that binds the lowest-latency upstream resolver (Cloudflare, Google, or Quad9).

### 4. Live Diagnostic Utilities
* **ETW Kernel Packet Sniffer (`pktmon`):** Orchestrates the native Windows Event Tracing kernel monitor to capture 10 seconds of live network traffic and converts the raw `.etl` trace into a standard `.pcapng` file on the user's Desktop for immediate inspection in **Wireshark**.
* **Path MTU Discovery (DF-Bit Sweep):** Performs an automated non-fragmented ICMP payload sweep (`ping -f -l`) against the default gateway to calculate and lock the exact L3 Maximum Transmission Unit without packet fragmentation.
* **Locally Administered MAC Anonymizer:** Generates a compliant IEEE 802 Locally Administered Unicast MAC address (`02:XX:XX:XX:XX:XX`), injects it into the active NDIS class registry key, and cycles the adapter.
* **Emergency Panic Reset:** Dedicated one-click recovery routine that reconstructs the Winsock catalog (`netsh winsock reset`), resets the TCP/IP stack, purges Layer-2 ARP tables, and forces a clean DHCP lease negotiation.

---

## 🛡️ Auditing, Telemetry & Factory Rollback

KeraM Optimizer is designed around **strict idempotency and auditability**:

1. **Real-Time Audit Log:** Every registry mutation, NDIS property change, and netsh invocation is timestamped and written to `%TEMP%\KeraM\KeraM.log` alongside host OS/CLR initialization telemetry.
2. **Pre-Flight Snapshot:** The **Create System Backup** module bypasses the 24-hour VSS frequency cap to create an immediate Windows System Restore Point (`KeraM-v1.0-Backup`) and exports the raw `HKLM\...\Tcpip\Parameters` hive to `%TEMP%\KeraM\Tcpip_Backup.reg`.
3. **Deterministic Rollback:** The **Factory Rollback** engine restores the backed-up registry hive, resets NDIS advanced driver properties to factory defaults, re-enables RSC/IPv6/WLAN scanning, strips managed QoS/Firewall policies, and cleans the `hosts` file.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for full details.
