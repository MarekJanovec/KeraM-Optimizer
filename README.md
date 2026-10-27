```markdown
# KeraM Optimizer v1.0
Enterprise-grade Windows network tuning, security hardening, and diagnostic suite written in PowerShell with a native WPF GUI. Designed for system administrators and power users to gain absolute control over the TCP/IP stack, NDIS hardware parameters, and network routing.

## 🚀 Quick Start
Run the following command in an **elevated (Administrator) PowerShell** prompt to launch KeraM Optimizer v1.0 directly from memory (no manual download required):

```powershell
irm [https://raw.githubusercontent.com/MarekJanovec/KeraM-Optimizer/main/KeraM-GUI.ps1](https://raw.githubusercontent.com/MarekJanovec/KeraM-Optimizer/main/KeraM-GUI.ps1) | iex

```

## ⚙️ Core Architecture & Features

### TCP/IP Stack & Kernel Tuning

* **Latency Reduction:** Disables Nagle's Algorithm (TCPNoDelay) and TCP Timestamps (RFC 1323) to strip header overhead.
* **Congestion Control:** Injects the CUBIC Linux algorithm and enables Receive-Side Scaling (RSS) for multi-core packet distribution.
* **Kernel Schedulers:** Forces Windows Platform Clock to TSC (High Precision Event Timer disabled) to minimize DPC latency. Elevates MMCSS gaming priorities (GPU/CPU) to bypass Windows multimedia network throttling.

### NDIS Physical Adapter (NIC) & WLAN Control

* **Hardware Unlocking:** Disables Energy Efficient Ethernet (EEE), Green Ethernet, Selective Suspend, and Flow Control.
* **Packet Processing:** Disables Interrupt Moderation, Large Send Offload (LSO), and Receive Segment Coalescing (RSC) to prevent hardware-induced bufferbloat and micro-stutters.
* **Wi-Fi 6E Engine:** Suspends WLAN AutoConfig background spectrum scanning and forces Roaming Aggressiveness to its lowest threshold.

### Security Hardening & DNS Sinkholes

* **Layer 2/3 Hardening:** Disables NetBIOS over TCP/IP and LLMNR to mitigate local broadcast spoofing and Man-in-the-Middle (MitM) attacks.
* **Smart Name Resolution:** Prevents Windows multi-homed DNS leaks. Includes dynamic real-time ICMP benchmarking to auto-configure the lowest-latency DNS provider.
* **Firewall & Hosts Sinkhole:** Blocks outbound SMB/RPC ports (135, 137-139, 445) via IPsec rules and injects a 0.0.0.0 hosts sinkhole to instantly drop Microsoft background telemetry at the resolution layer.

### Live Diagnostic Tools

* **Kernel Packet Sniffer:** Utilizes the hidden Windows `pktmon` ETW engine to capture live network traffic, exporting it directly to a Wireshark-ready `.pcapng` file.
* **Path MTU Discovery:** Calculates and applies the exact fragmentation-free packet payload size via automated Don't-Fragment (DF) bit ICMP sweeps.
* **MAC Spoofing:** Generates and injects randomized Locally Administered Unicast hexadecimal MAC addresses directly into the driver registry.

## 🛡️ Safety & Rollback

KeraM Optimizer v1.0 is strictly idempotent and auditable. Every action is recorded in a real-time asynchronous UI logger. The suite includes an isolated **Emergency Panic Reset** (Winsock, IP Stack, ARP, DHCP rebuild) and a complete **Factory Rollback** button that restores the registry, driver defaults, and GPO policies from a localized VSS snapshot.
