# Update-TeamsFWRules

![PowerShell](https://img.shields.io/badge/PowerShell-v3.0+-blue)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)]()
[![Build Status](https://img.shields.io/badge/Status-Stable-brightgreen.svg)]()

> **TL;DR:**Automate creation of Teams-specific firewall rules to eliminate initial Windows Security Alerts during Teams call initiation.

---

## Overview

**Update-TeamsFWRules** is a PowerShell script designed to automatically create optimized Windows Firewall rules for Microsoft Teams.  
It is intended for deployment via **Microsoft Intune** or **Scheduled Task**, targeting seamless user experience by eliminating security prompts when users initiate Teams calls.

Modified from Microsoft script found at: https://docs.microsoft.com/en-us/microsoftteams/get-clients#sample-powershell-script

As well as community script fouund at: https://github.com/mardahl/MyScripts-iphase.dk/blob/master/Update-TeamsFWRules.ps1

---

## Features

- Creates inbound firewall rules specific to the currently logged-in user's Teams client.
- Supports **force cleanup** of pre-existing inconsistent firewall rules.
- Logs all major actions and errors to **Event Viewer > Applications and Services Logs > Teams Firewall Rules**.
- Designed for **automation via Intune** or **Scheduled Tasks** at user login.

---

## Prerequisites

- PowerShell **3.0** or newer
- Windows OS with Microsoft Teams Desktop Client installed
- **Administrative privileges** (Run as Administrator)
- Execute in **SYSTEM context** (recommended)

---


## Usage

```powershell
.\Update-TeamsFWRules.ps1 [-Force]
