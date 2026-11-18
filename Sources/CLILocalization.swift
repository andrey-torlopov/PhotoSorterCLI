import Foundation

/// Terminal language is a per-invocation value; no process-wide locale mutation or persisted setting.
enum CLILanguage: String, CaseIterable, Sendable {
    case en, ru

    static func detected(environment: [String: String], preferredLanguages: [String]) -> Self {
        for key in ["LC_ALL", "LC_MESSAGES", "LANG"] {
            if let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                // An explicit unsupported POSIX locale (including C/POSIX) uses English,
                // rather than unexpectedly falling through to a lower-precedence variable.
                return matching(value) ?? .en
            }
        }
        return preferredLanguages.compactMap(matching).first ?? .en
    }

    private static func matching(_ value: String) -> Self? {
        let code = value.lowercased().split(whereSeparator: { "_- .@".contains($0) }).first.map(String.init)
        return code.flatMap(Self.init(rawValue:))
    }
}

/// Embedded strings keep the installed CLI a standalone executable, with no resource bundle.
struct CLILocalization: Sendable {
    let language: CLILanguage

    func callAsFunction(_ message: CLIMessage, _ arguments: CVarArg...) -> String {
        let format = language == .ru ? message.translations.ru : message.translations.en
        return String(format: format, locale: Locale(identifier: language == .ru ? "ru_RU" : "en_US_POSIX"), arguments: arguments)
    }

    func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .ru ? "ru_RU" : "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum CLIMessage: CaseIterable {
    case usage
    case menu
    case languageMenu
    case unsupportedArguments
    case invalidLanguage
    case choice
    case invalidChoice
    case operationFailed
    case yesDefault
    case noDefault
    case invalidAnswer
    case invalidPath
    case dateNotParsed
    case dateFormatPrompt
    case invalidDateFormat
    case conversionFolder
    case conversionDelete
    case conversionFinished
    case folderPrompt
    case forceDatePrompt
    case dateFinished
    case sortingFinished
    case processedTotal
    case errorsTotal
    case sourceFolderPrompt
    case destinationFolderPrompt
    case renamePrompt
    case dateExplanation
    case fixMetadataPrompt
    case foldersExplanation
    case createFoldersPrompt
    case deletePrompt
    case confirmSettings
    case sourceFolderSetting
    case destinationFolderSetting
    case renameSetting
    case fixMetadataSetting
    case foldersSetting
    case deleteSetting
    case forceDateSetting
    case customDateSetting
    case yes
    case no
    case notSet
    case startPrompt
    case customDateSkippedMetadata
    case customDatePrompt
    case customDateSkipped
    case customDateInput
    case dateEntered
    case confirmDatePrompt
    case dateConfirmed
    case dateRejected
    case cancelled
    case accessDenied
    case accessDeniedPath
    case converted
    case convertingFile
    case originalDeleted
    case folderUnavailable
    case folderUnavailablePath
    case deletionFailed
    case readingFailed
    case imageCreationFailed
    case imageDestinationFailed
    case heicSaveFailed
    case processedProgress
    case filenameMismatch
    case noDate
    case checkFinished
    case dateUpdateFailed
    case cantFixDate
    case metadataError
    case creationDateFailed
    case creationDateFailedPath
    case sortingStarted
    case folderCreated
    case fileProcessed
    case fileSkipped
    case sortingCount
    case invalidFileDate
    case missingDateComponents
    case moveFailed
    case copyFailed
    case folderCreationFailed
    case systemError

