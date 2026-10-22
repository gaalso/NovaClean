//
//  NovaCleanApp.swift — v1.1 "Nova"
//  Reimplementação original inspirada na CleanMyMac 5, construída a partir de uma
//  análise estática (REA) do app instalado na máquina. Código, nomes, labels, UI
//  e logo são 100% originais — sem assets ou strings da MacPaw. Não afiliado à MacPaw.
//

import SwiftUI
import AppKit

// MARK: - Helpers

func fmtBytes(_ b: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
}

func pct1(_ v: Double) -> String {
    String(format: "%.0f%%", min(100, max(0, v)))
}

func fmtDate(_ d: Date?) -> String {
    guard let d = d else { return "—" }
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .none
    return f.string(from: d)
}

// MARK: - Models

enum Phase: Equatable { case idle, running, done }

struct DiskItem: Identifiable, Hashable {
    let id: String
    let url: URL
    let name: String
    let pathDisplay: String
    let sizeBytes: Int64
    let modified: Date?
    let deletable: Bool
    let version: String?
}

struct ModuleResult {
    var phase: Phase = .idle
    var progressText: String = ""
    var items: [DiskItem] = []
    var total: Int64 = 0
}

struct TrashState {
    var phase: Phase = .idle
    var count: Int = 0
    var total: Int64 = 0
}

struct SysProc: Identifiable {
    let pid: Int32
    let name: String
    let cpu: Double
    let mem: Int64
    var id: Int32 { pid }
}

struct SysSnapshot {
    var ramTotal: Int64 = 0
    var ramUsed: Int64 = 0
    var ramUnused: Int64 = 0
    var cpuUser: Double = 0
    var cpuSys: Double = 0
    var cpuIdle: Double = 100
    var thermalText: String = "—"
    var thermalLevel: Int = -1
    var procs: [SysProc] = []
}

// MARK: - Theme ("Nova" identity)

enum Theme {
    static let bg       = Color(red: 0.043, green: 0.043, blue: 0.071)      // #0B0B12
    static let sidebar  = Color(red: 0.075, green: 0.075, blue: 0.118)      // #13131E
    static let card     = Color(red: 0.118, green: 0.118, blue: 0.173)      // #1E1E2C
    static let cardSoft = Color(red: 0.152, green: 0.152, blue: 0.220)      // #272738
    static let hairline = Color.white.opacity(0.07)
    static let textDim  = Color(red: 0.616, green: 0.627, blue: 0.690)      // #9DA0B0
    static let brandStart = Color(red: 0.478, green: 0.173, blue: 1.000)    // #7A2CFF
    static let brandMid   = Color(red: 0.647, green: 0.173, blue: 1.000)    // #A52CFF
    static let brandEnd   = Color(red: 1.000, green: 0.243, blue: 0.557)    // #FF3E8E
    static let danger   = Color(red: 1.000, green: 0.271, blue: 0.227)      // #FF453A
    static let okGreen  = Color(red: 0.204, green: 0.780, blue: 0.482)      // #34C77B

    static var brand: [Color] { [brandStart, brandMid, brandEnd] }

    /// Gradientes para o mapa de bolhas (orbit chart).
    static let bubbleGradients: [LinearGradient] = [
        LinearGradient(colors: [Color(red: 0.478, green: 0.173, blue: 1.000), Color(red: 0.647, green: 0.173, blue: 1.000)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.647, green: 0.173, blue: 1.000), Color(red: 1.000, green: 0.243, blue: 0.557)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.310, green: 0.541, blue: 1.000), Color(red: 0.478, green: 0.173, blue: 1.000)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.204, green: 0.820, blue: 0.763), Color(red: 0.310, green: 0.541, blue: 1.000)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 1.000, green: 0.243, blue: 0.557), Color(red: 1.000, green: 0.478, blue: 0.376)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.647, green: 0.173, blue: 1.000), Color(red: 0.843, green: 0.243, blue: 0.839)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.204, green: 0.541, blue: 1.000), Color(red: 0.204, green: 0.780, blue: 0.952)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.588, green: 0.243, blue: 1.000), Color(red: 1.000, green: 0.243, blue: 0.557)], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    static let spectrumColors: [Color] = [
        Color(red: 0.478, green: 0.173, blue: 1.000),
        Color(red: 0.310, green: 0.541, blue: 1.000),
        Color(red: 0.204, green: 0.820, blue: 0.763),
        Color(red: 1.000, green: 0.243, blue: 0.557)
    ]
}

