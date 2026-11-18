<div align="center">
  <img src="Docs/banner.png" alt="Photos Sorter CLI Banner" width="100%">
  
  <h1>Photos Sorter CLI</h1>
  
  <p>
    <strong>Interactive Swift CLI for sorting, fixing, and organizing photo and video libraries on macOS.</strong>
  </p>
  
  <p>
    <a href="#-what-problem-it-solves">What Problem It Solves</a> •
    <a href="#-safety-first">Safety First</a> •
    <a href="#-features">Features</a> •
    <a href="#-installation">Installation</a> •
    <a href="#-quick-start">Quick Start</a> •
    <a href="#-documentation">Documentation</a> •
    <a href="#-license">License</a> •
    <a href="#-support">Support</a>
  </p>
  
  <p>
    <img src="https://img.shields.io/badge/Platform-macOS%2015.0+-blue.svg" alt="Platform">
    <img src="https://img.shields.io/badge/Swift-6.1+-orange.svg" alt="Swift">
    <img src="https://img.shields.io/badge/CLI-Interactive-green.svg" alt="CLI">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  </p>
  
  <p>
    <a href="README-ru.md">Русская версия</a>
  </p>
</div>

---

Photos Sorter CLI is an interactive macOS terminal tool that helps tame growing photo archives: sort media into structured folders, fix or set metadata dates, validate file naming, and convert DNG/PNG images to HEIC.

## ❓ What Problem It Solves

Photo collections tend to sprawl: duplicates across drives, folders that drift out of sync, and metadata that contradicts itself. Some cloud services even overwrite EXIF tags, leaving you with files whose creation date is lost forever. The CLI helps consolidate everything by renaming files into the `YYYY-MM-DD--HH-MM` format—so the filename always preserves the capture moment even if metadata disappears—and by aligning folder layout and timestamps to restore order.

## ⚠️ Safety First

- Run a test on a small copy of your library first to confirm conversion quality, folder structure, naming, and metadata results meet your expectations—photos and their data are too valuable for guesswork.
- Keep the originals until you are confident the workflow matches your expectations.

Rushing straight into a full archive risks irreversible changes. Take the time to experiment safely.

## ✨ Features

- Sorts photos and videos into `Photos/Year/Month`, with optional date-based renaming.
- Repairs creation and modification metadata or forces a specific timestamp across files.
- Verifies that filenames containing dates match the internal metadata, reporting mismatches.
- Converts DNG and PNG collections to HEIC with optional deletion of the originals.
- Provides verbose progress and error logging for auditing.

## 🛠️ Installation and updates

Requires **macOS 15.0 or newer**. A packaged installation does not require Swift or Xcode.

1. Open [GitHub Releases](https://github.com/andrey-torlopov/PhotoSorterCLI/releases/latest) and select a published version. The first release targets Apple Silicon (arm64) only; installers are named `photos-sorter-cli-1.0.0-arm64.pkg`. Intel support is not currently claimed. Check the release notes for tested machines. Version 1.0.0 displays its version in the menu and supports English/Russian language selection.
2. Download the PKG and `SHA256SUMS`. Run `shasum -a 256 -c SHA256SUMS` in the download directory, then open the PKG. Report validation failures instead of disabling Gatekeeper.
3. Run `photos-sorter-cli --version` and compare it with the selected release. The executable is installed at `/usr/local/bin/photos-sorter-cli`.
4. To update, install a newer PKG over the existing version and check `--version` again. The installer does not change photo libraries. If the command is not found, use the full path or ensure `/usr/local/bin` is in `PATH`.

To remove only the executable: `sudo rm /usr/local/bin/photos-sorter-cli`. This leaves photos, user directories, and the installer receipt untouched.

Maintainers: see [build and release instructions](Docs/release.md). The historical file under `dist/` is not a recommended installation source.

## 🚀 Quick Start

```bash
photos-sorter-cli --help
photos-sorter-cli --version
photos-sorter-cli
```

Use the interactive menu to pick the desired action, supply source/destination folders, and fine-tune options.

Press Ctrl-D at any input prompt to exit. Deletion of originals defaults to off: an empty answer preserves files. Unsupported arguments exit with status 64 without processing anything.

Use `photos-sorter-cli --language en` or `--language ru` (`--lang` also works). Without the flag, language follows `LC_ALL` > `LC_MESSAGES` > `LANG`, then supported macOS language, then English. Unsupported explicit locales use English. Both `yes/no` and `да/нет` are accepted; the choice is not saved. See the [language rules](Docs/usage-en.md#interface-language).

Choose **7 — Language / Язык** in the main menu, then **1 — English** or **2 — Русский**. The header shows `v.1.0.0`; language changes apply immediately until you exit.

## 📚 Documentation

- [Detailed usage (EN)](Docs/usage-en.md)
- [Подробное руководство (RU)](Docs/usage-ru.md)

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

## 🤝 Support

- Author: Andrey Torlopov
- Email: torlopov.mail@ya.ru

Questions, bug reports, or feature ideas are welcome.
