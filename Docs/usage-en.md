# Photos Sorter CLI — Usage Guide (EN)

## Introduction

Photos Sorter CLI streamlines bulk maintenance of photo and video libraries. Because it can rename, move, or rewrite metadata, always start with backups or disposable copies. Once you confirm the workflow matches your needs, you can safely scale up to the full archive.

## Prerequisites

- macOS 13.0 or newer.
- Access permissions to the folders you intend to process.
- Optional: external drive or cloud backup for safeguarding originals.

## Installation

1. Download the signed installer: [photos-sorter-cli.pkg](../dist/photos-sorter-cli.pkg).  
   Replace the link with your hosted location if distributing publicly.
2. Double-click the `.pkg` file and follow the installer instructions.
3. The binary `photos-sorter-cli` is installed system-wide and can be launched from Terminal or Spotlight.

## Verify Installation

```bash
photos-sorter-cli --help
```

If the command prints usage information, the installation succeeded. Launch without arguments to open the interactive menu.

## Running the CLI

1. Prepare a small test folder that mirrors your real structure.
2. Run `photos-sorter-cli` and select the desired action (0 exits the program).
3. Provide source/destination paths when prompted. Use absolute paths for clarity.
4. Confirm each configuration summary before execution.
5. Inspect the output folder and logs, then iterate or scale up.

The menu includes six core operations:

| Option | Name | Summary |
| --- | --- | --- |
| 1 | Convert DNG to HEIC | Batch converts DNG images to HEIC. Can delete source files after conversion. |
| 2 | Sort files into folders | Moves media into `Photos` and `Videos` trees, grouped by year/month, with optional renaming to `YYYY-MM-DD--HH-mm`. |
| 3 | Fix dates in files | Reads metadata and updates filesystem creation/modification timestamps accordingly. |
| 4 | Set a specific date | Forces a user-defined timestamp onto all files in the selected folder. |
| 5 | Check filename vs metadata | Compares dates embedded in filenames against metadata, reporting mismatches. |
| 6 | Convert PNG to HEIC | Identical to option 1 but for PNG sources. |

## Expected Results

- **Option 1 & 6:** New HEIC files appear alongside the originals (unless deleted). The tool reports every file conversion and any failures.
- **Option 2:** Files move into the destination tree (`Photos`/`Videos` → `Year` → `Month`). Optional renaming applies the date-based format.
- **Option 3:** File creation and modification dates align with the metadata. A summary indicates processed counts and issues.
- **Option 4:** All selected files share the specified timestamp. Progress messages confirm each update.
- **Option 5:** A report lists files where the filename date differs from metadata so you can fix them manually or re-run other operations.

## Safety Checklist

- Keep backups or work on copies when trying new combinations of options.
- Review log output for warning or error messages after each run.
- Do not enable “delete originals” on the first pass; validate results first.
- Iterate on small subsets until the output is exactly what you expect.

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