extension LinearGradient {
    static var brand: LinearGradient {
        LinearGradient(colors: Theme.brand, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var brandH: LinearGradient {
        LinearGradient(colors: Theme.brand, startPoint: .leading, endPoint: .trailing)
    }
    static var deepspace: LinearGradient {
        LinearGradient(colors: [Color(red: 0.071, green: 0.071, blue: 0.114),
                                Theme.bg],
                       startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Logo & brand shapes

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.385
        for i in 0..<8 {
            let ang = Double(i) * Double.pi / 4 + Double.pi / 2
            let r = (i % 2 == 0) ? outer : inner
            let x = cx + CGFloat(r * cos(ang))
            let y = cy - CGFloat(r * sin(ang))
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

struct NovaLogo: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(LinearGradient.brand)
            Circle()
                .stroke(Color.white.opacity(0.38), lineWidth: max(1, size * 0.055))
                .padding(size * 0.145)
            SparkleShape()
                .fill(Color.white)
                .frame(width: size * 0.46, height: size * 0.46)
            SparkleShape()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.155, height: size * 0.155)
                .offset(x: -size * 0.26, y: size * 0.27)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Scan engine (Foundation puro; roda fora da MainActor)

enum Engine {

    /// Soma recursiva do tamanho de um diretório, com limite de entradas.
    static func deepSize(_ dir: URL, entryCap: Int = 300_000) -> Int64 {
        var total: Int64 = 0
        let fm = FileManager.default
        guard let en = fm.enumerator(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return 0 }
        var count = 0
        while let u = en.nextObject() as? URL {
            count += 1
            if count > entryCap { break }
            guard let v = try? u.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]) else { continue }
            if v.isRegularFile == true {
                total += Int64(v.fileSize ?? 0)
            }
        }
        return total
    }

    static func appMeta(_ app: URL) -> (name: String?, version: String?) {
        let p = app.appendingPathComponent("Contents/Info.plist")
        guard let d = try? Data(contentsOf: p),
              let o = (try? PropertyListSerialization.propertyList(from: d, options: [], format: nil)) as? [String: Any]
        else {
            return (app.deletingPathExtension().lastPathComponent, nil)
        }
        let name = (o["CFBundleDisplayName"] as? String)
            ?? (o["CFBundleName"] as? String)
            ?? app.deletingPathExtension().lastPathComponent
        let ver = (o["CFBundleShortVersionString"] as? String) ?? (o["CFBundleVersion"] as? String)
        return (name, ver)
    }

    /// Tamanhos dos componentes de 1º nível de um diretório, medidos em paralelo.
    static func topEntries(_ dir: URL, minSize: Int64, forceReadonly: Bool = false) -> [DiskItem] {
        let fm = FileManager.default
        let children = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        guard !children.isEmpty else { return [] }

        let buf = UnsafeMutablePointer<Int64>.allocate(capacity: children.count)
        DispatchQueue.concurrentPerform(iterations: children.count) { i in
            buf[i] = deepSize(children[i])
        }
        var items: [DiskItem] = []
        for (i, u) in children.enumerated() {
            let s = buf[i]
            guard s >= minSize else { continue }
            var version: String? = nil
            var name = u.lastPathComponent
            if u.pathExtension == "app" {
                let meta = appMeta(u)
                version = meta.version
                if let n = meta.name { name = n }
            }
            var date: Date? = nil
            if let v = (try? u.resourceValues(forKeys: [.contentModificationDateKey])) {
                date = v.contentModificationDate
            }
            items.append(DiskItem(
                id: u.path,
                url: u,
                name: name,
                pathDisplay: u.path,
                sizeBytes: s,
                modified: date,
                deletable: forceReadonly ? false : !u.path.hasPrefix("/Library/"),
                version: version
            ))
        }
        buf.deallocate()
        items.sort { $0.sizeBytes > $1.sizeBytes }
        return items
    }

    static func scanCaches() -> ModuleResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let userCaches = home.appendingPathComponent("Library/Caches")
        var items = topEntries(userCaches, minSize: 1_048_576)
        let sysItems = topEntries(URL(fileURLWithPath: "/Library/Caches"), minSize: 8_388_608, forceReadonly: true)
        items.append(contentsOf: sysItems)
        let total = items.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return ModuleResult(phase: .done, progressText: "", items: items, total: total)
    }

    static func scanLargeFiles(minimum: Int64 = 50_000_000) -> ModuleResult {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let roots = ["Desktop", "Documents", "Downloads", "Movies", "Music", "Pictures"]
            .map { home.appendingPathComponent($0) }
        var out: [DiskItem] = []
        for root in roots {
            guard let en = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }
            var count = 0
            while let u = en.nextObject() as? URL {
                count += 1
                if count > 80_000 { break }
                guard let v = try? u.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]) else { continue }
                guard v.isRegularFile == true else { continue }
                let name = u.lastPathComponent
                if Int64(v.fileSize ?? 0) >= minimum, !name.hasSuffix(".icloud") {
                    out.append(DiskItem(
                        id: u.path,
                        url: u,
                        name: name,
                        pathDisplay: u.path,
                        sizeBytes: Int64(v.fileSize ?? 0),
                        modified: v.contentModificationDate,
                        deletable: true,
                        version: nil
                    ))
                }
            }
        }
        out.sort { $0.sizeBytes > $1.sizeBytes }
        if out.count > 200 { out = Array(out.prefix(200)) }
        let total = out.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return ModuleResult(phase: .done, progressText: "", items: out, total: total)
    }

    static func scanApplications() -> ModuleResult {
        let fm = FileManager.default
        var appURLs: [URL] = []
        let dirs = [URL(fileURLWithPath: "/Applications"),
                    fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        for d in dirs {
            let entries = (try? fm.contentsOfDirectory(at: d, includingPropertiesForKeys: nil)) ?? []
            for e in entries where e.pathExtension == "app" {
                appURLs.append(e)
            }
        }
        guard !appURLs.isEmpty else {
            return ModuleResult(phase: .done, progressText: "", items: [], total: 0)
        }
        let buf = UnsafeMutablePointer<Int64>.allocate(capacity: appURLs.count)
        DispatchQueue.concurrentPerform(iterations: appURLs.count) { i in
            buf[i] = deepSize(appURLs[i], entryCap: 60_000)
        }
        var items: [DiskItem] = []
        for (i, u) in appURLs.enumerated() {
            let meta = appMeta(u)
            items.append(DiskItem(
                id: u.path,
                url: u,
                name: meta.name ?? u.deletingPathExtension().lastPathComponent,
                pathDisplay: u.path,
                sizeBytes: buf[i],
                modified: (try? u.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? nil,
                deletable: true,
                version: meta.version
            ))
        }
        buf.deallocate()
        items.sort { $0.sizeBytes > $1.sizeBytes }
        let total = items.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return ModuleResult(phase: .done, progressText: "", items: items, total: total)
    }

    static func scanTrash() -> TrashState {
        let fm = FileManager.default
        let trash = fm.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        let children = (try? fm.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil)) ?? []
        guard children.count > 0 else { return TrashState(phase: .done, count: 0, total: 0) }
        let buf = UnsafeMutablePointer<Int64>.allocate(capacity: children.count)
        DispatchQueue.concurrentPerform(iterations: children.count) { i in
            buf[i] = deepSize(children[i])
        }
        var total: Int64 = 0
        for i in 0..<children.count { total += buf[i] }
        buf.deallocate()
        return TrashState(phase: .done, count: children.count, total: total)
    }

    /// Quebra de espaço de um escopo: um passe profundo único atribui cada arquivo
    /// regular ao seu componente de 1º nível. Retorna pastas, arquivos topo, destaques e total.
    static func spaceBreakdown(scope: URL) -> (dirs: [DiskItem], files: [DiskItem], bigFiles: [DiskItem], total: Int64) {
        let fm = FileManager.default
        let children = (try? fm.contentsOfDirectory(at: scope, includingPropertiesForKeys: nil)) ?? []
        var dirNames: [String] = []
        var dirIndex: [String: Int] = [:]
        var fileItems: [DiskItem] = []
        var bigFiles: [DiskItem] = []
        for c in children {
            var isDir: ObjCBool = false
            _ = fm.fileExists(atPath: c.path, isDirectory: &isDir)
            if isDir.boolValue {
                dirIndex[c.lastPathComponent] = dirNames.count
                dirNames.append(c.lastPathComponent)
            } else if let v = (try? c.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])) {
                if v.isRegularFile == true {
                    fileItems.append(DiskItem(id: c.path, url: c, name: c.lastPathComponent, pathDisplay: c.path,
                                              sizeBytes: Int64(v.fileSize ?? 0), modified: nil, deletable: true, version: nil))
                }
            }
        }
        guard dirNames.count > 0 else {
            let total = fileItems.reduce(Int64(0)) { $0 + $1.sizeBytes }
            return ([], fileItems, [], total)
        }
        let sizes = UnsafeMutablePointer<Int64>.allocate(capacity: dirNames.count)
        for i in 0..<dirNames.count { sizes[i] = 0 }

        guard let en = fm.enumerator(
            at: scope,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            sizes.deallocate()
            return ([], fileItems, [], 0)
        }
        var count = 0
        while let u = en.nextObject() as? URL {
            count += 1
            if count > 500_000 { break }
            let p = u.path
            guard p.count > scope.path.count + 1 else { continue }
            let relStart = scope.path == "/" ? p.index(p.startIndex, offsetBy: 1) : p.index(scope.path.endIndex, offsetBy: 1)
            let rel = String(p[relStart...])
            guard let slash = rel.firstIndex(of: "/") else { continue }
            let first = String(rel[rel.startIndex..<slash])
            guard let idx = dirIndex[first] else { continue }
            guard let v = try? u.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]) else { continue }
            guard v.isRegularFile == true else { continue }
            let s = Int64(v.fileSize ?? 0)
            sizes[idx] += s
            if s >= 100_000_000, bigFiles.count < 300 {
                bigFiles.append(DiskItem(id: u.path, url: u, name: u.lastPathComponent, pathDisplay: u.path,
                                         sizeBytes: s, modified: nil, deletable: true, version: nil))
            }
        }
        var dirItems: [DiskItem] = []
        for i in 0..<dirNames.count {
            let name = dirNames[i]
            let url = scope.appendingPathComponent(name)
            dirItems.append(DiskItem(id: url.path, url: url, name: name, pathDisplay: url.path,
                                     sizeBytes: sizes[i], modified: nil,
                                     deletable: !url.path.hasPrefix("/Library/"), version: nil))
        }
        sizes.deallocate()
        dirItems.sort { $0.sizeBytes > $1.sizeBytes }
        fileItems.sort { $0.sizeBytes > $1.sizeBytes }
        bigFiles.sort { $0.sizeBytes > $1.sizeBytes }
        let total = dirItems.reduce(Int64(0)) { $0 + $1.sizeBytes } + fileItems.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return (dirItems, fileItems, bigFiles, total)
    }

    // MARK: Estatísticas e utilidades de sistema

    static func runCmd(_ path: String, _ args: [String], limit: Int = 8_000_000) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard data.count > 0 else { return nil }
        if data.count > limit { return String(data: data.prefix(limit), encoding: .utf8) }
        return String(data: data, encoding: .utf8)
    }

    /// sysctl genérico (Int32/Int64) — nil se inexistente neste kernel.
    static func sysctlNumber(_ name: String) -> Int64? {
        var size: Int = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        if size == MemoryLayout<Int32>.size {
            var v: Int32 = 0
            return sysctlbyname(name, &v, &size, nil, 0) == 0 ? Int64(v) : nil
        }
        if size == MemoryLayout<Int64>.size {
            var v: Int64 = 0
            return sysctlbyname(name, &v, &size, nil, 0) == 0 ? v : nil
        }
        return nil
    }

    /// "2.14G"/"523M"/"9K" → bytes (base 1024, resposta do /usr/bin/top).
    static func parseByteToken(_ t: String) -> Int64? {
        guard t.count >= 2 else { return nil }
        let last = t.last!
        let numPart = t.dropLast()
        guard let n = Double(numPart) else { return nil }
        switch last {
        case "K": return Int64(n * 1024)
        case "M": return Int64(n * 1024 * 1024)
        case "G": return Int64(n * 1024 * 1024 * 1024)
        case "B": return Int64(n)
        default: return nil
        }
    }

    private static func firstNumber(in line: String, pattern: String) -> Double? {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = line as NSString
        guard let m = re.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 1 else { return nil }
        return Double(ns.substring(with: m.range(at: 1)))
    }

    private static func thermalName(_ level: Int) -> String {
        switch level {
        case 0: return "Nominal"
        case 1: return "Moderado"
        case 2, 3: return "Quente"
        case 4, 5: return "Crítico"
        default: return "—"
        }
    }

    /// Amostra de CPU/mem/processos em duas passadas do top (2ª = delta preciso).
    static func fetchSystem() -> SysSnapshot {
        var snap = SysSnapshot()
        snap.ramTotal = sysctlNumber("hw.memsize") ?? 0

        if let out = runCmd("/usr/bin/top",
                            ["-l", "2", "-s", "2", "-n", "200", "-stats", "pid,mem,cpu,command"]) {
            var byPid: [Int32: SysProc] = [:]
            for raw in out.split(separator: "\n") {
                let s = String(raw).trimmingCharacters(in: .whitespaces)
                if s.hasPrefix("PhysMem:") {
                    let toks = s.split(separator: " ").map(String.init)
                    if toks.count > 2 {
                        snap.ramUsed = parseByteToken(toks[1]) ?? snap.ramUsed
                    }
                    if let ui = toks.firstIndex(where: { $0.hasSuffix("unused.") }),
                       ui >= 1, let u = parseByteToken(toks[ui - 1]) {
                        snap.ramUnused = u
                    }
                } else if s.contains("% user,") {
                    if let re = try? NSRegularExpression(pattern: "([0-9.]+)% user, *([0-9.]+)% sys, *([0-9.]+)% idle") {
                        let ns = s as NSString
                        if let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)),
                           m.numberOfRanges >= 4 {
                            snap.cpuUser = Double(ns.substring(with: m.range(at: 1))) ?? snap.cpuUser
                            snap.cpuSys = Double(ns.substring(with: m.range(at: 2))) ?? snap.cpuSys
                            snap.cpuIdle = Double(ns.substring(with: m.range(at: 3))) ?? snap.cpuIdle
                        }
                    }
                } else {
                    let toks = s.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
                    if toks.count >= 4, let pid = Int32(toks[0]) {
                        let mem = parseByteToken(toks[1]) ?? 0
                        let cpu = Double(toks[2]) ?? 0
                        let cmd = toks[3...].joined(separator: " ")
                        if !cmd.isEmpty, cmd != "COMMAND", cmd != "top" {
                            byPid[pid] = SysProc(pid: pid, name: cmd, cpu: max(0, cpu), mem: mem)
                        }
                    }
                }
            }
            snap.procs = Array(byPid.values).sorted { $0.mem > $1.mem }
        }

        var lvl = Int(sysctlNumber("machdep.xcpm.cpu_thermal_level") ?? -1)
        if lvl == -1 { lvl = Int(sysctlNumber("machdep.xcpm.package_thermal_level") ?? -1) }
        snap.thermalLevel = lvl
        snap.thermalText = lvl == 0 ? "Nominal" : (lvl > 0 ? "Nível \(lvl)" : "—")
        return snap
    }

    /// Squarified treemap (Bruls et al.) — sem sobreposição, preenche o retângulo inteiro.
    static func squarify(bytesArr: [Int64], frame: CGRect) -> [CGRect] {
        var out = [CGRect](repeating: .zero, count: bytesArr.count)
        let total = bytesArr.reduce(Int64(0)) { $0 + $1 }
        guard total > 0, frame.width > 2, frame.height > 2 else { return out }
        let area = Double(frame.width) * Double(frame.height)
        var areas: [Double] = bytesArr.map { Double($0) / Double(total) * area }

        var x = frame.minX
        var y = frame.minY
        var w = frame.width
        var h = frame.height
        var i = 0
        while i < areas.count {
            guard w > 0.5, h > 0.5 else { break }
            let vertical = w >= h
            let side = vertical ? h : w
            var sumA: Double = 0
            var bestWorst = Double.greatestFiniteMagnitude
            var chosenEnd = i - 1
            var j = i
            while j < areas.count {
                sumA += areas[j]
                let thick = max(0.000001, sumA / side)
                var worst = 0.0
                for k in i...j {
                    let len = max(0.000001, areas[k] / thick)
                    let asp = max(thick / len, len / thick)
                    if asp > worst { worst = asp }
                }
                if worst <= bestWorst {
                    bestWorst = worst
                    chosenEnd = j
                    j += 1
                } else {
                    break
                }
            }
            guard chosenEnd >= i else { break }
            let chosenSum = areas[i...chosenEnd].reduce(0, +)
            let thick = max(0.000001, chosenSum / side)
            var off = vertical ? y : x
            for k in i...chosenEnd {
                let len = max(0, areas[k] / thick)
                let r = vertical
                    ? CGRect(x: x, y: off, width: thick, height: len)
                    : CGRect(x: off, y: y, width: len, height: thick)
                out[k] = r
                off += len
            }
            if vertical {
                x += thick
                w -= thick
            } else {
                y += thick
                h -= thick
            }
            i = chosenEnd + 1
        }
        return out
    }

    /// Uso real do disco (total e livre) para a barra "Macintosh HD".
    static func diskStatus() -> (total: Int64, free: Int64) {
        let v = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
        return (Int64(v?.volumeTotalCapacity ?? 0), Int64(v?.volumeAvailableCapacity ?? 0))
    }

    /// Packing aproximado de bolhas (estilo orbit chart) em coordenadas unitárias [0..1].
    /// Entrada: pares (nome, bytes) já ordenados desc; saída: centros/raios normalizados.
    static func packBubbles(bytes: [Double], maxCount: Int = 24) -> [(cx: Double, cy: Double, r: Double)] {
        var data = bytes
        if data.count > maxCount { data = Array(data.prefix(maxCount)) }
        guard let maxB = data.first, maxB > 0 else { return [] }
        let radii = data.map { r -> Double in r / maxB } // 1.0 no líder

        var placed: [(x: Double, y: Double, r: Double)] = []
        let Rmax: Double = 0.40
        let pad: Double = 0.012
        // primeiro: líder no centro
        for (i, norm) in radii.enumerated() {
            let r0 = Rmax * sqrt(norm) * 0.72  // reduz o líder para dar espaço aos demais
            let r = max(0.05, min(Rmax, r0))
            if i == 0 {
                placed.append((0.5, 0.5, r))
            } else {
                // espiral dourada em busca de posição sem sobreposição
                var placed1 = false
                var bestX = 0.5
                var bestY = 0.5
                var bestMiss = Double.greatestFiniteMagnitude
                var t: Double = 0.015
                while t < 0.85 {
                    let ang = t * 7.6 // volta em espiral
                    let cx = 0.5 + t * cos(ang)
                    let cy = 0.5 + t * sin(ang)
                    var ok = cx - r >= 0.012 && cx + r <= 0.988 && cy - r >= 0.012 && cy + r <= 0.988
                    if ok {
                        for p in placed {
                            let dx = cx - p.x, dy = cy - p.y
                            let d = (dx * dx + dy * dy).squareRoot()
                            if d < p.r + r + pad {
                                ok = false
                                break
                            }
                        }
                    }
                    if ok {
                        placed.append((cx, cy, r))
                        placed1 = true
                        break
                    } else {
                        // guarda o melhor esforço (menor sobreposição)
                        var miss = 0.0
                        for p in placed {
                            let dx = cx - p.x, dy = cy - p.y
                            let d = (dx * dx + dy * dy).squareRoot()
                            let protrude = (p.r + r + pad) - d
                            if protrude > 0 { miss += protrude }
                        }
                        if miss < bestMiss {
                            bestMiss = miss
                            bestX = min(max(r + 0.012, cx), 0.988 - r)
                            bestY = min(max(r + 0.012, cy), 0.988 - r)
                        }
                    }
                    t += 0.006
                }
                if !placed1 {
                    // aperta um pouco e tenta a melhor posição de novo
                    var rr = r * 0.85
                    for _ in 0..<3 {
                        var fits = true
                        for p in placed {
                            let dx = (bestX - p.x), dy = (bestY - p.y)
                            let d = (dx * dx + dy * dy).squareRoot()
                            if d < p.r + rr + pad { fits = false; break }
                        }
                        if fits { placed.append((bestX, bestY, rr)); placed1 = true; break }
                        rr *= 0.85
                    }
                    if !placed1 {
                        placed.append((bestX, bestY, r * 0.7))
                    }
                }
            }
        }
        return placed.map { (cx: $0.x, cy: $0.y, r: $0.r) }
    }

    // MARK: Ações

    static func sendToTrash(_ url: URL) throws {
        var outURL: NSURL? = nil
        try FileManager.default.trashItem(at: url, resultingItemURL: &outURL)
    }

    @discardableResult
    static func moveToTrash(_ urls: [URL]) -> Int {
        var failed = 0
        for u in urls {
            do { try sendToTrash(u) } catch { failed += 1 }
        }
        return failed
    }

    @discardableResult
    static func emptyTrash() -> Int {
        let fm = FileManager.default
        let trash = fm.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        let children = (try? fm.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil)) ?? []
        var failed = 0
        for c in children {
            do { try fm.removeItem(at: c) } catch { failed += 1 }
        }
        return failed
    }

    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - Store

