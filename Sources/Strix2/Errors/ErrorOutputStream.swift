import Foundation

protocol ErrorOutputStream: TextOutputStream {
    var indent: Indent { get set }
}
