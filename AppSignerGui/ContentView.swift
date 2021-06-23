//
//  ContentView.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
import Foundation
import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PackageName.package, ascending: true)],
        animation: .default)
    private var packageNames: FetchedResults<PackageName>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AppName.name, ascending: true)],
        animation: .default)
    private var appNames: FetchedResults<AppName>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \KeyPass.pass, ascending: true)],
        animation: .default)
    private var keyPasses: FetchedResults<KeyPass>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \KeyStore.link, ascending: true)],
        animation: .default)
    private var keyStores: FetchedResults<KeyStore>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SigningScheme.value, ascending: true)],
        animation: .default)
    private var signingSchemes: FetchedResults<SigningScheme>
    
    func promptForWorkingApkPermission() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Select your Apk"
        openPanel.prompt = "Select Apk"
        openPanel.allowedFileTypes = ["apk"]
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        //openPanel.cancel()

        _ = openPanel.runModal()
        //print(openPanel.urls.first!.path)
        return openPanel.urls.first!.path
    }
    
    func promptForWorkingAabPermission() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Select your Aab"
        openPanel.prompt = "Select Aab"
        openPanel.allowedFileTypes = ["aab"]
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        //openPanel.cancel()

        _ = openPanel.runModal()
        //print(openPanel.urls.first!.path)
        return openPanel.urls.first!.path
    }
    
    func promptForWorkingDirectoryPermission() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Select your Directory"
        openPanel.prompt = "Select Directory"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true

        _ = openPanel.runModal()
        return openPanel.urls.first!.path
    }
    
