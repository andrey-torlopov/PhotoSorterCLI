import Foundation
import PhotoSorterCore

/// Presentation adapter for the pinned Core enums. Core's opaque reason strings may be
/// system-localized or English, so diagnostics use the typed failure and structured paths.
/// Unknown NSError values retain domain/code without exposing raw descriptions.
struct CoreMessages {
    let text: CLILocalization

    func conversion(_ state: ConversionState) -> String {
        switch state {
        case .unableToAccessSecurityScopedResource(let url): return text(.accessDeniedPath, url.path)
        case .taskCancelled: return text(.cancelled)
        case .successConvertedAndSaved: return text(.converted)
        case .fileFoundStartConverting(let name): return text(.convertingFile, name)
        case .originalFileDeleted: return text(.originalDeleted)
        case .cantOpenFolderPath: return text(.folderUnavailable)
        case .errorWhenDeletingOriginalFile: return text(.deletionFailed)
        case .errorReadingFile: return text(.readingFailed)
        case .errorCreatingCGImage: return text(.imageCreationFailed)
        case .errorCreatingCGImageDestination: return text(.imageDestinationFailed)
        case .errorSavingHEICFile: return text(.heicSaveFailed)
        }
    }

    func check(_ state: CheckFilesProviderState) -> String {
        switch state {
        case .unableToAccessSecurityScopedResource: return text(.accessDenied)
        case .cantOpenFolder: return text(.folderUnavailable)
        case .taskCancelled: return text(.cancelled)
        case .processedFilesCount(let count): return text(.processedProgress, count)
        case .fileNameDoesNotMatchDate(let path, let date):
            return text(.filenameMismatch, path, date ?? text(.noDate))
        case .processedFilesResult(let count): return text(.checkFinished, count)
        }
    }

    func fixDate(_ error: FixDateError) -> String {
        switch error {
        case .securityScopedResourceAccessFailed(let url): return text(.accessDeniedPath, url.path)
        case .cancelled: return text(.cancelled)
        case .folderNotAccessible(let url): return text(.folderUnavailablePath, url.path)
        case .dateUpdateFailed(let url, _): return text(.dateUpdateFailed, url.path)
        case .cantFixDate(let url, _): return text(.cantFixDate, url.path)
        case .metadataError(let path, _): return text(.metadataError, path)
        case .creationDateSetFailed: return text(.creationDateFailed)
        }
    }

    func progress(_ progress: SorterProgress) -> String {
        switch progress {
        case .started: return text(.sortingStarted)
        case .folderCreated(let name): return text(.folderCreated, name)
        case .fileProcessed(let source, let target): return text(.fileProcessed, source, target)
        case .fileSkipped(let path): return text(.fileSkipped, path)
        case .completed(let count): return text(.sortingCount, count)
        }
    }

    func fileError(_ error: FileProcessingError) -> String {
        switch error {
        case .invalidDate(let path, let date): return text(.invalidFileDate, path, date)
        case .missingDateComponents(let path): return text(.missingDateComponents, path)
        case .moveFailed(let source, let destination, _): return text(.moveFailed, source, destination)
        case .copyFailed(let source, let destination, _): return text(.copyFailed, source, destination)
        case .dateUpdateFailed(let url, _): return text(.dateUpdateFailed, url.path)
        case .cantFixDate(let url, _): return text(.cantFixDate, url.path)
        case .metadataError(let path, _): return text(.metadataError, path)
        case .creationDateSetFailed(let path, _): return text(.creationDateFailedPath, path)
        }
    }

    func failure(_ error: Error) -> String {
        if let error = error as? FixDateError { return fixDate(error) }
        if let error = error as? FileProcessingError { return fileError(error) }
        if let error = error as? SorterError {
            switch error {
            case .permissionDenied: return text(.accessDenied)
            case .folderNotAccessible(let path): return text(.folderUnavailablePath, path)
            case .folderCreationFailed(let path): return text(.folderCreationFailed, path)
            case .cancelled: return text(.cancelled)
            }
        }
        let error = error as NSError
        return text(.systemError, error.domain, String(error.code))
    }
}
