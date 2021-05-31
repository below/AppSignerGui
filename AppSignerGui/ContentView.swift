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

    var body: some View {
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