//    func promptForSavePermissoin () -> String? {
//        let savePanel = NSSavePanel()
//        savePanel.message = "Select file to save"
//        savePanel.prompt = "Save"
//        savePanel.allowedFileTypes = ["apk"]
//        savePanel.allowsOtherFileTypes = true
//        savePanel.canSelectHiddenExtension = true
//        //savePanel.cancel() =
//        savePanel.canSelectHiddenExtension = true
//
//        _ = savePanel.runModal()
//        print(savePanel.url!.path)
//        return savePanel.url!.path
//    }
    
    func androidTools(tool: URL, arguments: [String], completionHandler: @escaping (Int32, Data) -> Void) throws {
        let group = DispatchGroup()
        let pipe = Pipe()
        var standardOutData = Data()

        group.enter()
        let proc = Process()
        proc.executableURL = tool
        proc.arguments = arguments
        proc.standardOutput = pipe.fileHandleForWriting
        proc.terminationHandler = { _ in
            proc.terminationHandler = nil
            group.leave()
        }

        group.enter()
        DispatchQueue.global().async {
            // Doing long-running synchronous I/O on a global concurrent queue block
            // is less than ideal, but I’ve convinced myself that it’s acceptable
            // given the target ‘market’ for this code.

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            pipe.fileHandleForReading.closeFile()
            DispatchQueue.main.async {
                standardOutData = data
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completionHandler(proc.terminationStatus, standardOutData)
        }

        try proc.run()

        // We have to close our reference to the write side of the pipe so that the
        // termination of the child process triggers EOF on the read side.

        pipe.fileHandleForWriting.closeFile()
    }
    
    func aaptProcess () {
        
        let apkDirectory = promptForWorkingApkPermission()!
        
        try! androidTools(tool: Bundle.main.url(forResource: "android-11/aapt", withExtension: nil)!, arguments: ["dump", "badging", apkDirectory]) { (status, outputData) in
            let output = String(data: outputData, encoding: .utf8) ?? ""
            //print("done, status: \(status), output: \(output)")
             
            let pattern = #"package: name='(.*?)\'|versionCode='(.*?)\'|versionName='(.*?)\'|W*(application-debuggable)\W*"#
            let regex = try! NSRegularExpression(pattern: pattern)
            let testString = output
            let stringRange = NSRange(location: 0, length: testString.utf16.count)
            let matches = regex.matches(in: testString, range: stringRange)
            var result: [[String]] = []
            for match in matches {
              var groups: [String] = []
              for rangeIndex in 1 ..< match.numberOfRanges {
                let range: NSRange = match.range(at: rangeIndex)
                guard range.location != NSNotFound, range.length != 0 else {
                    continue
                }
                groups.append((testString as NSString).substring(with: match.range(at: rangeIndex)))
              }
              if !groups.isEmpty {
                result.append(groups)
              }
            }
            //print("Result: \(result)")
            
            if result.contains(["application-debuggable"]) {
                let packageName = PackageName(context: viewContext)
                packageName.package = result[0].reduce("", +)
                self.packageName = result[0].reduce("", +)
                
                packageNames.forEach { item in
                    print("was in for loop: \(item)")
                    if item == packageName {
                        print("was in if loop")
                        let appName = AppName(context: viewContext)
                        appName.packageName = packageName
                        appName.name = $appName.wrappedValue
                    }
                }
                
                self.versionCode = result[1].reduce("", +)
                self.versionName = result[2].reduce("", +)
                self.debugOption = "debug"
                
                do {
                    viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                    try viewContext.save()
                    //print("check change: \(packageName)")
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
            else{
                // checking database for existing packabgeName in PackageNames
                // if exist load data with relations data
                let packageName = PackageName(context: viewContext)
                packageName.package = result[0].reduce("", +)
                self.packageName = result[0].reduce("", +)
                
                packageNames.forEach { item in
                    print("was in for loop: \(item)")
                    print("Is item.package: \(item.package!)")
                    print("Is self.package: \(packageName)")
                    if item.package! == self.packageName {
                        print("was in if loop")
                        
                        
                    }
                }
                
                self.versionCode = result[1].reduce("", +)
                self.versionName = result[2].reduce("", +)
                self.debugOption = "release"
                
                do {
                    viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
    func signPackageProcess () {
        let packageName = PackageName(context: viewContext)
        packageName.package = $packageName.wrappedValue
        
        let appName = AppName(context: viewContext)
        appName.name = $appName.wrappedValue
        appName.packageName = packageName

        let keyStore = KeyStore(context: viewContext)
        keyStore.link = $keyStore.wrappedValue
        keyStore.packageName = packageName
        
        let keyPass = KeyPass(context: viewContext)
        keyPass.pass = $keyPass.wrappedValue
        keyPass.packageName = packageName

        let signingScheme = SigningScheme(context: viewContext)
        signingScheme.value = $signingScheme.wrappedValue
        signingScheme.packageName = packageName

        do {
            viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        let apkLocation = promptForWorkingAabPermission()!
        let apkLocationUrl = URL(string: apkLocation)
        let apkLocationUrlName = apkLocationUrl!.deletingLastPathComponent()
        let apkLocationString = apkLocationUrlName.absoluteString
            
        let apkNameSigned = "\(apkLocationString)/\($appName.wrappedValue)_\($versionName.wrappedValue)_\($versionCode.wrappedValue)_\($debugOption.wrappedValue)_signed.aab"
        
        let keyPassCommand = "\(apkLocationString)\($keyPass.wrappedValue)"
        let keyStoreCommand = "\(apkLocationString)\($keyStore.wrappedValue)"
        
        try! androidTools(tool: URL(fileURLWithPath: "/usr/bin/jarsigner", relativeTo: nil), arguments: ["-verbose", "-sigalg", "SHA256withRSA", "-digestalg", "SHA-256", "-keystore", keyStoreCommand, "-storepass", "file:\(keyPassCommand)", apkNameSigned, "magenta?"]) { (status, outputData) in
            let outputJarsigner = String(data: outputData, encoding: .utf8) ?? ""
            print("done, status: \(status), output: \(outputJarsigner)")
        }
        
        let apkNameAlignedSigned = "\(apkLocationString)/\($appName.wrappedValue)_\($versionName.wrappedValue)_\($versionCode.wrappedValue)_\($debugOption.wrappedValue)_aligned_signed.aab"
        
        try! androidTools(tool: Bundle.main.url(forResource: "android-11/zipalign", withExtension: nil)!, arguments: ["-v", "4", apkNameSigned, apkNameAlignedSigned]) { (status, outputData) in
            let outputZipalign = String(data: outputData, encoding: .utf8) ?? ""
            print("done, status: \(status), output: \(outputZipalign)")
        }
    }
    
    func signApkProcess () {
        let packageName = PackageName(context: viewContext)
        packageName.package = $packageName.wrappedValue
        
        let appName = AppName(context: viewContext)
        appName.name = $appName.wrappedValue
        appName.packageName = packageName

        let keyStore = KeyStore(context: viewContext)
        keyStore.link = $keyStore.wrappedValue
        keyStore.packageName = packageName
        
        let keyPass = KeyPass(context: viewContext)
        keyPass.pass = $keyPass.wrappedValue
        keyPass.packageName = packageName

        let signingScheme = SigningScheme(context: viewContext)
        signingScheme.value = $signingScheme.wrappedValue
        signingScheme.packageName = packageName

        do {
            viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        let apkLocation = promptForWorkingApkPermission()!
        let apkLocationUrl = URL(string: apkLocation)
        let apkLocationUrlName = apkLocationUrl!.deletingLastPathComponent()
        let apkLocationString = apkLocationUrlName.absoluteString
            
        let apkNameAligned = "\(apkLocationString)/\($appName.wrappedValue)_\($versionName.wrappedValue)_\($versionCode.wrappedValue)_\($debugOption.wrappedValue)_aligned.apk"
        
        try! androidTools(tool: Bundle.main.url(forResource: "android-11/zipalign", withExtension: nil)!, arguments: ["-v", "-p", "4", apkLocation, apkNameAligned]) { (status, outputData) in
            let outputZipalign = String(data: outputData, encoding: .utf8) ?? ""
            //print("done, status: \(status), output: \(outputZipalign)")
        }

        let apkNameAlignedSigned = "\(apkLocationString)/\($appName.wrappedValue)_\($versionName.wrappedValue)_\($versionCode.wrappedValue)_\($debugOption.wrappedValue)_aligned_signed.apk"

        let signingSchemeInput = $signingScheme.wrappedValue
        
        func signingSchemeBool (signingScheme: Int16) -> (vOne: String, vTwo: String, vThree: String, vFour: String) {
            switch signingScheme {
                case 1:
                    let vOne = "true"
                    let vTwo = "false"
                    let vThree = "false"
                    let vFour = "false"
                    return(vOne, vTwo, vThree, vFour)
            
                case 2:
                    let vOne = "true"
                    let vTwo = "true"
                    let vThree = "false"
                    let vFour = "false"
                    return(vOne, vTwo, vThree, vFour)
                    
                case 3:
                    let vOne = "true"
                    let vTwo = "true"
                    let vThree = "false"
                    let vFour = "false"
                    return(vOne, vTwo, vThree, vFour)
                    
                case 4:
                    let vOne = "true"
                    let vTwo = "true"
                    let vThree = "true"
                    let vFour = "true"
                    return(vOne, vTwo, vThree, vFour)
                    
                default:
                    print("error")
            }
            return("false", "false", "false", "false")
        }

        let schemeAll = signingSchemeBool(signingScheme: signingSchemeInput)
        let keyPassCommand = "\(apkLocationString)\($keyPass.wrappedValue)"
        let keyStoreCommand = "\(apkLocationString)\($keyStore.wrappedValue)"

        try! androidTools(tool: Bundle.main.url(forResource: "android-11/apksigner", withExtension: nil)!, arguments: ["sign", "-v", "--out", apkNameAlignedSigned, "--ks", keyStoreCommand, "--ks-pass", "file:\(keyPassCommand)", "--v1-signing-enabled", schemeAll.vOne, "--v2-signing-enabled", schemeAll.vTwo, "--v3-signing-enabled", schemeAll.vThree, "--v4-signing-enabled", schemeAll.vFour, apkNameAligned]) { (status, outputData) in
            let outputApksigner = String(data: outputData, encoding: .utf8) ?? ""
            print("done, status: \(status), output: \(outputApksigner)")
        }
    }
    
    @State var packageName: String = ""
    @State var appName: String = ""
    @State var keyStore: String = ""
    @State var keyPass: String = ""
    
    @State var isOn: Bool = true
    
    @State var signingScheme: Int16 = 1
    
    @State var versionCode: String = ""
    @State var versionName: String = ""
    @State var debugOption: String = ""

    var body: some View {
                
//        Toggle("My Checkbox Title", isOn: $isOn)
//               .padding()
        
        VStack {
            Text("Select the Apk and fill in the missing data, after that start the signing process.")
                .font(.largeTitle)
                .padding()
            VStack(alignment: .center, spacing: 10) {
                Button(action: self.aaptProcess)
                {
                    Text("Read Apk")
                }
                .padding()
                Text($packageName.wrappedValue)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                TextField("versionCode", text: $versionCode)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                TextField("versionName", text: $versionName)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                TextField("debugOption", text: $debugOption)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                TextField("appName", text: $appName)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                TextField("SigningScheme", value: $signingScheme, formatter: NumberFormatter())
                    .multilineTextAlignment(.center)
                    .padding([.horizontal], 200)
                TextField("KeyStore", text: $keyStore)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                TextField("KeyPass", text: $keyPass)
                    .padding([.horizontal], 200)
                    .multilineTextAlignment(.center)
                
                HStack{
                    Button(action: self.signApkProcess)
                    {
                        Text("Sign Apk")
                    }
                    .padding()
                    
                    Button(action: self.signPackageProcess)
                    {
                        Text("Sign Package")
                    }
                    .padding()
                }
            }
        }
        
            List {
                ForEach(packageNames) { item in
                    Text("PackageNameDatabase: \(item.package!)")
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                    viewContext.delete(item)
                            
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            } , label: {
                                Text("Delete")
                            })
                        }))
                }
                .onDelete(perform: deleteItems)
                
                ForEach(appNames) { item in
                    Text("AppNameDatabase: \(item.name!)")
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                    viewContext.delete(item)
                            
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            } , label: {
                                Text("Delete")
                            })
                        }))
                }
                .onDelete(perform: deleteItems)
                
                ForEach(keyPasses) { item in
                    Text("KeyPassDatabase: \(item.pass!)")
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                    viewContext.delete(item)
                            
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            } , label: {
                                Text("Delete")
                            })
                        }))
                }
                .onDelete(perform: deleteItems)
                
                ForEach(keyStores) { item in
                    Text("KeyStoreDatabase: \(item.link!)")
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                    viewContext.delete(item)
                            
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            } , label: {
                                Text("Delete")
                            })
                        }))
                }
                .onDelete(perform: deleteItems)
                
                ForEach(signingSchemes) { item in
                    Text("SigningSchemeDatabase: \(item.value)")
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                    viewContext.delete(item)
                            
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            } , label: {
                                Text("Delete")
                            })
                        }))
                }
                .onDelete(perform: deleteItems)
                
            }
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif

