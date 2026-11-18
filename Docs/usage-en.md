# Photos Sorter CLI — Usage Guide (EN)

## Introduction

Photos Sorter CLI streamlines bulk maintenance of photo and video libraries. Because it can rename, move, or rewrite metadata, always start with backups or disposable copies. Once you confirm the workflow matches your needs, you can safely scale up to the full archive.

## Prerequisites

- macOS 15.0 or newer.
- Access permissions to the folders you intend to process.
- Optional: external drive or cloud backup for safeguarding originals.

## Installation and updates

Select a published PKG from [GitHub Releases](https://github.com/andrey-torlopov/PhotoSorterCLI/releases). The first release targets Apple Silicon (arm64) only; Intel support is not currently claimed. Download `SHA256SUMS` alongside it and run `shasum -a 256 -c SHA256SUMS` before opening the installer. If no releases are published yet, a packaged release is not available.

The PKG installs only `/usr/local/bin/photos-sorter-cli`; Swift/Xcode are not required. Update by installing a newer PKG over the old version, then check `--version`. Stop and report signature/Gatekeeper failures; bypassing system checks is not an installation procedure.

Remove only the executable with `sudo rm /usr/local/bin/photos-sorter-cli`. Photos and the installer receipt remain untouched.

## Verify Installation

```bash
photos-sorter-cli --help
photos-sorter-cli --version
```

If the command prints usage information, the installation succeeded. Launch without arguments to open the interactive menu.

Ctrl-D (EOF) exits any dialogue without starting an incomplete operation. An empty deletion answer preserves originals; deletion requires an explicit yes (`y`/`yes` or `д`/`да`). `--help`/`--version` do not open the menu; unknown arguments, invalid language options, or combining `--help` with `--version` return exit status 64.

## Interface language

The menu, prompts, summaries, help and Core event diagnostics are available in English and Russian. In the main menu choose **7 — Language / Язык**, then **1 — English** or **2 — Русский**. The change applies immediately to subsequent menus, prompts and diagnostics until you exit; **0 — Back** keeps the current language. You can also select a startup language with a flag:

```bash
photos-sorter-cli --language en
photos-sorter-cli --language ru --help
```

`--lang` is an alias. The flag can appear before or after `--help`/`--version` and applies only to this invocation; nothing is saved. Without it, the first non-empty `LC_ALL`, `LC_MESSAGES`, or `LANG` determines the language. `ru`/`en` locales are supported; an explicit unsupported locale (including `C`/`POSIX`) selects English. With no locale variables, the first supported macOS preferred language is used, then English.

Both languages accept `y`, `yes`, `д`, `да` and `n`, `no`, `н`, `нет`, regardless of case. Enter uses the displayed default; deletion defaults to **No**. EOF cancels input. A missing, repeated or unsupported language value exits with code 64 without processing files.

File paths, filenames, date format patterns and protocol identifiers are not translated. Displayed dates and elapsed-time numbers follow the chosen language; the input date string and custom format are passed unchanged to Core. Diagnostics use typed Core events and structured paths; opaque Core/system error descriptions are replaced with localized guidance. Unexpected system errors include their technical domain and code. Raw xattr stdout/stderr is suppressed by the CLI command adapter; its failure still becomes a localized Core event.

## Running the CLI

1. Prepare a small test folder that mirrors your real structure.
2. Run `photos-sorter-cli` and select the desired action (0 exits the program).
3. Provide source/destination paths when prompted. Use absolute paths for clarity.
4. Confirm each configuration summary before execution.
5. Inspect the output folder and logs, then iterate or scale up.

The header shows the installed version (for example, `v.1.0.0`). The menu includes six photo operations and language selection:

| Option | Name | Summary |
| --- | --- | --- |
| 1 | Convert DNG to HEIC | Batch converts DNG images to HEIC. Can delete source files after conversion. |
| 2 | Sort files into folders | Copies or moves media into `Photos` and `Videos` trees, grouped by year/month, with optional renaming to `YYYY-MM-DD--HH-mm`. |
| 3 | Fix dates in files | Reads metadata and updates filesystem creation/modification timestamps accordingly. |
| 4 | Set a specific date | Forces a user-defined timestamp onto all files in the selected folder. |
| 5 | Check filename vs metadata | Compares dates embedded in filenames against metadata, reporting mismatches. |
| 6 | Convert PNG to HEIC | Identical to option 1 but for PNG sources. |
| 7 | Language / Язык | Choose 1 for English, 2 for Русский, or 0 to return. |

## Expected Results

- **Option 1 & 6:** New HEIC files appear alongside the originals (unless deleted). The tool reports every file conversion and any failures.
- **Option 2:** Files are copied or moved into the destination tree (`Photos`/`Videos` → `Year` → `Month`). Optional renaming applies the date-based format.
- **Option 3:** File creation and modification dates align with the metadata. A summary indicates processed counts and issues.
- **Option 4:** All selected files share the specified timestamp. Progress messages confirm each update.
- **Option 5:** A report lists files where the filename date differs from metadata so you can fix them manually or re-run other operations.

## Safety Checklist

Before touching your entire archive, rehearse the workflow on a small, representative folder:

1. Run the CLI on that sample set.
2. Check where each file ended up, confirm creation/modification dates and metadata are correct, and open a few conversions to inspect quality.
3. If everything looks right, repeat the process on progressively larger batches until you are ready for the full library.

Additional guardrails:

- Keep backups or work on copies, especially when enabling deletion of originals.
- Review log output for warnings or errors after every run.
- Disable destructive options on early passes; only enable them when you are confident in the outcome.

## Troubleshooting

- **Cannot open folder:** Ensure the path exists and you have read/write permissions.
- **Metadata errors:** Some formats store metadata differently; re-run with metadata fixes disabled, or convert files first.
- **Date parsing issues:** When prompted, provide the exact format (for example, `dd.MM.yyyy HH:mm`) that matches your input.
- **HEIC conversion failures:** Verify the source files are readable and not corrupted; re-run on a copy.

## Support

- Author: Andrey Torlopov
- Email: torlopov.mail@ya.ru
- License: MIT (see `../LICENSE`).

Share reproducible steps and sample files (if possible) when reporting issues.
