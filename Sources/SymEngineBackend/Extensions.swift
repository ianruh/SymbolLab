import SymEngine
import SymbolLab

extension SymEngine.Symbol {
    /// Make some changes to the string is a dialect I like here
    ///
    ///    Changes:
    ///
    ///    - Change '**' for power to '^'
    ///    - Change leading '-' to '-1*'
    public var symbolLabString: String {
        var desc = self.description
        desc = desc.replacingOccurrences(of: "**", with: "^")
        if(desc.first == "-") {
            desc.remove(at: desc.startIndex)
            desc = "-1*\(desc)"
        }
        return desc
    }
}