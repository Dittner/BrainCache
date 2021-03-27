//
//  FileListVM.swift
//
//
//  Created by Alexander Dittner on 10.02.2021.
//

import Combine
import Foundation

class FileListVM: ObservableObject {
    static var shared: FileListVM = FileListVM()

    @Published var files: [File] = []
    @Published var selectedFolder: Folder?
    @Published var selectedFile: File?

    private var disposeBag: Set<AnyCancellable> = []
    private let context: BrainCacheContext

    init() {
        logInfo(msg: "FileListVM init")
        context = BrainCacheContext.shared

        FolderListVM.shared.$selectedFolder
            .assign(to: \.selectedFolder, on: self)
            .store(in: &disposeBag)

        Publishers.CombineLatest($selectedFolder.compactMap { $0 }, context.filesRepo.subject)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { folder, allFiles in
                self.files = allFiles.filter { $0.folderUID == folder.uid }.sorted(by: { $0.title < $1.title })
                logInfo(msg: "FileListVM received files: \(self.files.count)")
                self.setupLastOpenedFile()
            }.store(in: &disposeBag)

        $selectedFile
            .sink { file in
                self.context.menuAPI.isDeleteFileEnabled = file != nil
                self.context.menuAPI.isMonoFontEnabled = file != nil
                self.context.menuAPI.isMonoFontSelected = file?.useMonoFont ?? false
            }.store(in: &disposeBag)

        context.menuAPI.subject
            .sink { event in
                switch event {
                case .deleteFile:
                    self.deleteFile()
                case let .monoFontSelected(value):
                    if let file = self.selectedFile {
                        file.useMonoFont = value
                    }
                default: break
                }
            }.store(in: &disposeBag)
    }

    private func setupLastOpenedFile() {
        guard let folder = selectedFolder else { deselectFile(); return }

        if let fileUID = folder.selectedFileUID, let file = files.first(where: { $0.uid == fileUID }) {
            selectFile(file)
        } else if files.count > 0 {
            selectFile(files[0])
        } else {
            deselectFile()
        }
    }

    func selectFile(_ f: File) {
        if f.uid != selectedFile?.uid {
            selectedFile = f
            selectedFolder?.selectedFileUID = f.uid
        }
    }

    func deselectFile() {
        if selectedFile != nil {
            selectedFile = nil
        }
    }

    func deleteFile() {
        if let file = selectedFile {
            context.entityRemover.removeFile(file)
        }
    }

    func addColumn() {
        if let listBody = selectedFile?.body as? ListFileBody {
            listBody.addNewColumn()
        }
    }
}
