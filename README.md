# NovaClean

**Cleaning, organization, and system monitoring for macOS.**

NovaClean is an open-source macOS application that brings together tools for analyzing disk usage, locating large files, managing applications, and monitoring system performance.

[**Download NovaClean v1.3.0**](https://github.com/gaalso/NovaClean/releases/tag/v1.3.0) · [Source code](https://github.com/gaalso/NovaClean)

**Language:** English | [Português (Brasil)](README.pt-BR.md)

## Features

- **Smart Care:** combines cleaning analyses and presents suggestions in one place.
- **System Junk:** identifies caches that may be removed.
- **Large Files:** finds large files in personal folders.
- **Disk Space Explorer:** visualizes file distribution and allows folder navigation.
- **Applications:** lists installed applications and provides an option to move them to Trash.
- **Trash:** checks occupied space and allows you to empty it.
- **Speed Up:** provides information about memory usage and running applications.
- **System Monitor:** tracks CPU, memory, storage, thermal status, and processes.

## Download and Installation

**Requirement:** macOS 12 or later.

1. Visit the [NovaClean v1.3.0 release page](https://github.com/gaalso/NovaClean/releases/tag/v1.3.0).
2. Expand **Assets**, if necessary.
3. Choose the `.dmg` installer appropriate for your Mac.
4. Open the disk image and drag NovaClean into the Applications folder.

Check the filenames on the release page to distinguish Intel, Apple Silicon, and Universal builds.

### Security Notice

This release is not notarized by Apple. macOS may display a security warning when you first open the application. Only proceed if you trust the source and have verified the downloaded file.

Review cleaning actions before applying them. Most removals are sent to Trash, but emptying Trash may permanently delete files.

## Development Requirements

- macOS 12 or later
- Xcode Command Line Tools
- Swift and the required build tools

## Build from Source

Clone the repository:

```sh
git clone https://
