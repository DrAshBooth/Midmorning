import Content
import Foundation

// scripts/content-signoff-list: prints every catalogue id, sorted, one per
// line. "Catalogue rules" states "A script MUST generate the README sign-
// off list from the catalogue ids. The team MUST NOT write the list by
// hand." The build change README's "Sign-off list" section holds this
// tool's output, inside a fenced code block.

do {
    let bundle = try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory)
    let ids = (bundle.cards.map(\.id) + bundle.strings.map(\.id)).sorted()
    for id in ids { print(id) }
} catch {
    FileHandle.standardError.write(Data("content-signoff-list: \(error)\n".utf8))
    exit(1)
}
