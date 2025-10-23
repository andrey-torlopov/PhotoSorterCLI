# 📸 Photos Sorter CLI

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

## 🛠️ Installation

1. Download the signed installer: [photos-sorter-cli.pkg](dist/photos-sorter-cli.pkg)  
   Replace the link with your hosted location (for example, GitHub Releases) if distributing publicly.
2. Open the `.pkg` file and follow the installer steps.
3. After installation, `photos-sorter-cli` is available via Terminal.

## 🚀 Quick Start

```bash
photos-sorter-cli
```

Use the interactive menu to pick the desired action, supply source/destination folders, and fine-tune options.

## 📚 Documentation

- [Detailed usage (EN)](Docs/usage-en.md)
- [Подробное руководство (RU)](Docs/usage-ru.md)

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

## 🤝 Support

- Author: Andrey Torlopov
- Email: torlopov.mail@ya.ru

Questions, bug reports, or feature ideas are welcome.
