import Foundation

public struct Settings {
    /**
     For use global on all reqeusts performed by CoreNetowrk
     
     There query items does not override network or request scope query items.
     */
    public static var globalQueryItems: [String: Any] = [:]
    
    /**
     For use global on all reqeusts performed by CoreNetowrk
     
     There header fields does not override network or request scope header fields.
     */
    public static var globalHeaderFields: [String: String] = [:]
}
