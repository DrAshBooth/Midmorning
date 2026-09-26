import Content
import Foundation

// scripts/content-signoff-list: prints every catalogue id, sorted, one per
// line: the cards, the bundle strings and the keys of Localizable.xcstrings
// that signed-catalogue-keys.json names (ruling r13-01). "Catalogue rules"
// states "A script MUST generate the README sign-off list from the
// catalogue ids. The team MUST NOT write the list by hand." The "Sign-off
// list" section of Packages/Content/SIGNOFF.md holds this tool's output,
// inside a fenced code block.

do {
    let bundle = try BundleLoader.loadSource()
    for id in bundle.signOffIds { print(id) }
} catch {
    FileHandle.standardError.write(Data("content-signoff-list: \(error)\n".utf8))
    exit(1)
}