    var translations: (en: String, ru: String) {
        switch self {
        case .usage:
            return ("Usage: photos-sorter-cli [--language ru|en] [--help | --version]\n\nRun without a command to open the interactive menu. Choose 7 to change language.\n  --help, -h          Print help without processing files.\n  --version           Print the installed version without processing files.\n  --language, --lang   Use Russian (ru) or English (en) for this invocation.\n\nWithout --language: LC_ALL > LC_MESSAGES > LANG > system language > English.\nRequires macOS 15.0 or newer. Press Ctrl-D to exit any input dialogue.\nStart with a small set of copies and keep deletion of originals disabled.\nProject: https://github.com/andrey-torlopov/PhotoSorterCLI", "Использование: photos-sorter-cli [--language ru|en] [--help | --version]\n\nЗапуск без команды открывает интерактивное меню. Пункт 7 — выбор языка.\n  --help, -h          Показать справку без обработки файлов.\n  --version           Показать установленную версию без обработки файлов.\n  --language, --lang   Русский (ru) или английский (en) язык для этого запуска.\n\nБез --language: LC_ALL > LC_MESSAGES > LANG > язык системы > английский.\nТребуется macOS 15.0 или новее. Ctrl-D завершает любой диалог ввода.\nНачните с небольшого набора копий и оставьте удаление оригиналов выключенным.\nПроект: https://github.com/andrey-torlopov/PhotoSorterCLI")
        case .menu:
            return ("\nPhotos Sorter CLI v.%@ · Andrey Torlopov\nSelect a command (0 — exit):\n1. Convert DNG to HEIC\n2. Sort files into Photos(Videos)/<Year>/<Month>\n3. Fix dates in files\n4. Set a specific date in files\n5. Check filename dates against internal dates\n6. Convert PNG to HEIC\n7. Language / Язык", "\nPhotos Sorter CLI v.%@ · Андрей Торлопов\nВыберите команду (0 — выход):\n1. Конвертировать DNG в HEIC\n2. Разложить файлы по Photos(Videos)/<Год>/<Месяц>\n3. Исправить даты файлов\n4. Установить заданную дату файлов\n5. Сверить даты в именах файлов с метаданными\n6. Конвертировать PNG в HEIC\n7. Язык / Language")
        case .languageMenu:
            return ("\nLanguage / Язык\n1. English\n2. Русский\n0. Back\nApplies until you exit the utility.", "\nЯзык / Language\n1. English\n2. Русский\n0. Назад\nДействует до завершения работы утилиты.")
        case .unsupportedArguments:
            return ("Unsupported arguments. Use photos-sorter-cli --help.", "Недопустимые аргументы. Используйте photos-sorter-cli --help.")
        case .invalidLanguage:
            return ("Use --language ru or --language en once, followed by an optional --help or --version.", "Укажите --language ru или --language en один раз; затем можно добавить --help или --version.")
        case .choice:
            return ("Your choice", "Ваш выбор")
        case .invalidChoice:
            return ("Invalid input. Please try again.", "Недопустимый ввод. Попробуйте ещё раз.")
        case .operationFailed:
            return ("The operation could not complete. Check the preceding diagnostics.", "Операция не завершена. Проверьте сообщения об ошибках выше.")
        case .yesDefault:
            return ("(Y/n)", "(Д/н; y/n)")
        case .noDefault:
            return ("(y/N)", "(д/Н; y/n)")
        case .invalidAnswer:
            return ("Invalid input. Please enter Y or n.", "Недопустимый ответ. Введите д/да или н/нет (также y/n).")
        case .invalidPath:
            return ("Invalid path. Please try again.", "Недопустимый путь. Попробуйте ещё раз.")
        case .dateNotParsed:
            return ("Could not parse this date.", "Не удалось распознать дату.")
        case .dateFormatPrompt:
            return ("Enter the date format (e.g., dd.MM.yyyy HH:mm)", "Введите формат даты (например, dd.MM.yyyy HH:mm)")
        case .invalidDateFormat:
            return ("Invalid date or format. Please try again.", "Неверная дата или формат. Попробуйте ещё раз.")
        case .conversionFolder:
            return ("Input path to %@ folder", "Введите путь к папке с файлами %@")
        case .conversionDelete:
            return ("Remove original %@ files?", "Удалить исходные файлы %@?")
        case .conversionFinished:
            return ("Converting finished. Time: %.2f seconds.", "Конвертация завершена. Время: %.2f с.")
        case .folderPrompt:
            return ("Enter the folder path", "Введите путь к папке")
        case .forceDatePrompt:
            return ("Enter the date you want to set for the files", "Введите дату, которую нужно установить для файлов")
        case .dateFinished:
            return ("✅ Date fixing completed. Time: %.2f seconds.", "✅ Изменение дат завершено. Время: %.2f с.")
        case .sortingFinished:
            return ("🏁 Sorting completed. Time elapsed: %.2f seconds.", "🏁 Сортировка завершена. Время: %.2f с.")
        case .processedTotal:
            return ("📊 Total files processed: %ld", "📊 Всего обработано файлов: %ld")
        case .errorsTotal:
            return ("❌ Total errors: %ld", "❌ Всего ошибок: %ld")
        case .sourceFolderPrompt:
            return ("Enter the source folder path (folder must exist)", "Введите путь к исходной папке (папка должна существовать)")
        case .destinationFolderPrompt:
            return ("Enter the destination folder path (folder must exist)", "Введите путь к целевой папке (папка должна существовать)")
        case .renamePrompt:
            return ("Rename files to date format (e.g., 2024-01-02--12-31)? (Recommended)", "Переименовать файлы по дате (например, 2024-01-02--12-31)? (Рекомендуется)")
        case .dateExplanation:
            return ("ℹ️ You can either automatically fix creation/modification dates or specify a custom date manually.", "ℹ️ Даты создания и изменения можно исправить автоматически или задать вручную.")
        case .fixMetadataPrompt:
            return ("Fix file metadata based on content creation date? (Recommended)", "Исправить метаданные по дате создания содержимого? (Рекомендуется)")
        case .foldersExplanation:
            return ("ℹ️ You can choose whether to create a folder hierarchy (Year-Month) and separate photos/videos.", "ℹ️ Можно создать папки по году и месяцу и разделить фото и видео.")
        case .createFoldersPrompt:
            return ("Create a folder structure in the destination folder? (Recommended)", "Создать структуру папок в целевой папке? (Рекомендуется)")
        case .deletePrompt:
            return ("Remove original files after processing?", "Удалить оригиналы после обработки?")
        case .confirmSettings:
            return ("Confirm the following settings:", "Подтвердите настройки:")
        case .sourceFolderSetting:
            return ("✅ Source folder: %@", "✅ Исходная папка: %@")
        case .destinationFolderSetting:
            return ("✅ Destination folder: %@", "✅ Целевая папка: %@")
        case .renameSetting:
            return ("Rename files to date format: %@", "Переименовать файлы по дате: %@")
        case .fixMetadataSetting:
            return ("Fix metadata (creation/modification dates): %@", "Исправить метаданные (даты создания/изменения): %@")
        case .foldersSetting:
            return ("Create folder structure in destination: %@", "Создать структуру папок: %@")
        case .deleteSetting:
            return ("Remove original files after processing: %@", "Удалить оригиналы после обработки: %@")
        case .forceDateSetting:
            return ("Force custom date: %@", "Установить заданную дату: %@")
        case .customDateSetting:
            return ("Custom date: %@", "Заданная дата: %@")
        case .yes:
            return ("YES", "ДА")
        case .no:
            return ("NO", "НЕТ")
        case .notSet:
            return ("Not set", "Не задана")
        case .startPrompt:
            return ("Start with these settings?", "Начать с этими настройками?")
        case .customDateSkippedMetadata:
            return ("ℹ️ Metadata fixing is enabled. Skipping custom date selection.", "ℹ️ Включено исправление метаданных. Выбор заданной даты пропущен.")
        case .customDatePrompt:
            return ("Would you like to set a custom creation/modification date for all files?", "Установить заданную дату создания/изменения для всех файлов?")
        case .customDateSkipped:
            return ("ℹ️ Custom date selection was skipped.", "ℹ️ Выбор заданной даты пропущен.")
        case .customDateInput:
            return ("Please specify the date in the format dd.MM.yyyy HH:mm", "Введите дату в формате dd.MM.yyyy HH:mm")
        case .dateEntered:
            return ("You entered the date: %@", "Введена дата: %@")
        case .confirmDatePrompt:
            return ("Do you confirm this date?", "Подтверждаете эту дату?")
        case .dateConfirmed:
            return ("✅ Custom date confirmed: %@.", "✅ Заданная дата подтверждена: %@.")
        case .dateRejected:
            return ("❌ Custom date entry was rejected. Prompting again...", "❌ Дата отклонена. Повторите ввод.")
        case .cancelled:
            return ("❌ Operation cancelled.", "❌ Операция отменена.")
        case .accessDenied:
            return ("❌ Unable to access the folder. Check its permissions.", "❌ Нет доступа к папке. Проверьте права доступа.")
        case .accessDeniedPath:
            return ("❌ Unable to access folder: %@. Check its permissions.", "❌ Нет доступа к папке: %@. Проверьте права доступа.")
        case .converted:
            return ("✅ File successfully converted and saved.", "✅ Файл успешно конвертирован и сохранён.")
        case .convertingFile:
            return ("⚙️ Processing file: %@.", "⚙️ Обрабатывается файл: %@.")
        case .originalDeleted:
            return ("✅ Original file has been deleted.", "✅ Исходный файл удалён.")
        case .folderUnavailable:
            return ("❌ Unable to open the specified folder path.", "❌ Не удалось открыть указанную папку.")
        case .folderUnavailablePath:
            return ("❌ Could not open folder: %@.", "❌ Не удалось открыть папку: %@.")
        case .deletionFailed:
            return ("❌ Could not delete the original file. The converted file was saved; check access permissions.", "❌ Не удалось удалить оригинал. Конвертированный файл сохранён; проверьте права доступа.")
        case .readingFailed:
            return ("❌ Error reading the file. Please check if the file exists and is accessible.", "❌ Не удалось прочитать файл. Проверьте его наличие и доступность.")
        case .imageCreationFailed:
            return ("❌ Could not decode the image. Check that the file is valid and its format is supported.", "❌ Не удалось декодировать изображение. Проверьте целостность файла и поддержку формата.")
        case .imageDestinationFailed:
            return ("❌ Could not create the HEIC output. Check the destination and available space.", "❌ Не удалось создать выходной HEIC. Проверьте целевую папку и свободное место.")
        case .heicSaveFailed:
            return ("❌ Could not save HEIC. Check for an existing output, available space and write permissions; the original is preserved.", "❌ Не удалось сохранить HEIC. Проверьте наличие одноимённого файла, свободное место и права записи; оригинал сохранён.")
        case .processedProgress:
            return ("📊 Files processed so far: %ld", "📊 Обработано файлов: %ld")
        case .filenameMismatch:
            return ("❌ File name does not match date for file %@. Expected date: %@", "❌ Дата в имени файла %@ не совпадает с метаданными. Ожидаемая дата: %@")
        case .noDate:
            return ("no date", "дата отсутствует")
        case .checkFinished:
            return ("✅ All files processed. Total files: %ld", "✅ Проверка завершена. Всего файлов: %ld")
        case .dateUpdateFailed:
            return ("❌ Failed to update date for %@. Check file permissions and metadata support.", "❌ Не удалось обновить дату файла %@. Проверьте права доступа и поддержку метаданных.")
        case .cantFixDate:
            return ("❌ Can't fix date for %@. Check that valid dates are present in the metadata and the file is writable.", "❌ Не удалось исправить дату файла %@. Проверьте даты в метаданных и возможность записи.")
        case .metadataError:
            return ("❌ Metadata error for %@. Check file integrity and access permissions.", "❌ Ошибка метаданных файла %@. Проверьте целостность файла и права доступа.")
        case .creationDateFailed:
            return ("❌ Could not set the creation date. Check write permissions and metadata support.", "❌ Не удалось установить дату создания. Проверьте права записи и поддержку метаданных.")
        case .creationDateFailedPath:
            return ("❌ Could not set creation date for %@. Check write permissions and metadata support.", "❌ Не удалось установить дату создания файла %@. Проверьте права записи и поддержку метаданных.")
        case .sortingStarted:
            return ("🚀 Sorting started...", "🚀 Сортировка началась...")
        case .folderCreated:
            return ("📂 Folder created: %@", "📂 Создана папка: %@")
        case .fileProcessed:
            return ("✅ File processed: %@ → %@", "✅ Файл обработан: %@ → %@")
        case .fileSkipped:
            return ("⏭️ File skipped (already dated): %@", "⏭️ Файл пропущен (дата уже задана): %@")
        case .sortingCount:
            return ("🏁 Sorting completed. Files processed: %ld", "🏁 Сортировка завершена. Обработано файлов: %ld")
        case .invalidFileDate:
            return ("❌ Invalid date in file: %@ — %@", "❌ Неверная дата в файле: %@ — %@")
        case .missingDateComponents:
            return ("❌ Missing date components: %@", "❌ Не хватает компонентов даты: %@")
        case .moveFailed:
            return ("❌ Move failed: %@ → %@. Check access permissions, available space and existing destination files.", "❌ Не удалось переместить файл: %@ → %@. Проверьте права доступа, свободное место и наличие файла в целевой папке.")
        case .copyFailed:
            return ("❌ Copy failed: %@ → %@. Check access permissions, available space and existing destination files.", "❌ Не удалось скопировать файл: %@ → %@. Проверьте права доступа, свободное место и наличие файла в целевой папке.")
        case .folderCreationFailed:
            return ("❌ Could not create folder: %@.", "❌ Не удалось создать папку: %@.")
        case .systemError:
            return ("❌ System operation failed (%@, code %@). Check file access and available space.", "❌ Системная операция не выполнена (%@, код %@). Проверьте доступ к файлам и свободное место.")
        }
    }
}