enum Tab: Hashable { case care, junk, large, space, accel, system, apps, trash, about }

@MainActor
final class Store: ObservableObject {
    @Published var tab: Tab = .care

    @Published var diskTotal: Int64 = 0
    @Published var diskFree: Int64 = 0

    @Published var carePhase: Phase = .idle
    @Published var careText: String = ""
    @Published var careJunkBytes: Int64 = 0
    @Published var careJunkCount: Int = 0
    @Published var careBigBytes: Int64 = 0
    @Published var careBigCount: Int = 0
    @Published var careTrashBytes: Int64 = 0
    @Published var careAppsCount: Int = 0
    @Published var careDiskTotal: Int64 = 0

    @Published var junk = ModuleResult()
    @Published var junkSelection: Set<String> = []

    @Published var larges = ModuleResult()
    @Published var largeSelection: Set<String> = []

    @Published var space = ModuleResult()
    @Published var spaceTopFiles: [DiskItem] = []
    @Published var spaceBigFiles: [DiskItem] = []
    @Published var spaceScope: URL = FileManager.default.homeDirectoryForCurrentUser

    @Published var apps = ModuleResult()

    @Published var trash = TrashState()

    @Published var sys = SysSnapshot()
    @Published var accelSelection: Set<Int32> = []
    @Published var lastPurgeNote: String = ""

    @Published var careFreeTrash: Bool = false
    @Published var lastCareNote: String = ""
    @Published var lastCareFreed: Int64 = 0
    @Published var lastCareFailed: Int = 0

    @Published var actionMessage: String = ""
    @Published var showActionAlert: Bool = false
    @Published var confirmEmptyTrash: Bool = false

    func notify(_ text: String) {
        actionMessage = text
        showActionAlert = true
    }

    func scanJunk() async {
        junk = ModuleResult()
        junk.phase = .running
        junk.progressText = "Medindo pastas de cache…"
        junkSelection = []
        let res = await Task.detached(priority: .userInitiated) { Engine.scanCaches() }.value
        junk = res
        // pré-seleção: sugestão = item removível ≥ 128 MB
        junkSelection = Set(res.items.filter { $0.deletable && $0.sizeBytes >= 131_072_000 }.map { $0.id })
    }

    func scanLarges() async {
        larges = ModuleResult()
        larges.phase = .running
        larges.progressText = "Procurando arquivos grandes…"
        largeSelection = []
        let res = await Task.detached(priority: .userInitiated) { Engine.scanLargeFiles() }.value
        larges = res
        // pré-seleção: sugestão = arquivo ≥ 300 MB
        largeSelection = Set(res.items.filter { $0.deletable && $0.sizeBytes >= 314_572_800 }.map { $0.id })
    }

    func scanSpace(at url: URL? = nil) async {
        if let u = url { spaceScope = u }
        let scope = spaceScope
        spaceTopFiles = []
        space = ModuleResult()
        space.phase = .running
        space.progressText = "Visualizando o espaço em disco…"
        let (status, res) = await Task.detached(priority: .userInitiated) {
            (Engine.diskStatus(), Engine.spaceBreakdown(scope: scope))
        }.value
        diskTotal = status.total
        diskFree = status.free
        space = ModuleResult(phase: .done, progressText: "", items: res.dirs, total: res.total)
        spaceTopFiles = res.files
        spaceBigFiles = res.bigFiles
    }

    func scanApps() async {
        apps = ModuleResult()
        apps.phase = .running
        apps.progressText = "Inventariando aplicativos…"
        let res = await Task.detached(priority: .userInitiated) { Engine.scanApplications() }.value
        apps = res
    }

    func scanTrash() async {
        trash = TrashState(phase: .running, count: 0, total: 0)
        let res = await Task.detached(priority: .userInitiated) { Engine.scanTrash() }.value
        trash = res
    }

    func cleanJunkSelection() async {
        let picked = junk.items.filter { junkSelection.contains($0.id) && $0.deletable }
        let urls = picked.map { $0.url }
        let freed = picked.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let failed = await Task.detached(priority: .userInitiated) { () -> Int in
            var f = 0
            for u in urls {
                do { try Engine.sendToTrash(u) } catch { f += 1 }
            }
            return f
        }.value
        sendSummary(moved: picked.count - failed, failed: failed, bytes: freed)
        await scanJunk()
    }

