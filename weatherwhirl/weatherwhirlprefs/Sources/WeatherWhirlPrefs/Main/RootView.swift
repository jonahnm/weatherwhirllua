import SwiftUI
import PhotosUI
import Comet
import libroot
struct PreferencesView: View {
    @State private var showDebugMenu = false
    @State private var showWallpaperModifier = false
    @StateObject private var preferenceStorage = PreferenceStorage()
    var body: some View {
        Form {
            Section(header: Text("General")) {
                Button("Debug Menu") {
                    withAnimation {
                        self.showDebugMenu = true
                    }
                }
                Button("Wallpaper Modifier") {
                    withAnimation {
                        self.showWallpaperModifier = true
                    }
                }
            }
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenuView(showDebugMenu: $showDebugMenu)
            .environmentObject(preferenceStorage)
        }
        .sheet(isPresented: $showWallpaperModifier) {
            WallpaperModifierView(showWallpaperModifier: $showWallpaperModifier)
            .environmentObject(preferenceStorage)
        }
    }
}

struct DebugMenuView: View {
    @Binding var showDebugMenu: Bool
    @State private var selectedOption = "light rain"
    let debugOptions = ["light rain","clear sky","moderate rain","heavy intensity rain","few clouds","scattered clouds","broken clouds","overcast clouds"]
    @State private var showPicker = false
    
    var body: some View {
        VStack {
            List {
                Button("Open Picker") {
                    withAnimation {
                        self.showPicker = true
                    }
                }
                
                // Other debug menu items...
            }
            .sheet(isPresented: $showPicker) {
                OptionPickerView(selectedOption: $selectedOption, debugOptions: debugOptions)
            }
            
            Button("Back") {
                withAnimation {
                    self.showDebugMenu = false
                }
            }
            .padding()
        }
    }
}

struct OptionPickerView: View {
    @Binding var selectedOption: String
    let debugOptions: [String]
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var preferenceStorage: PreferenceStorage
    var body: some View {
        VStack {
            Picker("Select an option", selection: $selectedOption) {
                ForEach(debugOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            
            Button("Done") {
                withAnimation {
                    showingAlert = true
                }
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Are you sure?"),
                    message: Text("Are you sure you want to override the weather, THIS WILL RESPRING!"),
                    primaryButton: .destructive(Text("Yes"),action: {
                        preferenceStorage.shouldOverride = true
                    preferenceStorage.override = selectedOption
                    Respring.execute()
                    }),
                    secondaryButton: .default(Text("No"),action: {
                        withAnimation {
                        showingAlert = false
                        presentationMode.wrappedValue.dismiss()
                        }
                    })
                )
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(10)
        .shadow(radius: 5)
        .overlay(
            Button(action: {
                withAnimation {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
            },
            alignment: .topTrailing
        )
    }
}

struct WallpaperModifierView: View {
    @Binding var showWallpaperModifier: Bool
    @State private var selectedWallpaperOption = "All"
    let wallpaperOptions = ["All","light rain","moderate rain","heavy intensity rain","clear sky","few clouds","scattered clouds","broken clouds","overcast clouds"];
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showFailAlert = false
    @EnvironmentObject var preferenceStorage: PreferenceStorage
    var body: some View {
        VStack {
            Picker("Select Wallpaper", selection: $selectedWallpaperOption) {
                ForEach(wallpaperOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            if selectedImage != nil {
                Image(uiImage: selectedImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            
            Button("Select Photo") {
                withAnimation {
                    self.showImagePicker = true
                }
            }
            
            Button("Apply") {
               if(selectedWallpaperOption == "All") {
                    for weather in wallpaperOptions {
                        if weather == "All" {
                            continue
                        }
                        let pngData = selectedImage!.pngData()!
                        let saveTo = NSString.path(withComponents: [NSString.init(cString: libroot_dyn_get_root_prefix(), encoding: UInt(4))! as String,"/Library/Application Support/WeatherWhirl","/" + weather + ".png"])
                        NSLog(saveTo);
                        do {
                        try pngData.write(to: URL(fileURLWithPath: saveTo),options: [.atomic])
                        } catch {
                            withAnimation {
                                showFailAlert = true
                            }
                            return
                        }
                        preferenceStorage.customBackgrounds[weather] = saveTo
                    }
               } else {
                        let pngData = selectedImage!.pngData()!
                        let saveTo = NSString.path(withComponents: [NSString.init(cString: libroot_dyn_get_root_prefix(), encoding: UInt(4))! as String,"/Library/Application Support/WeatherWhirl","/" + selectedWallpaperOption + ".png"])
                        NSLog(saveTo)
                        do {
                        try pngData.write(to: NSURL.fileURL(withPath: saveTo),options: [.atomic])
                        } catch {
                            withAnimation {
                                showFailAlert = true
                            }
                            return
                        }
                        preferenceStorage.customBackgrounds[selectedWallpaperOption] = saveTo
               }
               Respring.execute()
            }
            .alert(isPresented: $showFailAlert) {
                Alert(
                    title: Text("Error!"),
                    message: Text("Failed to apply image!"),
                    dismissButton: .default(Text("OK"),action: {
                        withAnimation {
                            showFailAlert = false
                        }
                    })
                )
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Back") {
                withAnimation {
                    self.showWallpaperModifier = false
                }
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let result = results.first, result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImage = image
                        }
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
