#!/usr/bin/env python3
"""Run real CLI operations on generated disposable images, never on a user library.

The Swift PNG fixture generator is compiled/interpreted once. An optional genuine DNG
fixture exercises the RAW path; a renamed PNG is rejected by its decoded format.
"""
import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=pathlib.Path)
    parser.add_argument("--dng-fixture", type=pathlib.Path)
    parser.add_argument("--language", choices=["en", "ru"], default="en")
    arguments = parser.parse_args()
    executable = arguments.executable.resolve(strict=True)
    russian = arguments.language == "ru"
    yes, no = ("да", "нет") if russian else ("y", "n")
    translated = {
        "Total files processed: 1": "Всего обработано файлов: 1",
        "Date fixing completed": "Изменение дат завершено",
        "File name does not match date": "не совпадает с метаданными",
        "successfully converted and saved": "успешно конвертирован и сохранён",
        "Error reading the file": "Не удалось прочитать файл",
    }

    def image_properties(path):
        decoded = subprocess.run(["sips", "-g", "format", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
                                 check=True, capture_output=True, text=True)
        return dict(line.strip().split(": ", 1) for line in decoded.stdout.splitlines()[1:] if ": " in line)

    dng_fixture = arguments.dng_fixture.resolve(strict=True) if arguments.dng_fixture else None
    if dng_fixture:
        dng_properties = image_properties(dng_fixture)
        assert dng_properties["format"] == "dng", "The optional fixture must decode as DNG"
        assert int(dng_properties["pixelWidth"]) > 0 and int(dng_properties["pixelHeight"]) > 0
    with tempfile.TemporaryDirectory(prefix="CLI фото fixtures ") as directory:
        root = pathlib.Path(directory)
        fixture = root / "fixture.png"
        generator = pathlib.Path(__file__).with_name("make_fixture.swift")
        generated = subprocess.run(["swift", str(generator), str(fixture)], check=True,
                                   capture_output=True, text=True, timeout=60)
        dates = json.loads(generated.stdout)
        original_hash = digest(fixture)

        def folder(name):
            path = root / name
            path.mkdir()
            return path

        def image_in(target):
            file = target / "2030-01-01--00-00 Проверка фото.png"
            shutil.copy2(fixture, file)
            return file

        def run(label, lines, expected, allow_file_error=False):
            result = subprocess.run([str(executable), "--language", arguments.language], input="\n".join(map(str, lines)) + "\n",
                                    capture_output=True, text=True, timeout=30)
            text = result.stdout + result.stderr
            print(f"SCENARIO: {label}\n{text}")
            assert result.returncode == 0, (label, result.returncode)
            expected = translated.get(expected, expected) if russian else expected
            assert expected in text, (label, expected)
            assert "Unable to access security-scoped resource" not in text, label
            if not allow_file_error:
                assert "Critical error" not in text, label
                assert "Can't fix date" not in text, label
                assert "Metadata error" not in text, label
                assert "Не удалось" not in text, label
                assert "Ошибка метаданных" not in text, label
            if russian:
                for english in ["Select a command", "Your choice", "Enter the", "Invalid input", "Converting finished", "Files processed", "Error reading"]:
                    assert english not in text, (label, "English UI leak", english)
            return text

        for delete in (False, True):
            source_dir = folder(f"sort input {delete}")
            target_dir = folder(f"sort output {delete}")
            source = image_in(source_dir)
            run(f"sort {'move' if delete else 'copy'}", ["2", source_dir, target_dir,
                yes, no, yes, no, yes if delete else "", yes, "0"], "Total files processed: 1")
            outputs = [path for path in target_dir.rglob("*") if path.is_file()]
            assert len(outputs) == 1
            assert digest(outputs[0]) == original_hash
            assert source.exists() is (not delete)
            if not delete:
                assert digest(source) == original_hash
            print(f"PASS: sort delete={delete}; output={outputs[0].relative_to(target_dir)}; SHA256={original_hash}")

        date_dir = folder("date inputs")
        source = image_in(date_dir)
        run("repair dates", ["3", date_dir, "0"], "Date fixing completed")
        assert abs(source.stat().st_mtime - dates["metadataTimestamp"]) < 1
        assert digest(source) == original_hash
        run("force date", ["4", date_dir, "2020-01-02 03-04", "0"], "Date fixing completed")
        assert abs(source.stat().st_mtime - dates["forcedTimestamp"]) < 1
        assert digest(source) == original_hash
        run("check filename dates", ["5", date_dir, "0"], "File name does not match date")
        assert digest(source) == original_hash
        print(f"PASS: fix/force/check; SHA256={original_hash}")

        for delete in (False, True):
            conversion_dir = folder(f"PNG conversion {delete}")
            source = image_in(conversion_dir)
            run(f"PNG to HEIC delete={delete}", ["6", conversion_dir, yes if delete else "", "0"],
                "successfully converted and saved")
            outputs = list(conversion_dir.glob("*.heic"))
            assert len(outputs) == 1 and outputs[0].stat().st_size > 0
            decoded = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(outputs[0])],
                                     check=True, capture_output=True, text=True)
            assert "pixelWidth: 32" in decoded.stdout and "pixelHeight: 32" in decoded.stdout
            assert source.exists() is (not delete)
            if not delete:
                assert digest(source) == original_hash
            print(f"PASS: PNG conversion delete={delete}; decoded=32x32; originalExists={source.exists()}")

        if dng_fixture:
            for delete in (False, True):
                conversion_dir = folder(f"DNG conversion {delete}")
                source = conversion_dir / "Линейный RAW.dng"
                shutil.copy2(dng_fixture, source)
                source_hash = digest(source)
                run(f"DNG to HEIC delete={delete}", ["1", conversion_dir, yes if delete else "", "0"],
                    "successfully converted and saved")
                outputs = list(conversion_dir.glob("*.heic"))
                assert len(outputs) == 1 and outputs[0].stat().st_size > 0
                properties = image_properties(outputs[0])
                assert properties["format"] == "heic"
                assert properties["pixelWidth"] == dng_properties["pixelWidth"]
                assert properties["pixelHeight"] == dng_properties["pixelHeight"]
                assert source.exists() is (not delete)
                if not delete:
                    assert digest(source) == source_hash
                print(f"PASS: DNG conversion delete={delete}; decoded={properties['pixelWidth']}x{properties['pixelHeight']}; originalExists={source.exists()}")

        for choice, extension in (("1", "dng"), ("6", "png")):
            corrupt_dir = folder(f"corrupt {extension}")
            corrupt = corrupt_dir / f"corrupt.{extension}"
            corrupt.write_bytes(b"deliberately invalid image fixture")
            before = digest(corrupt)
            run(f"corrupt {extension} with deletion requested", [choice, corrupt_dir, yes, "0"],
                "Error reading the file", allow_file_error=True)
            assert corrupt.is_file() and digest(corrupt) == before
            assert not list(corrupt_dir.glob("*.heic"))
            print(f"PASS: corrupt {extension} preserves source; no HEIC output")
        print("FIXTURE RESULT: sorting copy/move, date repair/force/check, PNG conversion keep/delete, corrupt PNG/DNG passed")
        if dng_fixture:
            print("DNG FIXTURE RESULT: keep/delete passed; support for other RAW encodings or camera models is not established")
        else:
            print("NOT VERIFIED: successful DNG conversion; no valid DNG fixture supplied")


if __name__ == "__main__":
    main()