    func cleanLargeSelection() async {
        let picked = larges.items.filter { largeSelection.contains($0.id) && $0.deletable }
        let urls = picked.map { $0.url }
        let freed = picked.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let failed = await Task.detached(priority: .userInitiated) { () -> Int in
            var f = 0
            for u in urls {
                do { try Engine.sendToTrash(u) } catch { f += 1 }
            }
            return f
        }.value
        sendSummary(moved: picked.count - failed, failed: failed, bytes: freed)
        await scanLarges()
    }

    func cleanSpaceFiles(_ picked: [DiskItem]) async {
        guard !picked.isEmpty else { return }
        let urls = picked.map { $0.url }
        let freed = picked.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let failed = await Task.detached(priority: .userInitiated) { () -> Int in
            var f = 0
            for u in urls {
                do { try Engine.sendToTrash(u) } catch { f += 1 }
            }
            return f
        }.value
        sendSummary(moved: picked.count - failed, failed: failed, bytes: freed)
        await scanSpace()
    }

    func uninstall(_ item: DiskItem) async {
        let name = item.name
        let failed = await Task.detached(priority: .userInitiated) { () -> Int in
            do {
                try Engine.sendToTrash(item.url)
                return 0
            } catch { return 1 }
        }.value
        if failed == 0 {
            notify("\(name) movido para a Lixeira.")
        } else {
            notify("Não foi possível mover \(name) (pode estar em execução).")
        }
        await scanApps()
    }

    /// Cuidado Inteligente: tudo em paralelo (uma amostra conjunta e rápida).
    func runCare() async {
        carePhase = .running
        lastCareNote = ""
        careText = "Analisando o sistema em paralelo…"
        let (status, _) = await Task.detached(priority: .utility) { (Engine.diskStatus(), true) }.value
        diskTotal = status.total
        diskFree = status.free
        careDiskTotal = status.total

        let jT = Task.detached(priority: .userInitiated) { Engine.scanCaches() }
        let lT = Task.detached(priority: .userInitiated) { Engine.scanLargeFiles() }
        let tT = Task.detached(priority: .userInitiated) { Engine.scanTrash() }
        let aT = Task.detached(priority: .userInitiated) { Engine.scanApplications() }

        junkSelection = []
        largeSelection = []

        let j = await jT.value
        junk = j
        junkSelection = Set(j.items.filter { $0.deletable && $0.sizeBytes >= 131_072_000 }.map { $0.id })
        careJunkBytes = j.total
        careJunkCount = j.items.filter { $0.deletable }.count
        careText = "Caches prontos — coletando o restante…"

        let l = await lT.value
        larges = l
        largeSelection = Set(l.items.filter { $0.deletable && $0.sizeBytes >= 314_572_800 }.map { $0.id })
        careBigBytes = l.total
        careBigCount = l.items.count

        let t = await tT.value
        trash = t
        careTrashBytes = t.total

        let a = await aT.value
        apps = a
        careAppsCount = a.items.count

        careText = ""
        carePhase = .done
    }

    /// Aplica tudo o que está marcado — caches + arquivos grandes (+ Lixeira, opcional).
    func applyCare(cleanTrashAfter: Bool) async {
        let junkPicked = junk.items.filter { junkSelection.contains($0.id) && $0.deletable }
        let largePicked = larges.items.filter { largeSelection.contains($0.id) && $0.deletable }
        let picked = junkPicked + largePicked
        guard !picked.isEmpty else {
            notify("Nenhum item selecionado para a limpeza.")
            return
        }
        let freed = picked.reduce(Int64(0)) { $0 + $1.sizeBytes }
        carePhase = .running
        careText = "Movendo \(picked.count) item(ns) para a Lixeira…"
        let urls = picked.map { $0.url }
        let failed = await Task.detached(priority: .userInitiated) { Engine.moveToTrash(urls) }.value
        let failedCount = failed
        var note = "Limpeza concluída: \(fmtBytes(freed)) em \(picked.count - failedCount) item(ns) — na Lixeira até esvaziar."
        if cleanTrashAfter {
            let left = await Task.detached(priority: .userInitiated) { Engine.emptyTrash() }.value
            note += left == 0 ? " Lixeira esvaziada." : " \(left) item(ns) não puderam ser apagados."
        }
        lastCareFreed = freed
        lastCareFailed = failedCount
        lastCareNote = note

        // atualização silenciosa em paralelo para manter todas as abas coerentes
        let jT = Task.detached(priority: .userInitiated) { Engine.scanCaches() }
        let lT = Task.detached(priority: .userInitiated) { Engine.scanLargeFiles() }
        let tT = Task.detached(priority: .userInitiated) { Engine.scanTrash() }
        let j = await jT.value
        junk = j
        junkSelection = Set(j.items.filter { $0.deletable && $0.sizeBytes >= 131_072_000 }.map { $0.id })
        careJunkBytes = j.total
        careJunkCount = j.items.filter { $0.deletable }.count
        let l = await lT.value
        larges = l
        largeSelection = Set(l.items.filter { $0.deletable && $0.sizeBytes >= 314_572_800 }.map { $0.id })
        careBigBytes = l.total
        careBigCount = l.items.count
        trash = await tT.value
        careTrashBytes = trash.total

        careText = ""
        carePhase = .done
        notify(note)
    }

    /// Estatísticas de sistema (CPU, memória, térmico, processos).
    func refreshSystem() async {
        let (snap, disk) = await Task.detached(priority: .userInitiated) {
            (Engine.fetchSystem(), Engine.diskStatus())
        }.value
        sys = snap
        diskTotal = disk.total
        diskFree = disk.free
        let myPid = ProcessInfo.processInfo.processIdentifier
        accelSelection = Set(snap.procs.filter { p in
            p.mem >= 629_145_600 && p.pid != myPid && isGui(p.pid)
        }.map { $0.pid })
    }

    /// O pid pertence a um app GUI regular (encerrável por um usuário comum).
    func isGui(_ pid: Int32) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        return app.activationPolicy == .regular
    }

    func terminateSelectedApps() async {
        let pids = accelSelection
        guard !pids.isEmpty else { return }
        var ok = 0
        for pid in pids {
            if let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated, app.terminate() {
                ok += 1
            }
        }
        accelSelection = []
        notify(ok == 0
               ? "Nenhum aplicativo pôde ser encerrado (pode pedir para salvar ou ser do sistema)."
               : "\(ok) aplicativo(s) encerrado(s) normalmente.")
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await refreshSystem()
    }

    /// purge: libera caches de disco inativos (memória em uso vira mais folga).
    func purgeNow() async {
        lastPurgeNote = "Liberando caches em disco…"
        let note = await Task.detached(priority: .userInitiated) { () -> String in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
            let out = Pipe()
            p.standardOutput = out
            p.standardError = FileHandle.nullDevice
            do {
                try p.run()
                _ = out.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                return p.terminationStatus == 0
                    ? "Caches de disco liberados — memória reaproveitável devolvida ao sistema."
                    : "purge não pôde executar sem privilégios de administrador neste sistema."
            } catch {
                return "purge não pôde executar sem privilégios de administrador neste sistema."
            }
        }.value
        lastPurgeNote = note
        await refreshSystem()
    }

    func emptyTrashNow() async {
        confirmEmptyTrash = false
        let failed = await Task.detached(priority: .userInitiated) { Engine.emptyTrash() }.value
        notify(failed == 0 ? "Lixeira esvaziada." : "Lixeira esvaziada com \(failed) falha(s).")
        await scanTrash()
    }

    private func sendSummary(moved: Int, failed: Int, bytes: Int64) {
        if failed == 0 {
            notify("Movidos \(moved) item(ns) para a Lixeira — \(fmtBytes(bytes)).")
        } else {
            notify("Concluído com \(failed) falha(s) de \(moved + failed) item(ns).")
        }
    }
}

// MARK: - App

@main
struct NovaCleanApp: App {
    var body: some Scene {
        WindowGroup("NovaClean") {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject var st = Store()

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(st: st)
                .frame(width: 236)
                .background(Theme.sidebar)
            Rectangle().fill(LinearGradient.brandH).frame(width: 3).opacity(0.55)
            detail
        }
        .background(LinearGradient.deepspace)
        .preferredColorScheme(.dark)
        .frame(minWidth: 1040, minHeight: 680)
        .alert(isPresented: $st.showActionAlert) {
            Alert(title: Text("NovaClean"), message: Text(st.actionMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Esvaziar a Lixeira apaga os itens permanentemente.",
                            isPresented: $st.confirmEmptyTrash, titleVisibility: .visible) {
            Button("Esvaziar agora", role: .destructive) {
                Task { await st.emptyTrashNow() }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    @ViewBuilder
    var detail: some View {
        switch st.tab {
        case .care:  CareView(st: st)
        case .junk:  JunkView(st: st)
        case .large: LargeView(st: st)
        case .space: SpaceView(st: st)
        case .accel: AccelView(st: st)
        case .system: SystemView(st: st)
        case .apps:  AppsView(st: st)
        case .trash: TrashView(st: st)
        case .about: AboutView()
        }
    }
}

// MARK: - Components

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}

struct BrandChip: View {
    let systemName: String
    var gradient: Bool = false
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(gradient ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.white.opacity(0.06)))
            Image(systemName: systemName)
                .font(.system(size: size * 0.52, weight: .medium))
                .foregroundColor(gradient ? .white : Color.white.opacity(0.65))
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(gradient ? Color.white.opacity(0.18) : Theme.hairline, lineWidth: 1)
        )
    }
}

struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    var danger: Bool = false
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let s = systemImage {
                    Image(systemName: s)
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(AnyShapeStyle(danger
                        ? LinearGradient(colors: [Theme.danger, Theme.brandEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient.brand))
            )
            .foregroundColor(.white)
            .shadow(color: (danger ? Theme.danger : Theme.brandEnd).opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}

struct GhostButton: View {
    let title: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.cardSoft))
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                .foregroundColor(.white.opacity(0.9))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}

/// Cabeçalho de cada tela.
struct Header: View {
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var actionSystemImage: String? = nil
    var action: (() -> Void)? = nil
    var actionDisabled: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if let title = actionTitle, let action = action {
                PillButton(title: title, systemImage: actionSystemImage, disabled: actionDisabled) { action() }
            }
        }
        .padding(.bottom, 6)
    }
}