//                Button(action: addItem) {
//                    Label("Add Item", systemImage: "plus")
//                }
            }
        }
//
//    private func addItem() {
//        withAnimation {
//            let newPackageName = PackageName(context: viewContext)
//            newPackageName.package = "newAppApkPackageName"
//
//            let newAppName = AppName(context: viewContext)
//            newAppName.name = "newAppApkAppName"
//            newAppName.packageName = newPackageName
//
//            let newKeyPass = KeyPass(context: viewContext)
//            newKeyPass.pass = "secret"
//            newKeyPass.packageName = newPackageName
//
//            let newKeyStore = KeyStore(context: viewContext)
//            newKeyStore.link = "/user/Desktop"
//            newKeyStore.packageName = newPackageName
//
//            let newSigningScheme = SigningScheme(context: viewContext)
//            newSigningScheme.value = 2
//            newSigningScheme.packageName = newPackageName
//
//            do {
//                try viewContext.save()
//                viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }


    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { packageNames[$0] }.forEach(viewContext.delete)
            offsets.map { appNames[$0] }.forEach(viewContext.delete)
            offsets.map { keyPasses[$0] }.forEach(viewContext.delete)
            offsets.map { keyStores[$0] }.forEach(viewContext.delete)
            offsets.map { signingSchemes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
