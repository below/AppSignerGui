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
    
    func promptForWorkingDirectoryPermission() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Choose your Apk"
        openPanel.prompt = "Choose"
        openPanel.allowedFileTypes = ["apk"]
        openPanel.allowsOtherFileTypes = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        _ = openPanel.runModal()
        print(openPanel.urls) // this contains the chosen folder
        return openPanel.urls.first!.path
    }
    
    func aapt(tool: URL, arguments: [String], completionHandler: @escaping (Int32, Data) -> Void) throws {
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
    
    @State var packageName: String = ""
    @State var appName: String = ""
    @State var keyStore: String = ""
    @State var keyPass: String = ""
    @State var signingScheme: String = ""

    var body: some View {
        
        VStack {
            Text("Select the Apk you want to sign. Then fill in the missing data, after that you can start the signing process.")
                .font(.largeTitle)
                .padding()
            HStack {
                Button(action: {
                                        try! aapt(tool: Bundle.main.url(forResource: "android-11/aapt", withExtension: nil)!, arguments: ["dump", "badging", promptForWorkingDirectoryPermission()!]) { (status, outputData) in
                                            let output = String(data: outputData, encoding: .utf8) ?? ""
                                            print("done, status: \(status), output: \(output)")
                                            
                                             
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
                                            print("Result: \(result)")
                                            
                                            if result.contains(["application-debuggable"]) {
                                                let packageName = PackageName(context: viewContext)
                                                packageName.package = result[0].reduce("", +)
                                                let versionCode = result[1].reduce("", +)
                                                let versionName = result[2].reduce("", +)
                                                let debug = result[3].reduce("", +)
                                                print(packageName, versionCode, versionName, debug)
                                                
                                                do {
                                                    try viewContext.save()
                                                } catch {
                                                    // Replace this implementation with code to handle the error appropriately.
                                                    
                                                    let nsError = error as NSError
                                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                                }
                                            }
                                            else{
                                                let packageName = PackageName(context: viewContext)
                                                packageName.package = result[0].reduce("", +)
                                                let versionCode = result[1].reduce("", +)
                                                let versionName = result[2].reduce("", +)
                                                print(packageName, versionCode, versionName)
                                                
                                                do {
                                                    try viewContext.save()
                                                } catch {
                                                    // Replace this implementation with code to handle the error appropriately.
                                                    
                                                    let nsError = error as NSError
                                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                                }
                                            }
                                        }
                }) {
                    Text("Read Apk")
                }
                .padding()
                
                TextField("packageName", text: $packageName)
                    .padding()
                TextField("appName", text: $appName)
                    .padding()
                TextField("KeyStore", text: $keyStore)
                    .padding()
                TextField("KeyPass", text: $keyPass)
                    .padding()
                TextField("SigningScheme", text: $signingScheme)
                    .padding(.trailing)
                
                Button(action: {
                    
                }){
                    Text("Sign Apk")
                }
                .padding()
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

                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }

    private func addItem() {
        withAnimation {
            let newPackageName = PackageName(context: viewContext)
            newPackageName.package = "newAppApkPackageName"

            let newAppName = AppName(context: viewContext)
            newAppName.name = "newAppApkAppName"
            newAppName.packageName = newPackageName

            let newKeyPass = KeyPass(context: viewContext)
            newKeyPass.pass = "secret"
            newKeyPass.packageName = newPackageName

            let newKeyStore = KeyStore(context: viewContext)
            newKeyStore.link = "/user/Desktop"
            newKeyStore.packageName = newPackageName

            let newSigningScheme = SigningScheme(context: viewContext)
            newSigningScheme.value = 2
            newSigningScheme.packageName = newPackageName

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }


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