/// Toggle de seleção por linha (checkbox), compatível com macOS 12.
struct RowToggle: View {
    let isOn: Bool
    let disabled: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle("", isOn: Binding(
            get: { isOn },
            set: { onChange($0) }
        ))
        .labelsHidden()
        .toggleStyle(.checkbox)
        .disabled(disabled)
    }
}

struct RowShell<Content: View>: View {
    var selected: Bool = false
    var locked: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? Theme.cardSoft : Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? AnyShapeStyle(LinearGradient.brandH) : AnyShapeStyle(Theme.hairline), lineWidth: selected ? 1.5 : 1)
        )
    }
}

struct BarShare: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient.brandH)
                    .frame(width: max(3, geo.size.width * CGFloat(min(1, max(0, fraction)))))
            }
        }
        .frame(height: 5)
    }
}

/// Tag "sugestão" para itens pré-selecionados pelo motor de recomendação.
struct SuggestedTag: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
            Text("sugestão")
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(AnyShapeStyle(LinearGradient.brandH)))
    }
}

/// Botão Selecionar tudo ↔ Deselecionar tudo.
struct SelectAllToggle: View {
    let selectableIDs: [String]
    let selection: Set<String>
    let onChange: (Set<String>) -> Void

    private var allSelected: Bool {
        selectableIDs.count > 0 && selection.count >= selectableIDs.count
    }

    var body: some View {
        GhostButton(title: allSelected ? "Deselecionar tudo" : "Selecionar tudo", disabled: selectableIDs.isEmpty) {
            onChange(allSelected ? [] : Set(selectableIDs))
        }
    }
}

/// Barra empilhada por categoria (spectrum) com legenda.
struct SpectrumBar: View {
    let segments: [(label: String, bytes: Int64)]

    private var sum: Int64 { max(1, segments.reduce(Int64(0)) { $0 + $1.bytes }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                        let w = CGFloat(Double(seg.bytes) / Double(sum)) * geo.size.width
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Theme.spectrumColors[idx % Theme.spectrumColors.count])
                            .frame(width: max(6, w - 2))
                    }
                }
            }
            .frame(height: 10)
            HStack(spacing: 14) {
                ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.spectrumColors[idx % Theme.spectrumColors.count])
                            .frame(width: 8, height: 8)
                        Text("\(seg.label) · \(fmtBytes(seg.bytes))")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textDim)
                    }
                }
            }
        }
    }
}

/// Mapa de bolhas (orbit chart) — visual Space Lens da identidade Nova.
struct BubbleCanvas: View {
    let items: [DiskItem]
    let onClick: (DiskItem) -> Void

    var body: some View {
        GeometryReader { geo in
            let packed = Engine.packBubbles(bytes: items.map { Double(max(1, $0.sizeBytes)) })
            ZStack(alignment: .topLeading) {
                ForEach(Array(packed.enumerated()), id: \.offset) { idx, b in
                    let item = items[idx]
                    let px = CGFloat(b.cx) * geo.size.width
                    let py = CGFloat(b.cy) * geo.size.height
                    let g = CGFloat(min(geo.size.width, geo.size.height))
                    let rad = g / 2 * CGFloat(b.r) * 1.15
                    let grad = Theme.bubbleGradients[idx % Theme.bubbleGradients.count]
                    Button {
                        onClick(item)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text(item.name)
                                .font(.system(size: item.sizeBytes > 1_073_741_824 ? 11 : 10, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                                .padding(.horizontal, 5)
                            Text(fmtBytes(item.sizeBytes))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: rad * 2, height: rad * 2)
                        .background(
                            Circle()
                                .fill(AnyShapeStyle(grad))
                                .shadow(color: Theme.brandEnd.opacity(0.30), radius: 6, x: 0, y: 5)
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .position(x: px, y: py)
                }
            }
        }
    }
}

/// Linha de uso do disco: "Macintosh HD: X GB · Y livre" com barra de preenchimento.
struct DiskUsageLine: View {
    var title: String = "Macintosh HD"
    let total: Int64
    let free: Int64

    private var usedFraction: Double {
        guard total > 0, free >= 0 else { return 0 }
        return min(1, Double(total - free) / Double(total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text(total > 0 ? "· \(fmtBytes(total)) · \(fmtBytes(max(0, free))) livre" : "· capacidade indisponível")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(String(format: "%.0f%% em uso", usedFraction * 100))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(usedFraction > 0.9 ? Theme.danger : Theme.textDim)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(AnyShapeStyle(LinearGradient(colors: usedFraction > 0.9
                                ? [Theme.danger, Theme.brandEnd]
                                : Theme.brand,
                            startPoint: .leading, endPoint: .trailing)))
                        .frame(width: max(6, geo.size.width * CGFloat(usedFraction)))
                }
            }
            .frame(height: 7)
        }
    }
}

/// Dial do Cuidado Inteligente (anel com gradiente angular).
struct NovaDial: View {
    let fraction: Double
    let centerTitle: String
    let centerSub: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 18, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(min(0.998, max(0.01, fraction))))
                .stroke(
                    AngularGradient(colors: Theme.brand, center: .center),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.9), value: fraction)
            VStack(spacing: 2) {
                Text(centerTitle)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(centerSub)
                    .font(.caption)
                    .foregroundColor(Theme.textDim)
            }
        }
        .frame(width: 208, height: 208)
    }
}

struct RunningView: View {
    let text: String
    var body: some View {
        Card {
            VStack(spacing: 12) {
                NovaLogo(size: 34)
                    .shadow(color: Theme.brandEnd.opacity(0.4), radius: 10)
                Text(text.isEmpty ? "Analisando…" : text)
                    .font(.subheadline)
                    .foregroundColor(Theme.textDim)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
        }
    }
}

struct IdleView: View {
    let message: String
    var icon: String
    var body: some View {
        Card {
            VStack(spacing: 10) {
                NovaLogo(size: 56)
                    .shadow(color: Theme.brandEnd.opacity(0.4), radius: 14)
                Text(message)
                    .foregroundColor(Theme.textDim)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(30)
        }
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @ObservedObject var st: Store

    let items: [(Tab, String, String)] = [
        (.care,   "sparkles",                 "Cuidado Inteligente"),
        (.junk,   "bubbles.and.sparkles",     "Lixo do Sistema"),
        (.large,  "doc.text.magnifyingglass", "Arquivos Grandes"),
        (.space,  "internaldrive",            "Meu Espaço"),
        (.accel,  "hare.fill",                "Acelerar"),
        (.system, "memorychip",               "Sistema"),
        (.apps,   "shippingbox",              "Aplicativos"),
        (.trash,  "trash",                    "Lixeira"),
        (.about,  "info.circle",              "Sobre")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 10) {
                NovaLogo(size: 34)
                    .shadow(color: Theme.brandEnd.opacity(0.45), radius: 8, x: 0, y: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text("NovaClean")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Limpeza para o seu Mac")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)

            ForEach(items, id: \.0) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { st.tab = item.0 }
                } label: {
                    HStack(spacing: 10) {
                        BrandChip(systemName: item.1, gradient: st.tab == item.0)
                            .frame(width: 24, height: 24)
                            .offset(x: 0)
                        Text(item.2)
                            .font(.system(size: 13, weight: st.tab == item.0 ? .semibold : .regular))
                            .foregroundColor(st.tab == item.0 ? .white : Theme.textDim)
                        Spacer()
                        if st.tab == item.0 {
                            Circle().fill(LinearGradient.brandH).frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(st.tab == item.0 ? Color.white.opacity(0.06) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Divider().overlay(Theme.hairline)
                HStack(spacing: 6) {
                    Circle().fill(LinearGradient.brandH).frame(width: 7, height: 7)
                    Text("scans 100% locais · nada sai da sua máquina")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textDim)
                }
                Text("v1.1 · build local")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textDim.opacity(0.7))
            }
            .padding(10)
        }
        .padding(10)
    }
}

// MARK: - Cuidado Inteligente

struct CareView: View {
    @ObservedObject var st: Store

    private var rebound: (Int64, Double) {
        let cap = st.careDiskTotal
        let reclaimable = st.careJunkBytes + st.careTrashBytes
        guard cap > 0 else { return (reclaimable, 0.02) }
        return (reclaimable, Double(reclaimable) / Double(cap))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Header(title: "Cuidado Inteligente",
                   subtitle: "Analisa tudo em paralelo, já marca as sugestões e aplica em um clique — sem trocar de aba.",
                   actionTitle: "Analisar agora",
                   actionSystemImage: "sparkles",
                   action: { Task { await st.runCare() } },
                   actionDisabled: st.carePhase == .running)

            if st.carePhase == .running {
                RunningView(text: st.careText)
                Spacer()
            } else if st.carePhase == .done {
                ScrollView {
                    VStack(spacing: 14) {
                        Card {
                            HStack(spacing: 26) {
                                NovaDial(fraction: rebound.1,
                                         centerTitle: fmtBytes(rebound.0),
                                         centerSub: "liberação potencial")
                                VStack(alignment: .leading, spacing: 12) {
                                    CareRow(icon: "checkmark.circle.fill", color: Theme.okGreen,
                                            label: "Lixo do Sistema", detail: "\(fmtBytes(st.careJunkBytes)) · \(st.careJunkCount) itens")
                                    CareRow(icon: "checkmark.circle.fill", color: Theme.okGreen,
                                            label: "Arquivos grandes", detail: "\(st.careBigCount) ≥ 50 MB")
                                    CareRow(icon: "checkmark.circle.fill", color: Theme.okGreen,
                                            label: "Lixeira", detail: fmtBytes(st.careTrashBytes))
                                    CareRow(icon: "checkmark.circle.fill", color: Theme.okGreen,
                                            label: "Aplicativos", detail: "\(st.careAppsCount) inventariados")
                                }
                            }
                            .padding(22)
                        }
                        HStack(spacing: 14) {
                            MetricCard(title: "Liberável em caches", value: fmtBytes(st.careJunkBytes),
                                       sub: "\(st.careJunkCount) itens", icon: "bubbles.and.sparkles") { st.tab = .junk }
                            MetricCard(title: "Arquivos grandes", value: fmtBytes(st.careBigBytes),
                                       sub: "\(st.careBigCount) arquivos", icon: "doc.text.magnifyingglass") { st.tab = .large }
                            MetricCard(title: "Lixeira", value: fmtBytes(st.careTrashBytes),
                                       sub: "\(st.trash.count) itens", icon: "trash") { st.tab = .trash }
                            MetricCard(title: "Aplicativos", value: "\(st.careAppsCount)",
                                       sub: "inventário completo", icon: "shippingbox") { st.tab = .apps }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Categorias acima do mínimo de limpeza", systemImage: "chart.pie")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                SpectrumBar(segments: [
                                    ("Lixo", st.careJunkBytes),
                                    ("Grandes", st.careBigBytes),
                                    ("Lixeira", st.careTrashBytes),
                                    ("Apps", st.apps.total)
                                ])
                                DiskUsageLine(total: st.diskTotal, free: st.diskFree)
                            }
                            .padding(6)
                        }
                        careActionCard
                        suggestionSections
                    }
                }
            } else {
                IdleView(message: "Nenhuma análise rodou ainda.\nClique em “Analisar agora” para o resumo completo.", icon: "sparkles")
                Spacer()
            }
        }
        .padding(24)
    }

    private var junkSuggested: [DiskItem] {
        st.junk.items.filter { $0.deletable && $0.sizeBytes >= 131_072_000 }
    }

    private var largeSuggested: [DiskItem] {
        st.larges.items.filter { $0.deletable && $0.sizeBytes >= 314_572_800 }
    }

    private var pickedCount: Int { st.junkSelection.count + st.largeSelection.count }

    private var pickedBytes: Int64 {
        st.junk.items.filter { st.junkSelection.contains($0.id) }.reduce(Int64(0)) { $0 + $1.sizeBytes }
            + st.larges.items.filter { st.largeSelection.contains($0.id) }.reduce(Int64(0)) { $0 + $1.sizeBytes }
    }

    @ViewBuilder
    private var careActionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Um clique aplica tudo")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(pickedCount) item(ns) marcados · \(fmtBytes(pickedBytes)) a mover — aperte e pronto.")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                    }
                    Spacer()
                    PillButton(title: "Aplicar limpeza",
                               systemImage: "bolt.fill",
                               disabled: pickedCount == 0 || st.carePhase == .running) {
                        Task { await st.applyCare(cleanTrashAfter: st.careFreeTrash) }
                    }
                }
                HStack(spacing: 8) {
                    RowToggle(isOn: st.careFreeTrash, disabled: false, onChange: { st.careFreeTrash = $0 })
                    Text("Esvaziar a Lixeira ao concluir (irreversível)")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                    Spacer()
                }
                if !st.lastCareNote.isEmpty {
                    Text(st.lastCareNote)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.okGreen)
                }
                if st.lastCareFailed > 0 {
                    Text("\(st.lastCareFailed) item(ns) ficaram para trás (em uso ou protegidos pelo sistema).")
                        .font(.caption2)
                        .foregroundColor(Theme.danger)
                }
            }
        }
    }

    @ViewBuilder
    private var suggestionSections: some View {
        Card {
            VStack(alignment: .leading, spacing: 9) {
                Label("Sugestões — Lixo do Sistema (≥128 MB)", systemImage: "bubbles.and.sparkles")
                    .font(.headline)
                    .foregroundColor(.white)
                if junkSuggested.isEmpty {
                    Text("Nada acima do limiar nas caches agora.")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
                ForEach(junkSuggested) { item in
                    PickRow(title: item.name, bytes: item.sizeBytes,
                            isOn: st.junkSelection.contains(item.id)) { on in
                        if on { st.junkSelection.insert(item.id) } else { st.junkSelection.remove(item.id) }
                    }
                }
            }
        }
        Card {
            VStack(alignment: .leading, spacing: 9) {
                Label("Sugestões — Arquivos Grandes (≥300 MB)", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                    .foregroundColor(.white)
                if largeSuggested.isEmpty {
                    Text("Nenhum arquivo ≥ 300 MB no Radar agora.")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
                ForEach(largeSuggested) { item in
                    PickRow(title: item.name, bytes: item.sizeBytes,
                            isOn: st.largeSelection.contains(item.id)) { on in
                        if on { st.largeSelection.insert(item.id) } else { st.largeSelection.remove(item.id) }
                    }
                }
            }
        }
    }
}

struct CareRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.callout).foregroundColor(.white)
                Text(detail).font(.caption).foregroundColor(Theme.textDim)
            }
        }
    }
}

