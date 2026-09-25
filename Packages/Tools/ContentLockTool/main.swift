import Content
import Foundation

// scripts/content-lock <version>: writes Packages/Content/Resources/
// content-lock.json for the bundle as it is on disk. The content spec
// requires "A commit that raises the content version MUST update the lock
// in the same commit"; this tool is how the team does that.

let arguments = CommandLine.arguments
guard arguments.count == 2, let version = Int(arguments[1]) else {
    FileHandle.standardError.write(Data("usage: content-lock <version>\n".utf8))
    exit(64)
}

do {
    let directory = RepositoryRoot.contentResourcesDirectory
    let bundle = try ContentBundle.load(from: directory)
    guard bundle.contentVersion == version else {
        FileHandle.standardError.write(Data(
            "content-lock: manifest.json holds version \(bundle.contentVersion), not \(version). Raise it there first.\n".utf8
        ))
        exit(1)
    }
    let lock = ContentLock(contentVersion: bundle.contentVersion, bundleHash: bundle.bundleHash)
    try lock.write(to: directory)
    print("wrote content-lock.json: version \(lock.contentVersion), hash \(lock.bundleHash)")
} catch {
    FileHandle.standardError.write(Data("content-lock: \(error)\n".utf8))
    exit(1)
}
