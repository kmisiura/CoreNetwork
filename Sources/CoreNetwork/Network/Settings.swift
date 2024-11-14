import Foundation

public struct Settings {
    /**
     For use global on all reqeusts performed by CoreNetowrk
     
     These query items do not override network or request scope query items.
     */
    public static var globalQueryItems: [String: Any] = [:]
    
    /**
     For use global on all reqeusts performed by CoreNetowrk
     
     These header fields do not override network or request scope header fields.
     */
    public static var globalHeaderFields: [String: String] = [:]
}