/// Linha selectable da ação única (sugestões pré-marcadas).
struct PickRow: View {
    let title: String
    let bytes: Int64
    let isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        HStack(spacing: 9) {
            RowToggle(isOn: isOn, disabled: false, onChange: onChange)
            Image(systemName: "doc")
                .font(.system(size: 11))
                .foregroundColor(Theme.textDim)
            Text(title)
                .lineLimit(1)
                .font(.callout)
                .foregroundColor(.white)
            Spacer()
            Text(fmtBytes(bytes))
                .font(.callout.monospacedDigit())
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let sub: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                BrandChip(systemName: icon, gradient: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundColor(Theme.textDim)
                    Text(value)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(sub).font(.caption).foregroundColor(Theme.textDim)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lixo do Sistema

struct JunkView: View {
    @ObservedObject var st: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Header(title: "Lixo do Sistema",
                   subtitle: "Caches de aplicativos do usuário (removíveis → Lixeira). Caches de sistema aparecem apenas como informação.",
                   actionTitle: "Analisar",
                   actionSystemImage: "magnifyingglass",
                   action: { Task { await st.scanJunk() } },
                   actionDisabled: st.junk.phase == .running)
            if st.junk.phase == .running {
                RunningView(text: st.junk.progressText)
                Spacer()
            } else if st.junk.phase == .done {
                HStack {
                    Text("\(fmtBytes(st.junk.total)) em \(st.junk.items.count) componentes")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    SelectAllToggle(
                        selectableIDs: st.junk.items.filter { $0.deletable }.map { $0.id },
                        selection: st.junkSelection,
                        onChange: { st.junkSelection = $0 }
                    )
                    PillButton(title: "Limpar selecionados (\(st.junkSelection.count))",
                               systemImage: "trash",
                               disabled: st.junkSelection.isEmpty) {
                        Task { await st.cleanJunkSelection() }
                    }
                }
                ScrollView {
                    VStack(spacing: 7) {
                        ForEach(st.junk.items) { item in
                            RowShell(selected: st.junkSelection.contains(item.id), locked: !item.deletable) {
                                RowToggle(isOn: st.junkSelection.contains(item.id),
                                          disabled: !item.deletable) { on in
                                    if on { st.junkSelection.insert(item.id) }
                                    else { st.junkSelection.remove(item.id) }
                                }
                                BrandChip(systemName: "bubble.left.and.bubble.right", gradient: false, size: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.name).lineLimit(1).foregroundColor(.white)
                                        if item.deletable && item.sizeBytes >= 131_072_000 {
                                            SuggestedTag()
                                        }
                                        if !item.deletable {
                                            Label("somente informação", systemImage: "lock")
                                                .font(.caption2)
                                                .foregroundColor(Theme.textDim)
                                        }
                                    }
                                    Text(item.pathDisplay)
                                        .font(.caption)
                                        .foregroundColor(Theme.textDim)
                                        .lineLimit(1)
                                    if st.junk.total > 0 {
                                        BarShare(fraction: Double(item.sizeBytes) / Double(st.junk.total))
                                            .frame(width: 120)
                                    }
                                }
                                Spacer()
                                Text(fmtBytes(item.sizeBytes))
                                    .font(.callout.monospacedDigit())
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
            } else {
                IdleView(message: "Clique em “Analisar” para medir as pastas de cache.", icon: "magnifyingglass")
                Spacer()
            }
        }
        .padding(24)
    }
}

// MARK: - Arquivos Grandes

struct LargeView: View {
    @ObservedObject var st: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Header(title: "Arquivos Grandes",
                   subtitle: "Arquivos ≥ 50 MB em Desktop, Documentos, Downloads, Filmes, Música e Imagens.",
                   actionTitle: "Analisar",
                   actionSystemImage: "magnifyingglass",
                   action: { Task { await st.scanLarges() } },
                   actionDisabled: st.larges.phase == .running)
            if st.larges.phase == .running {
                RunningView(text: st.larges.progressText)
                Spacer()
            } else if st.larges.phase == .done {
                HStack {
                    Text("\(st.larges.items.count) arquivos — \(fmtBytes(st.larges.total))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    SelectAllToggle(
                        selectableIDs: st.larges.items.map { $0.id },
                        selection: st.largeSelection,
                        onChange: { st.largeSelection = $0 }
                    )
                    GhostButton(title: "Revelar", disabled: st.largeSelection.isEmpty) {
                        if let first = st.larges.items.first(where: { st.largeSelection.contains($0.id) }) {
                            Engine.revealInFinder(first.url)
                        }
                    }
                    PillButton(title: "Mover (\(st.largeSelection.count))",
                               systemImage: "trash",
                               disabled: st.largeSelection.isEmpty) {
                        Task { await st.cleanLargeSelection() }
                    }
                }
                ScrollView {
                    VStack(spacing: 7) {
                        ForEach(st.larges.items) { item in
                            RowShell(selected: st.largeSelection.contains(item.id)) {
                                RowToggle(isOn: st.largeSelection.contains(item.id),
                                          disabled: false) { on in
                                    if on { st.largeSelection.insert(item.id) }
                                    else { st.largeSelection.remove(item.id) }
                                }
                                BrandChip(systemName: "doc", gradient: false, size: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.name).lineLimit(1).foregroundColor(.white)
                                        if item.sizeBytes >= 314_572_800 {
                                            SuggestedTag()
                                        }
                                    }
                                    Text(item.pathDisplay)
                                        .font(.caption)
                                        .foregroundColor(Theme.textDim)
                                        .lineLimit(1)
                                    if st.larges.total > 0 {
                                        BarShare(fraction: Double(item.sizeBytes) / Double(st.larges.total))
                                            .frame(width: 120)
                                    }
                                }
                                Spacer()
                                Text(fmtDate(item.modified))
                                    .font(.caption)
                                    .foregroundColor(Theme.textDim)
                                Text(fmtBytes(item.sizeBytes))
                                    .font(.callout.monospacedDigit())
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
            } else {
                IdleView(message: "Clique em “Analisar” para localizar arquivos grandes.", icon: "magnifyingglass")
                Spacer()
            }
        }
        .padding(24)
    }
}

// MARK: - Meu Espaço

struct SpaceView: View {
    @ObservedObject var st: Store

    private var homePath: String { FileManager.default.homeDirectoryForCurrentUser.path }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meu Espaço")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                    Text(breadcrumb)
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                        .lineLimit(1)
                    if st.space.total > 0 {
                        Text("Escopo: \(fmtBytes(st.space.total))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                if st.spaceScope.path != homePath {
                    GhostButton(title: "Voltar", disabled: false) {
                        Task { await st.scanSpace(at: st.spaceScope.deletingLastPathComponent()) }
                    }
                }
                GhostButton(title: "Atualizar", disabled: st.space.phase == .running) {
                    Task { await st.scanSpace() }
                }
            }
            if st.diskTotal > 0 {
                DiskUsageLine(total: st.diskTotal, free: st.diskFree)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            if st.space.phase == .running {
                RunningView(text: st.space.progressText)
                Spacer()
            } else if st.space.phase == .done {
                ScrollView {
                    VStack(spacing: 14) {
                        if !st.space.items.isEmpty {
                            Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Mapa do espaço — clique num bloco para descer", systemImage: "square.grid.3x3")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    TreemapView(items: st.space.items, onClick: { item in
                                        Task { await st.scanSpace(at: item.url) }
                                    })
                                    .frame(height: 380)
                                }
                                .padding(8)
                            }
                        }
                        HStack(alignment: .top, spacing: 14) {
                            Card {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Pastas", systemImage: "folder")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    if st.space.items.isEmpty {
                                        Text("Sem subpastas neste nível.")
                                            .font(.caption)
                                            .foregroundColor(Theme.textDim)
                                    }
                                    ForEach(st.space.items.prefix(20)) { item in
                                        Button {
                                            Task { await st.scanSpace(at: item.url) }
                                        } label: {
                                            HStack(spacing: 10) {
                                                BrandChip(systemName: "folder", gradient: false, size: 28)
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.name).lineLimit(1).foregroundColor(.white)
                                                    BarShare(fraction: share(item.sizeBytes))
                                                }
                                                Spacer()
                                                Text(fmtBytes(item.sizeBytes))
                                                    .font(.callout.monospacedDigit())
                                                    .foregroundColor(.white.opacity(0.9))
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(Theme.cardSoft)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(Theme.hairline, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    if st.space.items.count > 20 {
                                        Text("+ \(st.space.items.count - 20) pastas menores (veja no mapa acima)")
                                            .font(.caption2)
                                            .foregroundColor(Theme.textDim)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 14) {
                                if st.spaceBigFiles.count > 0 {
                                    Card {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Label("Destaques (≥100 MB aqui)", systemImage: "star")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            ForEach(st.spaceBigFiles.prefix(10)) { f in
                                                HStack(spacing: 8) {
                                                    Image(systemName: "doc")
                                                        .foregroundColor(Theme.textDim)
                                                    Text(f.name)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Text(fmtBytes(f.sizeBytes))
                                                        .font(.callout.monospacedDigit())
                                                        .foregroundColor(.white.opacity(0.9))
                                                    Text("Remover")
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(Theme.danger)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 3)
                                                        .background(Capsule().stroke(Theme.danger.opacity(0.45), lineWidth: 1))
                                                        .contentShape(Rectangle())
                                                        .onTapGesture {
                                                            Task { await st.cleanSpaceFiles([f]) }
                                                        }
                                                }
                                                .font(.caption)
                                            }
                                        }
                                    }
                                }
                                Card {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Arquivos neste nível", systemImage: "doc")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        if st.spaceTopFiles.isEmpty {
                                            Text("Nenhum arquivo solto neste nível.")
                                                .font(.caption)
                                                .foregroundColor(Theme.textDim)
                                        }
                                        ForEach(st.spaceTopFiles.prefix(16)) { f in
                                            HStack {
                                                Image(systemName: "doc")
                                                Text(f.name).lineLimit(1)
                                                Spacer()
                                                Text(fmtBytes(f.sizeBytes)).font(.callout.monospacedDigit())
                                            }
                                            .font(.caption)
                                            .foregroundColor(Theme.textDim)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            } else {
                IdleView(message: "Clique em “Atualizar” para visualizar o que ocupa o disco.", icon: "internaldrive")
                Spacer()
            }
        }
        .padding(24)
        .onAppear {
            if st.space.phase == .idle {
                Task { await st.scanSpace() }
            }
        }
    }

    private var breadcrumb: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let p = st.spaceScope.path
        if p == home { return "home" }
        if p.hasPrefix(home) {
            return "home" + p.dropFirst(home.count).replacingOccurrences(of: "/", with: " › ")
        }
        return p.replacingOccurrences(of: "/", with: " › ")
    }

    private func share(_ bytes: Int64) -> Double {
        guard st.space.total > 0 else { return 0 }
        return Double(bytes) / Double(st.space.total)
    }
}

/// Treemap squarified — mapa de áreas sem sobreposição (estilo "Space View" da identidade Nova).
struct TreemapView: View {
    let items: [DiskItem]
    let onClick: (DiskItem) -> Void

    var body: some View {
        GeometryReader { geo in
            let rects = Engine.squarify(bytesArr: items.map { max(1, $0.sizeBytes) },
                                        frame: CGRect(origin: .zero, size: geo.size))
            ZStack(alignment: .topLeading) {
                ForEach(Array(rects.enumerated()), id: \.offset) { idx, r in
                    let item = items[idx]
                    let grad = Theme.bubbleGradients[idx % Theme.bubbleGradients.count]
                    let big = r.width > 92 && r.height > 54
                    Button {
                        onClick(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: big ? 13 : 10, weight: .semibold))
                                Text(item.name)
                                    .font(.system(size: big ? 12 : 10, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if big {
                                Text(fmtBytes(item.sizeBytes))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(6)
                        .foregroundColor(.white)
                        .frame(width: max(1, r.width), height: max(1, r.height), alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AnyShapeStyle(grad))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: max(1, r.width), height: max(1, r.height))
                    .position(x: r.midX, y: r.midY)
                }
            }
        }
    }
}

// MARK: - Acelerar

struct AccelView: View {
    @ObservedObject var st: Store

    private var myPid: Int32 { ProcessInfo.processInfo.processIdentifier }

    private var heavyApps: [SysProc] {
        st.sys.procs.filter { $0.mem >= 104_857_600 }
    }

    private var selectableApps: [Int32] {
        heavyApps.filter { st.isGui($0.pid) && $0.pid != myPid }.map { $0.pid }
    }

    private var ramFree: Int64 { max(0, st.sys.ramTotal - st.sys.ramUsed) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Header(title: "Acelerar",
                   subtitle: "Encerra aplicativos pesados que você escolher (quit normal) e tenta devolver caches de disco ao sistema.",
                   actionTitle: "Atualizar",
                   actionSystemImage: "arrow.clockwise",
                   action: { Task { await st.refreshSystem() } },
                   actionDisabled: false)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    DiskUsageLine(title: "Memória física", total: st.sys.ramTotal, free: ramFree)
                    HStack {
                        Text(st.sys.ramTotal > 0
                             ? "\(fmtBytes(st.sys.ramUsed)) em uso · \(fmtBytes(max(0, st.sys.ramUnused))) imediatamente livre"
                             : "Carregando memória…")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                        Spacer()
                        GhostButton(title: "Liberar caches (purge)", disabled: false) {
                            Task { await st.purgeNow() }
                        }
                    }
                    if !st.lastPurgeNote.isEmpty {
                        Text(st.lastPurgeNote)
                            .font(.caption)
                            .foregroundColor(st.lastPurgeNote.contains("não pôde") ? Theme.danger : Theme.okGreen)
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Aplicativos em memória (≥100 MB)", systemImage: "memorychip")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        GhostButton(title: (st.accelSelection.count >= selectableApps.count && !selectableApps.isEmpty)
                                    ? "Deselecionar tudo" : "Selecionar todos",
                                    disabled: selectableApps.isEmpty) {
                            st.accelSelection = (st.accelSelection.count >= selectableApps.count && !selectableApps.isEmpty)
                                ? [] : Set(selectableApps)
                        }
                    }
                    if heavyApps.isEmpty {
                        Text("Nenhum aplicativo acima de 100 MB neste momento.")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                    }
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(heavyApps.prefix(24)) { p in
                                let gui = st.isGui(p.pid)
                                let mine = p.pid == myPid
                                let sel = st.accelSelection.contains(p.pid)
                                HStack(spacing: 9) {
                                    RowToggle(isOn: sel,
                                              disabled: !gui || mine,
                                              onChange: { on in
                                        if on { st.accelSelection.insert(p.pid) }
                                        else { st.accelSelection.remove(p.pid) }
                                    })
                                    BrandChip(systemName: gui ? "app" : "gearshape.fill", gradient: false, size: 26)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(p.name)
                                            .lineLimit(1)
                                            .font(.callout)
                                            .foregroundColor(.white)
                                        Text("\(pct1(p.cpu)) CPU · pid \(p.pid)")
                                            .font(.caption2)
                                            .foregroundColor(Theme.textDim)
                                    }
                                    Spacer()
                                    if mine {
                                        Text("este app")
                                            .font(.caption2)
                                            .foregroundColor(Theme.textDim)
                                    } else if !gui {
                                        Text("sistema")
                                            .font(.caption2)
                                            .foregroundColor(Theme.textDim)
                                    }
                                    Text(fmtBytes(p.mem))
                                        .font(.callout.monospacedDigit())
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(AnyShapeStyle(sel ? AnyShapeStyle(Theme.cardSoft) : AnyShapeStyle(Theme.card)))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(sel ? AnyShapeStyle(LinearGradient.brandH) : AnyShapeStyle(Theme.hairline),
                                                lineWidth: sel ? 1.5 : 1)
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
            }

            HStack {
                Spacer()
                PillButton(title: "Encerrar selecionados (\(st.accelSelection.count))",
                           systemImage: "xmark.circle",
                           danger: true,
                           disabled: st.accelSelection.isEmpty) {
                    Task { await st.terminateSelectedApps() }
                }
            }
            Text("Sugestões (≥600 MB) já vêm marcadas. O encerramento é o quit normal — apps podem pedir para salvar. Processos de sistema nunca são encerrados.")
                .font(.caption)
                .foregroundColor(Theme.textDim)
        }
        .padding(24)
        .onAppear {
            if st.sys.procs.isEmpty {
                Task { await st.refreshSystem() }
            }
        }
    }
}

// MARK: - Sistema

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                BrandChip(systemName: icon, gradient: true, size: 26)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.textDim)
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(sub)
                .font(.caption)
                .foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

struct SystemView: View {
    @ObservedObject var st: Store

