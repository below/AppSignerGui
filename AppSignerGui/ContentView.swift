//
//  ContentView.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
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
    
    @State var apkString = "Last working Directory gets here"

    var body: some View {
        
        VStack {
            Text("GO")
                .font(.largeTitle)
                .padding()
            HStack {
                TextField("Message", text: $apkString)
                    .padding(.leading)
                Button(action: {
                                        try! aapt(tool: Bundle.main.url(forResource: "android-11/aapt", withExtension: nil)!, arguments: ["dump", "badging", promptForWorkingDirectoryPermission()!]) { (status, outputData) in
                                            let output = String(data: outputData, encoding: .utf8) ?? ""
                                            print("done, status: \(status), output: \(output)")
                                        }
                }) {
                    Text("Sign")
                }
                .padding(.trailing)
        }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        
            List {
                ForEach(items) { item in
                    Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                viewContext.delete(item)

                                do {
                                    try viewContext.save()
                                } catch {
                                    let nsError = error as NSError
                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                            }, label: {
                                Text("Delete")
                            })
                        }))
                }
                .onDelete(perform: deleteItems)
                
                ForEach(packageNames) { item in
                    Text("PackageName: \(item.package!)")
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
                    Text("AppName: \(item.name!)")
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
                    Text("KeyPass: \(item.pass!)")
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
                    Text("KeyStore: \(item.link!)")
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
                    Text("SigningScheme: \(item.value)")
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
            
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.packageName = newPackageName

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
            offsets.map { items[$0] }.forEach(viewContext.delete)
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
