//
//  Catalogsandfiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation

class Catalogsandfiles: NamesandPaths {
    func getfullpathsshkeys() -> [String]? {
        if let atpath = fullpathsshkeys {
            do {
                var array = [String]()
                for file in try Folder(path: atpath).files {
                    array.append(file.name)
                }
                return array
            } catch {
                return nil
            }
        }
        return nil
    }

    func getfilesasstringnames() -> [String]? {
        if let atpath = fullpathmacserial {
            do {
                var array = [String]()
                for file in try Folder(path: atpath).files {
                    array.append(file.name)
                }
                return array
            } catch {
                return nil
            }
        }
        return nil
    }

    func getcatalogsasstringnames() -> [String]? {
        if let atpath = fullpathmacserial {
            var array = [String]()
            array.append(SharedReference.shared.defaultprofile)
            do {
                for folders in try Folder(path: atpath).subfolders {
                    array.append(folders.name)
                }
                return array
            } catch {
                return nil
            }
        }
        return nil
    }

    // Create SSH catalog
    // If ssh catalog exists - bail out, no need to create
    func createsshkeyrootpath() {
        if let path = onlysshkeypath {
            let root = Folder.home
            guard root.containsSubfolder(named: path) == false else { return }
            do {
                try root.createSubfolder(at: path)
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }
        }
    }

    override init(_ whichroot: Rootpath?) {
        super.init(whichroot)
    }
}

// swiftlint:enable opening_brace