    private var busyCpu: Int {
        Int(max(0, min(100, 100 - st.sys.cpuIdle)))
    }

    private var diskUsePct: Int {
        guard st.diskTotal > 0, st.diskFree >= 0 else { return 0 }
        return Int(100 * Double(st.diskTotal - st.diskFree) / Double(st.diskTotal))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Header(title: "Sistema",
                   subtitle: "Saúde do Mac: processador, memória, estado térmico e disco — atualiza sozinho a cada 6 s.",
                   actionTitle: "Atualizar",
                   actionSystemImage: "arrow.clockwise",
                   action: { Task { await st.refreshSystem() } },
                   actionDisabled: false)
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        StatCard(icon: "cpu",
                                 title: "Processador",
                                 value: "\(busyCpu)%",
                                 sub: "user \(pct1(st.sys.cpuUser)) · sys \(pct1(st.sys.cpuSys)) · ocioso \(pct1(st.sys.cpuIdle))")
                        StatCard(icon: "memorychip",
                                 title: "Memória",
                                 value: st.sys.ramTotal > 0 ? fmtBytes(st.sys.ramUsed) : "…",
                                 sub: st.sys.ramTotal > 0
                                     ? "de \(fmtBytes(st.sys.ramTotal)) · livre \(fmtBytes(st.sys.ramUnused))"
                                     : "calculando…")
                    }
                    HStack(spacing: 14) {
                        StatCard(icon: "thermometer",
                                 title: "Estado térmico",
                                 value: st.sys.thermalText,
                                 sub: st.sys.thermalLevel >= 0
                                     ? "nível \(st.sys.thermalLevel) do kernel (xcpm)"
                                     : "sem leitura térmica neste modelo")
                        StatCard(icon: "internaldrive",
                                 title: "Disco",
                                 value: st.diskTotal > 0 ? fmtBytes(st.diskTotal) : "…",
                                 sub: st.diskTotal > 0
                                     ? "livre \(fmtBytes(max(0, st.diskFree))) · \(diskUsePct)% em uso"
                                     : "—")
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            DiskUsageLine(total: st.diskTotal, free: st.diskFree)
                            DiskUsageLine(title: "Memória",
                                          total: st.sys.ramTotal,
                                          free: max(0, st.sys.ramTotal - st.sys.ramUsed))
                        }
                        .padding(6)
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Top memória — processos ativos", systemImage: "chart.bar.doc.horizontal")
                                .font(.headline)
                                .foregroundColor(.white)
                            if st.sys.procs.isEmpty {
                                Text("Carregando processos…")
                                    .font(.caption)
                                    .foregroundColor(Theme.textDim)
                            }
                            ForEach(st.sys.procs.prefix(18)) { p in
                                HStack(spacing: 8) {
                                    Text("\(p.pid)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Theme.textDim)
                                        .frame(width: 46, alignment: .leading)
                                    Text(p.name)
                                        .lineLimit(1)
                                        .font(.callout)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(pct1(p.cpu))
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(Theme.textDim)
                                    Text(fmtBytes(p.mem))
                                        .font(.callout.monospacedDigit())
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            if st.sys.procs.count > 18 {
                                Text("… \(st.sys.procs.count - 18) outros processos")
                                    .font(.caption2)
                                    .foregroundColor(Theme.textDim)
                            }
                            HStack {
                                Spacer()
                                Text("Para encerrar aplicativos pesados, use a aba Acelerar.")
                                    .font(.caption2)
                                    .foregroundColor(Theme.textDim)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .onAppear {
            if st.sys.procs.isEmpty {
                Task { await st.refreshSystem() }
            }
        }
        .onReceive(Timer.publish(every: 6, on: .main, in: .common).autoconnect()) { _ in
            Task { await st.refreshSystem() }
        }
    }
}

// MARK: - Aplicativos

struct AppsView: View {
    @ObservedObject var st: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Header(title: "Aplicativos",
                   subtitle: "Inventário de /Applications e ~/Applications com versão e tamanho. “Desinstalar” move o .app para a Lixeira.",
                   actionTitle: "Analisar",
                   actionSystemImage: "magnifyingglass",
                   action: { Task { await st.scanApps() } },
                   actionDisabled: st.apps.phase == .running)
            if st.apps.phase == .running {
                RunningView(text: st.apps.progressText)
                Spacer()
            } else if st.apps.phase == .done {
                HStack {
                    Text("\(st.apps.items.count) apps — \(fmtBytes(st.apps.total))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                ScrollView {
                    VStack(spacing: 7) {
                        ForEach(st.apps.items) { item in
                            RowShell {
                                BrandChip(systemName: "app", gradient: false, size: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).lineLimit(1).foregroundColor(.white)
                                    Text(item.pathDisplay)
                                        .font(.caption)
                                        .foregroundColor(Theme.textDim)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if let v = item.version {
                                    Text("v\(v)")
                                        .font(.caption)
                                        .foregroundColor(Theme.textDim)
                                }
                                Text(fmtBytes(item.sizeBytes))
                                    .font(.callout.monospacedDigit())
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(minWidth: 90, alignment: .trailing)
                                GhostButton(title: "Revelar", disabled: false) {
                                    Engine.revealInFinder(item.url)
                                }
                                Button("Desinstalar") {
                                    Task { await st.uninstall(item) }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.danger)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().stroke(Theme.danger.opacity(0.45), lineWidth: 1))
                            }
                        }
                    }
                }
            } else {
                IdleView(message: "Clique em “Analisar” para inventariar aplicativos.", icon: "shippingbox")
                Spacer()
            }
        }
        .padding(24)
    }
}

// MARK: - Lixeira

struct TrashView: View {
    @ObservedObject var st: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Header(title: "Lixeira",
                   subtitle: "Itens aguardando exclusão em ~/.Trash.",
                   actionTitle: "Atualizar",
                   actionSystemImage: "arrow.clockwise",
                   action: { Task { await st.scanTrash() } },
                   actionDisabled: st.trash.phase == .running)
            if st.trash.phase == .running {
                RunningView(text: "Dimensionando a Lixeira…")
                Spacer()
            } else if st.trash.phase == .done {
                Card {
                    HStack(spacing: 44) {
                        BrandChip(systemName: "trash", gradient: true, size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Itens").font(.caption).foregroundColor(Theme.textDim)
                            Text("\(st.trash.count)")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tamanho").font(.caption).foregroundColor(Theme.textDim)
                            Text(fmtBytes(st.trash.total))
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        PillButton(title: "Esvaziar Lixeira",
                                   systemImage: "trash.slash",
                                   danger: true,
                                   disabled: st.trash.count == 0) {
                            st.confirmEmptyTrash = true
                        }
                    }
                    .padding(22)
                }
                Spacer()
            } else {
                IdleView(message: "Clique em “Atualizar” para dimensionar a Lixeira.", icon: "trash")
                Spacer()
            }
        }
        .padding(24)
        .onAppear {
            if st.trash.phase == .idle {
                Task { await st.scanTrash() }
            }
        }
    }
}

// MARK: - Sobre

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            NovaLogo(size: 64)
                                .shadow(color: Theme.brandEnd.opacity(0.5), radius: 16)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("NovaClean")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text("v1.1 “Nova” · identidade própria")
                                    .foregroundColor(Theme.textDim)
                            }
                        }
                        Divider().overlay(Theme.hairline)
                        Text("""
                        Uma nova é uma estrela que volta a brilhar — a metáfora do app: seu Mac limpo e leve de novo. Tudo aqui é original: nomes, ícone, gradientes e código. Nenhum código, asset ou conteúdo da MacPaw foi replicado.
                        """)
                        .font(.callout)
                        .foregroundColor(Theme.textDim)
                        HStack(spacing: 8) {
                            ForEach(Theme.brand, id: \.self) { c in
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(c)
                                    .frame(width: 26, height: 26)
                            }
                            Spacer()
                            Text("#7A2CFF → #A52CFF → #FF3E8E")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                }
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Cuidado Inteligente — orquestra 4 varreduras e resume o liberável num dial.", systemImage: "sparkles")
                        Label("Lixo do Sistema — mede ~/Library/Caches (remoção) e /Library/Caches (informativo).", systemImage: "bubbles.and.sparkles")
                        Label("Arquivos Grandes — varre pastas do usuário por arquivos ≥ 50 MB.", systemImage: "doc.text.magnifyingglass")
                        Label("Meu Espaço — visualiza por pastas com drill-down e destaques ≥ 100 MB.", systemImage: "internaldrive")
                        Label("Aplicativos — inventário com versão/tamanho; desinstalação move para a Lixeira.", systemImage: "shippingbox")
                        Label("Lixeira — tamanho, contagem e esvaziar com confirmação.", systemImage: "trash")
                    }
                    .font(.callout)
                    .foregroundColor(Theme.textDim)
                }
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Origem e limites").font(.headline).foregroundColor(.white)
                        Text("""
                        Arquitetura de referência obtida por análise estática com REA (Info.plist, assinatura, entitlements, ~140 frameworks e strings de localização), documentada em blueprint-REA.md e IDENTITY.md. Fora de escopo consciente: remoção real de malware (motor Moonlock da MacPaw), leftovers de desinstalação, integrações de contas em nuvem, assistente IA local e apps antecessores de menu bar.
                        """)
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                        Text("Scans 100% locais — nenhuma informação sai do computador.")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.okGreen)
                    }
                }
            }
            .padding(24)
        }
    }
}
