import SwiftUI
import Comet
import WeatherWhirlPrefsC

class RootListController: CMViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup(content: PreferencesView())
        self.title = "WeatherWhirlPrefs"
    }
}
