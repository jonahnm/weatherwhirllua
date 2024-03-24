import Foundation
import Comet
import libroot
// MARK: - Internal

final class PreferenceStorage: ObservableObject {

    private static let registry: String = NSString.path(withComponents: [NSString.init(cString: libroot_dyn_get_root_prefix(), encoding: UInt(4))! as String,"/var/mobile/Library/Preferences/com.sora.weatherwhirl.plist"])
    /// Welcome to Comet
    /// By @ginsudev
    ///
    /// Mark your preferences with `@Published(key: "someKey", registry: PreferenceStorage.registry)`.
    /// When the value of these properties are changed, they are also saved into the preferences file on disk to persist changes.
    ///
    /// The initial value you initialise your property with is the fallback / default value that will be used if there is no present value for the
    /// given key.
    ///
    /// `@Published(key: _ registry:_)` properties can only store Foundational types that conform
    /// to `Codable` (i.e. `String, Data, Int, Bool, Double, Float`, etc).

    // Preferences
    @Published(key: "isEnabledTweak", registry: registry) var isEnabled = false
    @Published(key: "overrideNext", registry: registry) var shouldOverride = false
    @Published(key: "override",registry: registry) var override = ""
    @Published(key: "customBackgrounds",registry: registry) var customBackgrounds: Dictionary<String,String> = [:];
}
