// LocalizationManager.swift
// ApexUninstaller
// Đa ngôn ngữ: VI, EN, JA, KO, ZH-Hans, FR, DE, ES

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "简体中文"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        }
    }
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .vietnamese: return "🇻🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .spanish: return "🇪🇸"
        }
    }
}

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    var currentLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(currentLanguage.rawValue, forKey: "ApexUninstaller.language") }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "ApexUninstaller.language"), let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            let sys = Locale.current.language.languageCode?.identifier ?? "en"
            switch sys {
            case "vi": self.currentLanguage = .vietnamese
            case "ja": self.currentLanguage = .japanese
            case "ko": self.currentLanguage = .korean
            case "zh": self.currentLanguage = .chinese
            case "fr": self.currentLanguage = .french
            case "de": self.currentLanguage = .german
            case "es": self.currentLanguage = .spanish
            default: self.currentLanguage = .english
            }
        }
    }

    func localized(_ key: String) -> String { L10n.string(key, language: currentLanguage) }

    func localized(_ key: String, _ args: CVarArg...) -> String {
        let template = localized(key)
        guard !args.isEmpty else { return template }
        return String(format: template, locale: Locale(identifier: currentLanguage.rawValue), arguments: args)
    }
}

enum L10n {
    // Shorthand: [en, vi, ja, ko, zh, fr, de, es]
    private static let t: [String: [AppLanguage: String]] = [
        // Sidebar
        "sidebar.title": [.english: "Applications", .vietnamese: "Ứng dụng", .japanese: "アプリケーション", .korean: "응용 프로그램", .chinese: "应用程序", .french: "Applications", .german: "Programme", .spanish: "Aplicaciones"],
        "sidebar.appCount": [.english: "apps", .vietnamese: "ứng dụng", .japanese: "アプリ", .korean: "앱", .chinese: "应用", .french: "apps", .german: "Apps", .spanish: "apps"],
        "sidebar.search": [.english: "Search apps...", .vietnamese: "Tìm ứng dụng...", .japanese: "アプリを検索...", .korean: "앱 검색...", .chinese: "搜索应用...", .french: "Rechercher...", .german: "Apps suchen...", .spanish: "Buscar apps..."],
        "sidebar.scanButton": [.english: "Scan Applications", .vietnamese: "Quét ứng dụng", .japanese: "アプリをスキャン", .korean: "앱 스캔", .chinese: "扫描应用", .french: "Analyser", .german: "Scannen", .spanish: "Escanear"],
        "sidebar.emptyTitle": [.english: "Press scan to start", .vietnamese: "Nhấn nút quét để bắt đầu", .japanese: "スキャンを押して開始", .korean: "스캔을 눌러 시작", .chinese: "按扫描开始", .french: "Appuyez pour analyser", .german: "Zum Starten scannen", .spanish: "Pulse escanear"],
        "sidebar.emptySubtitle": [.english: "Scan applications in /Applications\nand ~/Applications", .vietnamese: "Quét ứng dụng trong /Applications\nvà ~/Applications", .japanese: "/Applicationsと\n~/Applicationsをスキャン", .korean: "/Applications 및\n~/Applications 스캔", .chinese: "扫描/Applications\n和~/Applications", .french: "Analyser les applications dans\n/Applications et ~/Applications", .german: "/Applications und\n~/Applications scannen", .spanish: "Escanear aplicaciones en\n/Applications y ~/Applications"],

        // Sort
        "sort.nameAsc": [.english: "Name (A-Z)", .vietnamese: "Tên (A-Z)", .japanese: "名前 (A-Z)", .korean: "이름 (A-Z)", .chinese: "名称 (A-Z)", .french: "Nom (A-Z)", .german: "Name (A-Z)", .spanish: "Nombre (A-Z)"],
        "sort.nameDesc": [.english: "Name (Z-A)", .vietnamese: "Tên (Z-A)", .japanese: "名前 (Z-A)", .korean: "이름 (Z-A)", .chinese: "名称 (Z-A)", .french: "Nom (Z-A)", .german: "Name (Z-A)", .spanish: "Nombre (Z-A)"],
        "sort.sizeDesc": [.english: "Size (Large→Small)", .vietnamese: "Dung lượng (Lớn→Nhỏ)", .japanese: "サイズ (大→小)", .korean: "크기 (큰→작은)", .chinese: "大小 (大→小)", .french: "Taille (Grand→Petit)", .german: "Größe (Groß→Klein)", .spanish: "Tamaño (Grande→Pequeño)"],
        "sort.sizeAsc": [.english: "Size (Small→Large)", .vietnamese: "Dung lượng (Nhỏ→Lớn)", .japanese: "サイズ (小→大)", .korean: "크기 (작은→큰)", .chinese: "大小 (小→大)", .french: "Taille (Petit→Grand)", .german: "Größe (Klein→Groß)", .spanish: "Tamaño (Pequeño→Grande)"],
        "sort.leftoverCount": [.english: "Leftover count", .vietnamese: "Số file rác", .japanese: "残留ファイル数", .korean: "잔여 파일 수", .chinese: "残留文件数", .french: "Nb de résidus", .german: "Restdateien", .spanish: "Archivos residuales"],

        // Detail
        "detail.leftovers": [.english: "leftovers", .vietnamese: "tệp rác", .japanese: "残留ファイル", .korean: "잔여 파일", .chinese: "残留文件", .french: "résidus", .german: "Restdateien", .spanish: "residuos"],
        "detail.total": [.english: "Total", .vietnamese: "Tổng", .japanese: "合計", .korean: "합계", .chinese: "总计", .french: "Total", .german: "Gesamt", .spanish: "Total"],
        "detail.uninstall": [.english: "Uninstall", .vietnamese: "Gỡ cài đặt", .japanese: "アンインストール", .korean: "제거", .chinese: "卸载", .french: "Désinstaller", .german: "Deinstallieren", .spanish: "Desinstalar"],
        "detail.reset": [.english: "Reset", .vietnamese: "Đặt lại", .japanese: "リセット", .korean: "재설정", .chinese: "重置", .french: "Réinitialiser", .german: "Zurücksetzen", .spanish: "Restablecer"],
        "detail.exportReport": [.english: "Export report", .vietnamese: "Xuất báo cáo", .japanese: "レポートを書き出す", .korean: "보고서 내보내기", .chinese: "导出报告", .french: "Exporter le rapport", .german: "Bericht exportieren", .spanish: "Exportar informe"],
        "detail.ignore": [.english: "Ignore this app", .vietnamese: "Bỏ qua app này", .japanese: "このアプリを無視", .korean: "이 앱 무시", .chinese: "忽略此应用", .french: "Ignorer cette app", .german: "Diese App ignorieren", .spanish: "Ignorar esta app"],
        "detail.removeApp": [.english: "Remove .app file", .vietnamese: "Xóa file .app", .japanese: ".appファイルを削除", .korean: ".app 파일 삭제", .chinese: "删除.app文件", .french: "Supprimer le .app", .german: ".app-Datei entfernen", .spanish: "Eliminar archivo .app"],
        "detail.selectRecommended": [.english: "Recommended", .vietnamese: "Đề xuất", .japanese: "推奨", .korean: "권장", .chinese: "推荐", .french: "Recommandé", .german: "Empfohlen", .spanish: "Recomendado"],
        "detail.selectAll": [.english: "Select All", .vietnamese: "Chọn tất cả", .japanese: "すべて選択", .korean: "모두 선택", .chinese: "全选", .french: "Tout sélectionner", .german: "Alle auswählen", .spanish: "Seleccionar todo"],
        "detail.deselectAll": [.english: "Deselect All", .vietnamese: "Bỏ chọn tất cả", .japanese: "すべて解除", .korean: "모두 해제", .chinese: "取消全选", .french: "Tout désélectionner", .german: "Alle abwählen", .spanish: "Deseleccionar todo"],
        "detail.selected": [.english: "selected", .vietnamese: "đã chọn", .japanese: "選択済み", .korean: "선택됨", .chinese: "已选择", .french: "sélectionné(s)", .german: "ausgewählt", .spanish: "seleccionado(s)"],
        "detail.reviewSelectedHelp": [.english: "Review items are selected. Check them before uninstalling.", .vietnamese: "Có mục cần xem kỹ đang được chọn.", .japanese: "確認が必要な項目が選択されています。", .korean: "검토 항목이 선택되었습니다.", .chinese: "已选择需要检查的项目。", .french: "Des éléments à vérifier sont sélectionnés.", .german: "Prüfelemente sind ausgewählt.", .spanish: "Hay elementos de revisión seleccionados."],
        "detail.reviewWarning": [.english: "Review items selected. Check file names before continuing.", .vietnamese: "Có mục cần xem kỹ đang được chọn. Hãy kiểm tra tên file trước khi tiếp tục.", .japanese: "確認が必要な項目が選択されています。続行前にファイル名を確認してください。", .korean: "검토 항목이 선택되었습니다. 계속하기 전에 파일 이름을 확인하세요.", .chinese: "已选择需要检查的项目。继续前请检查文件名。", .french: "Des éléments à vérifier sont sélectionnés. Vérifiez les noms avant de continuer.", .german: "Prüfelemente sind ausgewählt. Dateinamen vor dem Fortfahren prüfen.", .spanish: "Hay elementos de revisión seleccionados. Revise los nombres antes de continuar."],
        "detail.cleanApp": [.english: "App is clean!", .vietnamese: "Ứng dụng sạch!", .japanese: "アプリはクリーンです！", .korean: "앱이 깨끗합니다!", .chinese: "应用程序很干净！", .french: "L'app est propre !", .german: "App ist sauber!", .spanish: "¡La app está limpia!"],
        "detail.noLeftovers": [.english: "No leftover files found.", .vietnamese: "Không tìm thấy tệp rác nào.", .japanese: "残留ファイルは見つかりませんでした。", .korean: "잔여 파일이 없습니다.", .chinese: "未找到残留文件。", .french: "Aucun résidu trouvé.", .german: "Keine Restdateien gefunden.", .spanish: "No se encontraron residuos."],
        "detail.scanning": [.english: "Scanning for leftovers...", .vietnamese: "Đang quét tệp rác...", .japanese: "残留ファイルをスキャン中...", .korean: "잔여 파일 검색 중...", .chinese: "正在扫描残留文件...", .french: "Recherche de résidus...", .german: "Suche nach Restdateien...", .spanish: "Buscando residuos..."],

        // Scan
        "scan.apps": [.english: "Scanning applications...", .vietnamese: "Đang quét ứng dụng...", .japanese: "アプリをスキャン中...", .korean: "앱 스캔 중...", .chinese: "正在扫描应用...", .french: "Analyse des applications...", .german: "Scanne Anwendungen...", .spanish: "Escaneando aplicaciones..."],
        "scan.leftovers": [.english: "Searching for leftovers...", .vietnamese: "Đang tìm tệp rác...", .japanese: "残留ファイルを検索中...", .korean: "잔여 파일 검색 중...", .chinese: "搜索残留文件...", .french: "Recherche de résidus...", .german: "Suche nach Restdateien...", .spanish: "Buscando residuos..."],
        "scan.rescan": [.english: "Rescan", .vietnamese: "Quét lại", .japanese: "再スキャン", .korean: "다시 스캔", .chinese: "重新扫描", .french: "Réanalyser", .german: "Erneut scannen", .spanish: "Re-escanear"],
        "scan.rescanAll": [.english: "Rescan all applications", .vietnamese: "Quét lại toàn bộ ứng dụng", .japanese: "すべてのアプリを再スキャン", .korean: "모든 앱 다시 스캔", .chinese: "重新扫描所有应用", .french: "Réanalyser toutes les apps", .german: "Alle Apps erneut scannen", .spanish: "Re-escanear todas las apps"],
        "scanLocations.title": [.english: "Scan Folders", .vietnamese: "Thư mục quét", .japanese: "スキャンフォルダ", .korean: "스캔 폴더", .chinese: "扫描文件夹", .french: "Dossiers d'analyse", .german: "Scan-Ordner", .spanish: "Carpetas de escaneo"],
        "scanLocations.add": [.english: "Add Scan Folder...", .vietnamese: "Thêm thư mục quét...", .japanese: "スキャンフォルダを追加...", .korean: "스캔 폴더 추가...", .chinese: "添加扫描文件夹...", .french: "Ajouter un dossier...", .german: "Scan-Ordner hinzufügen...", .spanish: "Agregar carpeta..."],
        "scanLocations.remove": [.english: "Remove Folder", .vietnamese: "Bỏ thư mục", .japanese: "フォルダを削除", .korean: "폴더 제거", .chinese: "移除文件夹", .french: "Retirer le dossier", .german: "Ordner entfernen", .spanish: "Quitar carpeta"],
        "scanLocations.clear": [.english: "Clear Scan Folders", .vietnamese: "Xóa các thư mục quét", .japanese: "スキャンフォルダを消去", .korean: "스캔 폴더 지우기", .chinese: "清除扫描文件夹", .french: "Effacer les dossiers", .german: "Scan-Ordner löschen", .spanish: "Borrar carpetas"],
        "scanLocations.help": [.english: "Grant access to app folders such as /Users/Shared, Game folders, Steam libraries, or external drives.", .vietnamese: "Cấp quyền thư mục chứa app như /Users/Shared, thư mục Game, Steam library hoặc ổ ngoài.", .japanese: "/Users/Shared、ゲームフォルダ、Steamライブラリ、外部ドライブなどのアプリフォルダへのアクセスを許可します。", .korean: "/Users/Shared, 게임 폴더, Steam 라이브러리 또는 외장 드라이브 같은 앱 폴더 접근을 허용합니다.", .chinese: "授予对 /Users/Shared、游戏文件夹、Steam 库或外置硬盘等应用文件夹的访问权限。", .french: "Autorise l'accès aux dossiers d'apps comme /Users/Shared, jeux, bibliothèques Steam ou disques externes.", .german: "Gewährt Zugriff auf App-Ordner wie /Users/Shared, Spieleordner, Steam-Bibliotheken oder externe Laufwerke.", .spanish: "Concede acceso a carpetas de apps como /Users/Shared, juegos, bibliotecas Steam o discos externos."],
        "scanLocations.suggested": [.english: "Suggested folders", .vietnamese: "Thư mục gợi ý", .japanese: "おすすめフォルダ", .korean: "추천 폴더", .chinese: "建议文件夹", .french: "Dossiers suggérés", .german: "Vorgeschlagene Ordner", .spanish: "Carpetas sugeridas"],

        // Uninstall
        "uninstall.confirm.title": [.english: "Confirm Uninstall", .vietnamese: "Xác nhận gỡ cài đặt", .japanese: "アンインストールの確認", .korean: "제거 확인", .chinese: "确认卸载", .french: "Confirmer la désinstallation", .german: "Deinstallation bestätigen", .spanish: "Confirmar desinstalación"],
        "uninstall.confirm.button": [.english: "Uninstall & Move to Trash", .vietnamese: "Gỡ & Di chuyển vào Thùng rác", .japanese: "アンインストールしてゴミ箱へ", .korean: "제거 및 휴지통으로 이동", .chinese: "卸载并移至废纸篓", .french: "Désinstaller et mettre à la corbeille", .german: "Deinstallieren & in Papierkorb", .spanish: "Desinstalar y mover a Papelera"],
        "reset.confirm.title": [.english: "Confirm Reset", .vietnamese: "Xác nhận đặt lại", .japanese: "リセットの確認", .korean: "재설정 확인", .chinese: "确认重置", .french: "Confirmer la réinitialisation", .german: "Zurücksetzen bestätigen", .spanish: "Confirmar restablecimiento"],
        "reset.confirm.button": [.english: "Reset & Move Data to Trash", .vietnamese: "Đặt lại & chuyển dữ liệu vào Thùng rác", .japanese: "リセットしてゴミ箱へ", .korean: "재설정 및 휴지통으로 이동", .chinese: "重置并移至废纸篓", .french: "Réinitialiser et mettre à la corbeille", .german: "Zurücksetzen & in Papierkorb", .spanish: "Restablecer y mover a Papelera"],
        "uninstall.cancel": [.english: "Cancel", .vietnamese: "Hủy", .japanese: "キャンセル", .korean: "취소", .chinese: "取消", .french: "Annuler", .german: "Abbrechen", .spanish: "Cancelar"],
        "uninstall.success": [.english: "Uninstall successful!", .vietnamese: "Gỡ cài đặt thành công!", .japanese: "アンインストール成功！", .korean: "제거 성공!", .chinese: "卸载成功！", .french: "Désinstallation réussie !", .german: "Deinstallation erfolgreich!", .spanish: "¡Desinstalación exitosa!"],
        "uninstall.partial": [.english: "Completed with errors", .vietnamese: "Hoàn tất với lỗi", .japanese: "エラーありで完了", .korean: "오류와 함께 완료", .chinese: "完成但有错误", .french: "Terminé avec des erreurs", .german: "Mit Fehlern abgeschlossen", .spanish: "Completado con errores"],
        "uninstall.trashInfo": [.english: "Files moved to Trash. Restore via Trash > Put Back.", .vietnamese: "Đã di chuyển vào Thùng rác. Khôi phục: Thùng rác > Đặt lại.", .japanese: "ゴミ箱に移動しました。復元：ゴミ箱 > 戻す。", .korean: "휴지통으로 이동했습니다. 복원: 휴지통 > 되돌리기.", .chinese: "已移至废纸篓。恢复：废纸篓 > 放回原处。", .french: "Fichiers déplacés dans la corbeille. Restaurer via Corbeille > Remettre.", .german: "Dateien in Papierkorb verschoben. Wiederherstellen via Papierkorb > Zurücklegen.", .spanish: "Archivos movidos a Papelera. Restaurar: Papelera > Reponer."],
        "uninstall.close": [.english: "Close", .vietnamese: "Đóng", .japanese: "閉じる", .korean: "닫기", .chinese: "关闭", .french: "Fermer", .german: "Schließen", .spanish: "Cerrar"],

        // Empty state
        "empty.selectApp": [.english: "Select an application", .vietnamese: "Chọn ứng dụng", .japanese: "アプリを選択", .korean: "앱 선택", .chinese: "选择应用", .french: "Sélectionnez une app", .german: "App auswählen", .spanish: "Seleccione una app"],
        "empty.selectAppDesc": [.english: "Select an app from sidebar to view details.", .vietnamese: "Chọn một ứng dụng từ sidebar để xem chi tiết.", .japanese: "サイドバーからアプリを選択して詳細を表示。", .korean: "사이드바에서 앱을 선택하여 세부정보를 봅니다.", .chinese: "从侧边栏选择应用查看详情。", .french: "Sélectionnez une app dans la barre latérale.", .german: "Wählen Sie eine App aus der Seitenleiste.", .spanish: "Seleccione una app de la barra lateral."],
        "empty.welcomeDesc": [.english: "App uninstaller for macOS.\nPress scan to get started.", .vietnamese: "Trình gỡ ứng dụng cho macOS.\nNhấn quét để bắt đầu.", .japanese: "macOS用アンインストーラー。\nスキャンを押して開始。", .korean: "macOS용 언인스톨러.\n스캔을 눌러 시작하세요.", .chinese: "macOS卸载工具。\n按扫描开始。", .french: "Désinstalleur pour macOS.\nAppuyez pour analyser.", .german: "Deinstallationsprogramm für macOS.\nZum Starten scannen.", .spanish: "Desinstalador para macOS.\nPulse escanear para comenzar."],
        "empty.feature.scan": [.english: "Smart Scan", .vietnamese: "Quét thông minh", .japanese: "スマートスキャン", .korean: "스마트 스캔", .chinese: "智能扫描", .french: "Analyse intelligente", .german: "Smart-Scan", .spanish: "Escaneo inteligente"],
        "empty.feature.scanDesc": [.english: "Find apps and leftovers automatically", .vietnamese: "Tìm ứng dụng và tệp rác tự động", .japanese: "アプリと残留ファイルを自動検出", .korean: "앱과 잔여 파일 자동 검색", .chinese: "自动查找应用和残留文件", .french: "Trouver les apps et résidus automatiquement", .german: "Apps und Reste automatisch finden", .spanish: "Encuentra apps y residuos automáticamente"],
        "empty.feature.safe": [.english: "Recoverable Removal", .vietnamese: "Có thể khôi phục", .japanese: "復元可能な削除", .korean: "복구 가능한 제거", .chinese: "可恢复移除", .french: "Suppression récupérable", .german: "Wiederherstellbar entfernen", .spanish: "Eliminación recuperable"],
        "empty.feature.safeDesc": [.english: "Moves selected items to Trash", .vietnamese: "Di chuyển mục đã chọn vào Thùng rác", .japanese: "選択項目をゴミ箱に移動", .korean: "선택한 항목을 휴지통으로 이동", .chinese: "将所选项目移至废纸篓", .french: "Déplace les éléments sélectionnés dans la corbeille", .german: "Verschiebt ausgewählte Objekte in den Papierkorb", .spanish: "Mueve elementos seleccionados a Papelera"],
        "empty.feature.fast": [.english: "Apple Silicon Optimized", .vietnamese: "Tối ưu Apple Silicon", .japanese: "Apple Silicon最適化", .korean: "Apple Silicon 최적화", .chinese: "Apple Silicon优化", .french: "Optimisé Apple Silicon", .german: "Apple Silicon optimiert", .spanish: "Optimizado para Apple Silicon"],
        "empty.feature.fastDesc": [.english: "Ultra lightweight, optimized for M-Series", .vietnamese: "Cực nhẹ, tối ưu cho chip M-Series", .japanese: "超軽量、M-Seriesに最適化", .korean: "초경량, M-Series 최적화", .chinese: "超轻量，M系列芯片优化", .french: "Ultra léger, optimisé pour M-Series", .german: "Ultraleicht, für M-Series optimiert", .spanish: "Ultra ligero, optimizado para M-Series"],

        // Access / Onboarding
        "access.limited": [.english: "Limited scan - grant Library access for full results", .vietnamese: "Quét hạn chế - cấp quyền Library để quét đầy đủ", .japanese: "限定スキャン - 完全な結果のためLibraryアクセスを許可", .korean: "제한된 스캔 - 전체 결과를 위해 Library 접근 권한 부여", .chinese: "有限扫描 - 授予Library访问权限以获取完整结果", .french: "Analyse limitée - accordez l'accès Library", .german: "Eingeschränkter Scan - Library-Zugriff gewähren", .spanish: "Escaneo limitado - otorgue acceso a Library"],
        "access.grant": [.english: "Grant Access", .vietnamese: "Cấp quyền", .japanese: "アクセスを許可", .korean: "접근 권한 부여", .chinese: "授予访问权限", .french: "Accorder l'accès", .german: "Zugriff gewähren", .spanish: "Otorgar acceso"],
        "onboarding.title": [.english: "Setup Access", .vietnamese: "Thiết lập quyền truy cập", .japanese: "アクセス設定", .korean: "접근 권한 설정", .chinese: "设置访问权限", .french: "Configuration d'accès", .german: "Zugriff einrichten", .spanish: "Configurar acceso"],
        "onboarding.subtitle": [.english: "One-time setup, takes 10 seconds", .vietnamese: "Chỉ cần làm 1 lần, mất 10 giây", .japanese: "1回限りの設定、10秒で完了", .korean: "일회성 설정, 10초 소요", .chinese: "一次性设置，仅需10秒", .french: "Configuration unique, 10 secondes", .german: "Einmalig, dauert 10 Sekunden", .spanish: "Configuración única, toma 10 segundos"],
        "onboarding.step1.title": [.english: "Access Required", .vietnamese: "Cần quyền truy cập", .japanese: "アクセスが必要", .korean: "접근 권한 필요", .chinese: "需要访问权限", .french: "Accès requis", .german: "Zugriff erforderlich", .spanish: "Acceso requerido"],
        "onboarding.step1.desc": [.english: "ApexUninstaller needs access to your Library folder to find leftover files from uninstalled apps.", .vietnamese: "ApexUninstaller cần truy cập thư mục Library để tìm tệp rác.", .japanese: "残留ファイルを検出するためにLibraryフォルダへのアクセスが必要です。", .korean: "잔여 파일을 찾기 위해 Library 폴더에 접근해야 합니다.", .chinese: "需要访问Library文件夹以查找残留文件。", .french: "Accès au dossier Library nécessaire pour trouver les résidus.", .german: "Zugriff auf den Library-Ordner erforderlich.", .spanish: "Se necesita acceso a la carpeta Library."],
        "onboarding.step2.title": [.english: "Select Library Folder", .vietnamese: "Chọn thư mục Library", .japanese: "Libraryフォルダを選択", .korean: "Library 폴더 선택", .chinese: "选择Library文件夹", .french: "Sélectionner le dossier Library", .german: "Library-Ordner auswählen", .spanish: "Seleccionar carpeta Library"],
        "onboarding.step2.desc": [.english: "Click 'Grant Access' below. In the dialog, select your ~/Library folder and click Open.", .vietnamese: "Nhấn 'Cấp quyền'. Trong hộp thoại, chọn ~/Library và nhấn Open.", .japanese: "「アクセスを許可」をクリック。ダイアログで~/Libraryを選択しOpenをクリック。", .korean: "'접근 권한 부여'를 클릭하세요. 대화상자에서 ~/Library를 선택하고 열기를 클릭하세요.", .chinese: "点击'授予访问权限'。在对话框中选择~/Library文件夹并点击打开。", .french: "Cliquez 'Accorder l'accès'. Sélectionnez ~/Library et cliquez Ouvrir.", .german: "Klicken Sie 'Zugriff gewähren'. Wählen Sie ~/Library und klicken Sie Öffnen.", .spanish: "Haga clic en 'Otorgar acceso'. Seleccione ~/Library y haga clic en Abrir."],
        "onboarding.step3.title": [.english: "Done!", .vietnamese: "Hoàn tất!", .japanese: "完了！", .korean: "완료!", .chinese: "完成！", .french: "Terminé !", .german: "Fertig!", .spanish: "¡Listo!"],
        "onboarding.step3.desc": [.english: "Access saved permanently. You won't need to do this again.", .vietnamese: "Quyền truy cập đã lưu vĩnh viễn. Không cần làm lại.", .japanese: "アクセス権限は永続的に保存されます。再度行う必要はありません。", .korean: "접근 권한이 영구적으로 저장됩니다. 다시 할 필요 없습니다.", .chinese: "访问权限已永久保存。无需再次操作。", .french: "Accès sauvegardé définitivement.", .german: "Zugriff dauerhaft gespeichert.", .spanish: "Acceso guardado permanentemente."],
        "onboarding.skip": [.english: "Skip", .vietnamese: "Bỏ qua", .japanese: "スキップ", .korean: "건너뛰기", .chinese: "跳过", .french: "Passer", .german: "Überspringen", .spanish: "Omitir"],
        "onboarding.continue": [.english: "Continue", .vietnamese: "Tiếp tục", .japanese: "続ける", .korean: "계속", .chinese: "继续", .french: "Continuer", .german: "Weiter", .spanish: "Continuar"],

        // Status
        "fda.granted": [.english: "Library", .vietnamese: "Library", .japanese: "Library", .korean: "Library", .chinese: "Library", .french: "Library", .german: "Library", .spanish: "Library"],
        "fda.limited": [.english: "Limited", .vietnamese: "Hạn chế", .japanese: "制限あり", .korean: "제한됨", .chinese: "受限", .french: "Limité", .german: "Eingeschränkt", .spanish: "Limitado"],
        "fda.status.granted": [.english: "Access Granted", .vietnamese: "Đã cấp quyền", .japanese: "アクセス許可済み", .korean: "접근 허가됨", .chinese: "已授权", .french: "Accès accordé", .german: "Zugriff gewährt", .spanish: "Acceso otorgado"],
        "fda.status.denied": [.english: "Not Granted", .vietnamese: "Chưa cấp quyền", .japanese: "未許可", .korean: "미허가", .chinese: "未授权", .french: "Non accordé", .german: "Nicht gewährt", .spanish: "No otorgado"],

        // Categories
        "category.appSupport": [.english: "Application Data", .vietnamese: "Dữ liệu ứng dụng", .japanese: "アプリデータ", .korean: "앱 데이터", .chinese: "应用数据", .french: "Données d'app", .german: "App-Daten", .spanish: "Datos de app"],
        "category.caches": [.english: "Caches", .vietnamese: "Bộ nhớ đệm", .japanese: "キャッシュ", .korean: "캐시", .chinese: "缓存", .french: "Caches", .german: "Caches", .spanish: "Cachés"],
        "category.preferences": [.english: "Preferences", .vietnamese: "Cấu hình", .japanese: "環境設定", .korean: "환경설정", .chinese: "偏好设置", .french: "Préférences", .german: "Einstellungen", .spanish: "Preferencias"],
        "category.containers": [.english: "Containers", .vietnamese: "Container (Sandbox)", .japanese: "コンテナ", .korean: "컨테이너", .chinese: "容器", .french: "Conteneurs", .german: "Container", .spanish: "Contenedores"],
        "category.launchAgents": [.english: "Launch Agents", .vietnamese: "Tác vụ khởi chạy", .japanese: "起動エージェント", .korean: "실행 에이전트", .chinese: "启动代理", .french: "Agents de lancement", .german: "Start-Agenten", .spanish: "Agentes de inicio"],
        "category.logs": [.english: "Logs", .vietnamese: "Nhật ký", .japanese: "ログ", .korean: "로그", .chinese: "日志", .french: "Journaux", .german: "Protokolle", .spanish: "Registros"],
        "category.savedState": [.english: "Saved State", .vietnamese: "Trạng thái đã lưu", .japanese: "保存済み状態", .korean: "저장된 상태", .chinese: "已保存状态", .french: "État sauvegardé", .german: "Gespeicherter Zustand", .spanish: "Estado guardado"],

        // Match confidence
        "confidence.high": [.english: "Safe", .vietnamese: "An toàn", .japanese: "安全", .korean: "안전", .chinese: "安全", .french: "Sûr", .german: "Sicher", .spanish: "Seguro"],
        "confidence.medium": [.english: "Likely", .vietnamese: "Có khả năng", .japanese: "可能性高", .korean: "가능성 높음", .chinese: "可能", .french: "Probable", .german: "Wahrscheinlich", .spanish: "Probable"],
        "confidence.review": [.english: "Review", .vietnamese: "Xem kỹ", .japanese: "確認", .korean: "검토", .chinese: "检查", .french: "Vérifier", .german: "Prüfen", .spanish: "Revisar"],

        // Toolbar / paid-value tools
        "toolbar.orphans": [.english: "Orphans", .vietnamese: "Rác cũ", .japanese: "孤立ファイル", .korean: "고아 파일", .chinese: "孤立文件", .french: "Orphelins", .german: "Verwaist", .spanish: "Huérfanos"],
        "toolbar.orphans.help": [.english: "Find leftovers from apps already removed", .vietnamese: "Tìm file rác của app đã xoá trước đó", .japanese: "削除済みアプリの残留ファイルを検索", .korean: "이미 삭제된 앱의 잔여 파일 찾기", .chinese: "查找已删除应用的残留文件", .french: "Trouver les résidus d'apps déjà supprimées", .german: "Reste bereits entfernter Apps finden", .spanish: "Buscar residuos de apps ya eliminadas"],
        "toolbar.history": [.english: "History", .vietnamese: "Lịch sử", .japanese: "履歴", .korean: "기록", .chinese: "历史", .french: "Historique", .german: "Verlauf", .spanish: "Historial"],
        "toolbar.history.help": [.english: "View cleanup history", .vietnamese: "Xem lịch sử dọn dẹp", .japanese: "クリーンアップ履歴を表示", .korean: "정리 기록 보기", .chinese: "查看清理历史", .french: "Voir l'historique", .german: "Bereinigungsverlauf anzeigen", .spanish: "Ver historial"],
        "toolbar.ignored": [.english: "Ignored", .vietnamese: "Đã bỏ qua", .japanese: "無視リスト", .korean: "무시됨", .chinese: "已忽略", .french: "Ignorées", .german: "Ignoriert", .spanish: "Ignoradas"],
        "toolbar.ignored.help": [.english: "Manage ignored apps", .vietnamese: "Quản lý app đã bỏ qua", .japanese: "無視したアプリを管理", .korean: "무시한 앱 관리", .chinese: "管理已忽略应用", .french: "Gérer les apps ignorées", .german: "Ignorierte Apps verwalten", .spanish: "Gestionar apps ignoradas"],
        "toolbar.dashboard": [.english: "Dashboard", .vietnamese: "Tổng quan", .japanese: "ダッシュボード", .korean: "대시보드", .chinese: "仪表板", .french: "Tableau de bord", .german: "Dashboard", .spanish: "Panel"],
        "toolbar.dashboard.help": [.english: "View disk space overview", .vietnamese: "Xem tổng quan dung lượng", .japanese: "ディスク容量の概要を表示", .korean: "디스크 공간 개요 보기", .chinese: "查看磁盘空间概览", .french: "Voir l'aperçu de l'espace disque", .german: "Festplattenübersicht anzeigen", .spanish: "Ver resumen de espacio"],
        "toolbar.usage": [.english: "Usage", .vietnamese: "Sử dụng", .japanese: "使用状況", .korean: "사용량", .chinese: "使用情况", .french: "Utilisation", .german: "Nutzung", .spanish: "Uso"],
        "toolbar.usage.help": [.english: "Analyze app usage age", .vietnamese: "Phân tích thời gian sử dụng app", .japanese: "アプリ使用状況を分析", .korean: "앱 사용 기간 분석", .chinese: "分析应用使用情况", .french: "Analyser l'utilisation des apps", .german: "App-Nutzung analysieren", .spanish: "Analizar uso de apps"],
        "toolbar.settings": [.english: "Settings", .vietnamese: "Cài đặt", .japanese: "設定", .korean: "설정", .chinese: "设置", .french: "Paramètres", .german: "Einstellungen", .spanish: "Configuración"],
        "toolbar.settings.help": [.english: "Open app settings", .vietnamese: "Mở cài đặt ứng dụng", .japanese: "アプリ設定を開く", .korean: "앱 설정 열기", .chinese: "打开应用设置", .french: "Ouvrir les réglages", .german: "App-Einstellungen öffnen", .spanish: "Abrir ajustes"],

        // Orphaned leftovers
        "orphans.title": [.english: "Orphaned Leftovers", .vietnamese: "File rác cũ", .japanese: "孤立した残留ファイル", .korean: "고아 잔여 파일", .chinese: "孤立残留文件", .french: "Résidus orphelins", .german: "Verwaiste Reste", .spanish: "Residuos huérfanos"],
        "orphans.scanning": [.english: "Scanning orphaned leftovers...", .vietnamese: "Đang quét file rác cũ...", .japanese: "孤立ファイルをスキャン中...", .korean: "고아 잔여 파일 검색 중...", .chinese: "正在扫描孤立残留文件...", .french: "Recherche des résidus orphelins...", .german: "Suche nach verwaisten Resten...", .spanish: "Buscando residuos huérfanos..."],
        "orphans.empty": [.english: "No orphaned leftovers found", .vietnamese: "Không tìm thấy file rác cũ", .japanese: "孤立ファイルは見つかりません", .korean: "고아 잔여 파일 없음", .chinese: "未找到孤立残留文件", .french: "Aucun résidu orphelin", .german: "Keine verwaisten Reste gefunden", .spanish: "No se encontraron residuos huérfanos"],
        "orphans.empty.desc": [.english: "Your Library does not show leftovers from removed apps.", .vietnamese: "Library chưa có dấu hiệu file rác từ app đã xoá.", .japanese: "削除済みアプリの残留ファイルは見つかりません。", .korean: "삭제된 앱의 잔여 파일이 보이지 않습니다.", .chinese: "Library 中未发现已删除应用的残留文件。", .french: "Aucun résidu d'app supprimée détecté.", .german: "Keine Reste entfernter Apps erkannt.", .spanish: "No se detectaron residuos de apps eliminadas."],
        "orphans.cleanSelected": [.english: "Clean Selected", .vietnamese: "Dọn mục đã chọn", .japanese: "選択項目を削除", .korean: "선택 항목 정리", .chinese: "清理所选项目", .french: "Nettoyer la sélection", .german: "Auswahl bereinigen", .spanish: "Limpiar selección"],

        // Cleanup history
        "history.title": [.english: "Cleanup History", .vietnamese: "Lịch sử dọn dẹp", .japanese: "クリーンアップ履歴", .korean: "정리 기록", .chinese: "清理历史", .french: "Historique de nettoyage", .german: "Bereinigungsverlauf", .spanish: "Historial de limpieza"],
        "history.clear": [.english: "Clear", .vietnamese: "Xóa lịch sử", .japanese: "消去", .korean: "지우기", .chinese: "清除", .french: "Effacer", .german: "Leeren", .spanish: "Borrar"],
        "history.empty": [.english: "No cleanup history yet.", .vietnamese: "Chưa có lịch sử dọn dẹp.", .japanese: "履歴はまだありません。", .korean: "아직 정리 기록이 없습니다.", .chinese: "暂无清理历史。", .french: "Aucun historique pour le moment.", .german: "Noch kein Verlauf.", .spanish: "Aún no hay historial."],
        "history.operation.uninstall": [.english: "Uninstall", .vietnamese: "Gỡ cài đặt", .japanese: "アンインストール", .korean: "제거", .chinese: "卸载", .french: "Désinstallation", .german: "Deinstallation", .spanish: "Desinstalación"],
        "history.operation.reset": [.english: "Reset", .vietnamese: "Đặt lại", .japanese: "リセット", .korean: "재설정", .chinese: "重置", .french: "Réinitialisation", .german: "Zurücksetzen", .spanish: "Restablecimiento"],
        "history.operation.orphaned": [.english: "Orphan Cleanup", .vietnamese: "Dọn rác cũ", .japanese: "孤立ファイル削除", .korean: "고아 파일 정리", .chinese: "孤立文件清理", .french: "Nettoyage orphelin", .german: "Verwaiste Reste", .spanish: "Limpieza huérfana"],

        // Ignored apps
        "ignored.title": [.english: "Ignored Apps", .vietnamese: "App đã bỏ qua", .japanese: "無視したアプリ", .korean: "무시한 앱", .chinese: "已忽略应用", .french: "Apps ignorées", .german: "Ignorierte Apps", .spanish: "Apps ignoradas"],
        "ignored.empty": [.english: "No ignored apps.", .vietnamese: "Chưa có app bị bỏ qua.", .japanese: "無視したアプリはありません。", .korean: "무시한 앱이 없습니다.", .chinese: "没有已忽略的应用。", .french: "Aucune app ignorée.", .german: "Keine ignorierten Apps.", .spanish: "No hay apps ignoradas."],
        "ignored.restore": [.english: "Restore", .vietnamese: "Khôi phục", .japanese: "復元", .korean: "복원", .chinese: "恢复", .french: "Restaurer", .german: "Wiederherstellen", .spanish: "Restaurar"],
        "ignored.restoreAll": [.english: "Restore All", .vietnamese: "Khôi phục tất cả", .japanese: "すべて復元", .korean: "모두 복원", .chinese: "全部恢复", .french: "Tout restaurer", .german: "Alle wiederherstellen", .spanish: "Restaurar todo"],

        // App insights
        "insights.version": [.english: "Version", .vietnamese: "Phiên bản", .japanese: "バージョン", .korean: "버전", .chinese: "版本", .french: "Version", .german: "Version", .spanish: "Versión"],
        "insights.source": [.english: "Source", .vietnamese: "Nguồn", .japanese: "入手元", .korean: "출처", .chinese: "来源", .french: "Source", .german: "Quelle", .spanish: "Origen"],
        "insights.source.appStore": [.english: "App Store", .vietnamese: "App Store", .japanese: "App Store", .korean: "App Store", .chinese: "App Store", .french: "App Store", .german: "App Store", .spanish: "App Store"],
        "insights.source.external": [.english: "External", .vietnamese: "Bên ngoài", .japanese: "外部", .korean: "외부", .chinese: "外部", .french: "Externe", .german: "Extern", .spanish: "Externa"],
        "insights.minOS": [.english: "Min macOS", .vietnamese: "macOS tối thiểu", .japanese: "最小macOS", .korean: "최소 macOS", .chinese: "最低 macOS", .french: "macOS min.", .german: "Min. macOS", .spanish: "macOS mín."],
        "insights.modified": [.english: "Modified", .vietnamese: "Sửa đổi", .japanese: "変更日", .korean: "수정일", .chinese: "修改时间", .french: "Modifiée", .german: "Geändert", .spanish: "Modificada"],

        // Settings & General
        "settings.language": [.english: "Language", .vietnamese: "Ngôn ngữ", .japanese: "言語", .korean: "언어", .chinese: "语言", .french: "Langue", .german: "Sprache", .spanish: "Idioma"],
        "error.title": [.english: "Error", .vietnamese: "Lỗi", .japanese: "エラー", .korean: "오류", .chinese: "错误", .french: "Erreur", .german: "Fehler", .spanish: "Error"],
        "error.ok": [.english: "OK", .vietnamese: "OK", .japanese: "OK", .korean: "확인", .chinese: "好", .french: "OK", .german: "OK", .spanish: "OK"],
        "error.dropNotApp": [.english: "Please drop a .app bundle.", .vietnamese: "Vui lòng kéo thả file .app.", .japanese: ".appバンドルをドロップしてください。", .korean: ".app 번들을 드롭하세요.", .chinese: "请拖放.app文件。", .french: "Déposez un bundle .app.", .german: "Bitte eine .app-Datei ablegen.", .spanish: "Suelte un bundle .app."],
        "error.readBundleFailed": [.english: "Could not read this application bundle.", .vietnamese: "Không thể đọc bundle ứng dụng này.", .japanese: "このアプリバンドルを読み取れません。", .korean: "이 앱 번들을 읽을 수 없습니다.", .chinese: "无法读取此应用包。", .french: "Impossible de lire ce bundle.", .german: "App-Bundle konnte nicht gelesen werden.", .spanish: "No se pudo leer este bundle."],
        "error.libraryRequired": [.english: "Grant Library access before scanning orphaned leftovers.", .vietnamese: "Cấp quyền Library trước khi quét file rác cũ.", .japanese: "孤立ファイルをスキャンする前にLibraryアクセスを許可してください。", .korean: "고아 파일을 검색하기 전에 Library 접근 권한을 부여하세요.", .chinese: "扫描孤立文件前请授予Library访问权限。", .french: "Accordez l'accès Library avant de scanner les orphelins.", .german: "Library-Zugriff vor dem Scan gewähren.", .spanish: "Otorgue acceso a Library antes de escanear huérfanos."],
        "error.noOrphansSelected": [.english: "No orphaned leftovers selected.", .vietnamese: "Chưa chọn file rác cũ nào.", .japanese: "孤立ファイルが選択されていません。", .korean: "선택된 고아 잔여 파일이 없습니다.", .chinese: "未选择孤立残留文件。", .french: "Aucun résidu orphelin sélectionné.", .german: "Keine verwaisten Reste ausgewählt.", .spanish: "No hay residuos huérfanos seleccionados."],
        "error.noResetSelected": [.english: "No leftovers selected to reset.", .vietnamese: "Chưa chọn file rác để đặt lại.", .japanese: "リセットする残留ファイルが選択されていません。", .korean: "재설정할 잔여 파일이 선택되지 않았습니다.", .chinese: "未选择要重置的残留文件。", .french: "Aucun résidu sélectionné pour réinitialiser.", .german: "Keine Restdateien zum Zurücksetzen ausgewählt.", .spanish: "No hay residuos seleccionados para restablecer."],
        "error.appDidNotQuit": [.english: "%@ did not quit. Please quit it manually before uninstalling.", .vietnamese: "%@ chưa thoát. Vui lòng thoát thủ công trước khi gỡ.", .japanese: "%@が終了しませんでした。手動で終了してからアンインストールしてください。", .korean: "%@이(가) 종료되지 않았습니다. 수동으로 종료한 후 제거하세요.", .chinese: "%@未退出。请先手动退出再卸载。", .french: "%@ ne s'est pas fermée. Quittez-la manuellement.", .german: "%@ wurde nicht beendet. Bitte manuell beenden.", .spanish: "%@ no se cerró. Ciérrela manualmente antes de desinstalar."],
        "error.noItemsSelected": [.english: "No items selected.", .vietnamese: "Chưa chọn mục nào.", .japanese: "項目が選択されていません。", .korean: "선택된 항목이 없습니다.", .chinese: "未选择任何项目。", .french: "Aucun élément sélectionné.", .german: "Keine Elemente ausgewählt.", .spanish: "No hay elementos seleccionados."],
        "error.appStillRunning": [.english: "%@ is still running. Please quit it first.", .vietnamese: "%@ vẫn đang chạy. Vui lòng thoát trước.", .japanese: "%@はまだ実行中です。先に終了してください。", .korean: "%@이(가) 아직 실행 중입니다. 먼저 종료하세요.", .chinese: "%@仍在运行。请先退出。", .french: "%@ est toujours en cours. Quittez-la d'abord.", .german: "%@ läuft noch. Bitte zuerst beenden.", .spanish: "%@ sigue en ejecución. Ciérrela primero."],
        "error.batch.noneSelected": [.english: "No applications selected.", .vietnamese: "Chưa chọn ứng dụng nào.", .japanese: "アプリが選択されていません。", .korean: "선택된 앱이 없습니다.", .chinese: "未选择应用。", .french: "Aucune application sélectionnée.", .german: "Keine Apps ausgewählt.", .spanish: "No hay aplicaciones seleccionadas."],
        "error.batch.notScanned": [.english: "Wait for leftover scan to finish before batch uninstall.", .vietnamese: "Đợi quét file rác xong trước khi gỡ hàng loạt.", .japanese: "一括アンインストール前に残留ファイルのスキャン完了を待ってください。", .korean: "일괄 제거 전에 잔여 파일 스캔이 끝날 때까지 기다리세요.", .chinese: "批量卸载前请等待残留文件扫描完成。", .french: "Attendez la fin du scan avant la désinstallation groupée.", .german: "Warten Sie auf den Scan vor der Stapel-Deinstallation.", .spanish: "Espere a que termine el escaneo antes de desinstalar en lote."],

        // Running app warning
        "running.title": [.english: "%@ is Running", .vietnamese: "%@ đang chạy", .japanese: "%@が実行中", .korean: "%@ 실행 중", .chinese: "%@正在运行", .french: "%@ est en cours", .german: "%@ läuft", .spanish: "%@ en ejecución"],
        "running.message": [.english: "%@ is currently running. For best results, quit the app before uninstalling.\n\nQuit it now?", .vietnamese: "%@ đang chạy. Nên thoát app trước khi gỡ.\n\nThoát ngay?", .japanese: "%@は実行中です。アンインストール前に終了することをお勧めします。\n\n今終了しますか？", .korean: "%@이(가) 실행 중입니다. 제거 전에 종료하는 것이 좋습니다.\n\n지금 종료할까요?", .chinese: "%@正在运行。卸载前建议先退出。\n\n现在退出？", .french: "%@ est en cours. Quittez-la avant de désinstaller.\n\nQuitter maintenant ?", .german: "%@ läuft. Beenden Sie die App vor der Deinstallation.\n\nJetzt beenden?", .spanish: "%@ está en ejecución. Ciérrela antes de desinstalar.\n\n¿Cerrar ahora?"],
        "running.quitContinue": [.english: "Quit & Continue", .vietnamese: "Thoát & Tiếp tục", .japanese: "終了して続行", .korean: "종료 후 계속", .chinese: "退出并继续", .french: "Quitter et continuer", .german: "Beenden & Fortfahren", .spanish: "Cerrar y continuar"],
        "running.uninstallAnyway": [.english: "Uninstall Anyway", .vietnamese: "Vẫn gỡ", .japanese: "そのままアンインストール", .korean: "그래도 제거", .chinese: "仍然卸载", .french: "Désinstaller quand même", .german: "Trotzdem deinstallieren", .spanish: "Desinstalar de todos modos"],

        // Uninstall results
        "results.succeeded": [.english: "%d succeeded", .vietnamese: "%d thành công", .japanese: "%d 件成功", .korean: "%d 성공", .chinese: "%d 成功", .french: "%d réussi(s)", .german: "%d erfolgreich", .spanish: "%d exitoso(s)"],
        "results.failed": [.english: "%d failed", .vietnamese: "%d thất bại", .japanese: "%d 件失敗", .korean: "%d 실패", .chinese: "%d 失败", .french: "%d échoué(s)", .german: "%d fehlgeschlagen", .spanish: "%d fallido(s)"],
        "results.failedItems": [.english: "Failed Items", .vietnamese: "Mục thất bại", .japanese: "失敗した項目", .korean: "실패한 항목", .chinese: "失败项目", .french: "Éléments échoués", .german: "Fehlgeschlagene Elemente", .spanish: "Elementos fallidos"],
        "results.manualTip": [.english: "Tip: Open in Finder and press ⌘⌫ to manually move to Trash", .vietnamese: "Mẹo: Mở trong Finder và nhấn ⌘⌫ để chuyển vào Thùng rác", .japanese: "ヒント: Finderで開き ⌘⌫ でゴミ箱に移動", .korean: "팁: Finder에서 ⌘⌫을 눌러 휴지통으로 이동", .chinese: "提示：在Finder中按⌘⌫移至废纸篓", .french: "Astuce : ouvrez dans le Finder et appuyez sur ⌘⌫", .german: "Tipp: In Finder öffnen und ⌘⌫ drücken", .spanish: "Consejo: abra en Finder y pulse ⌘⌫"],
        "results.retry": [.english: "Retry deletion", .vietnamese: "Thử xóa lại", .japanese: "削除を再試行", .korean: "삭제 재시도", .chinese: "重试删除", .french: "Réessayer la suppression", .german: "Löschen wiederholen", .spanish: "Reintentar eliminación"],
        "results.reveal": [.english: "Reveal in Finder", .vietnamese: "Hiện trong Finder", .japanese: "Finderで表示", .korean: "Finder에서 보기", .chinese: "在Finder中显示", .french: "Afficher dans le Finder", .german: "Im Finder anzeigen", .spanish: "Mostrar en Finder"],
        "results.unknownError": [.english: "Unknown error", .vietnamese: "Lỗi không xác định", .japanese: "不明なエラー", .korean: "알 수 없는 오류", .chinese: "未知错误", .french: "Erreur inconnue", .german: "Unbekannter Fehler", .spanish: "Error desconocido"],

        // Failure reasons
        "failure.appRunning": [.english: "%@ is still running. Quit the app and try again.", .vietnamese: "%@ vẫn đang chạy. Thoát app và thử lại.", .japanese: "%@はまだ実行中です。終了して再試行してください。", .korean: "%@이(가) 아직 실행 중입니다. 종료 후 다시 시도하세요.", .chinese: "%@仍在运行。请退出后重试。", .french: "%@ est toujours en cours. Quittez-la et réessayez.", .german: "%@ läuft noch. Beenden und erneut versuchen.", .spanish: "%@ sigue en ejecución. Ciérrela e intente de nuevo."],
        "failure.permissionDenied": [.english: "Permission denied. Open in Finder and press ⌘⌫ to move to Trash.", .vietnamese: "Không đủ quyền. Mở Finder và nhấn ⌘⌫ để chuyển vào Thùng rác.", .japanese: "権限がありません。Finderで ⌘⌫ を押してゴミ箱へ移動してください。", .korean: "권한이 없습니다. Finder에서 ⌘⌫을 눌러 휴지통으로 이동하세요.", .chinese: "权限不足。在Finder中按⌘⌫移至废纸篓。", .french: "Permission refusée. Ouvrez dans le Finder et appuyez sur ⌘⌫.", .german: "Keine Berechtigung. Im Finder öffnen und ⌘⌫ drücken.", .spanish: "Permiso denegado. Abra en Finder y pulse ⌘⌫."],
        "failure.unsafePath": [.english: "This location is protected by ApexUninstaller's safety policy.", .vietnamese: "Vị trí này được chính sách an toàn của ApexUninstaller bảo vệ.", .japanese: "この場所はApexUninstallerの安全ポリシーで保護されています。", .korean: "이 위치는 ApexUninstaller 안전 정책으로 보호됩니다.", .chinese: "此位置受 ApexUninstaller 安全策略保护。", .french: "Cet emplacement est protégé par la politique de sécurité d’ApexUninstaller.", .german: "Dieser Ort ist durch die Sicherheitsrichtlinie von ApexUninstaller geschützt.", .spanish: "Esta ubicación está protegida por la política de seguridad de ApexUninstaller."],
        "failure.fileInUse": [.english: "File is in use by another process. Close it and try again.", .vietnamese: "File đang được dùng bởi tiến trình khác. Đóng và thử lại.", .japanese: "別のプロセスが使用中です。閉じて再試行してください。", .korean: "다른 프로세스가 사용 중입니다. 닫고 다시 시도하세요.", .chinese: "文件正被其他进程使用。请关闭后重试。", .french: "Fichier utilisé par un autre processus. Fermez-le et réessayez.", .german: "Datei wird verwendet. Schließen und erneut versuchen.", .spanish: "Archivo en uso. Ciérrelo e intente de nuevo."],
        "failure.fileNotFound": [.english: "File no longer exists.", .vietnamese: "File không còn tồn tại.", .japanese: "ファイルは存在しません。", .korean: "파일이 더 이상 존재하지 않습니다.", .chinese: "文件已不存在。", .french: "Le fichier n'existe plus.", .german: "Datei existiert nicht mehr.", .spanish: "El archivo ya no existe."],
        "failure.unknown": [.english: "Open in Finder and press ⌘⌫ to move to Trash.", .vietnamese: "Mở Finder và nhấn ⌘⌫ để chuyển vào Thùng rác.", .japanese: "Finderで ⌘⌫ を押してゴミ箱へ移動してください。", .korean: "Finder에서 ⌘⌫을 눌러 휴지통으로 이동하세요.", .chinese: "在Finder中按⌘⌫移至废纸篓。", .french: "Ouvrez dans le Finder et appuyez sur ⌘⌫.", .german: "Im Finder öffnen und ⌘⌫ drücken.", .spanish: "Abra en Finder y pulse ⌘⌫."],

        // History detail
        "history.itemsOk": [.english: "%d ok", .vietnamese: "%d ok", .japanese: "%d 件成功", .korean: "%d 성공", .chinese: "%d 成功", .french: "%d ok", .german: "%d ok", .spanish: "%d ok"],
        "history.itemsFailed": [.english: "%d failed", .vietnamese: "%d lỗi", .japanese: "%d 件失敗", .korean: "%d 실패", .chinese: "%d 失败", .french: "%d échoué(s)", .german: "%d fehlgeschlagen", .spanish: "%d fallido(s)"],

        // Status bar
        "status.libraryGranted": [.english: "Library ✓", .vietnamese: "Library ✓", .japanese: "Library ✓", .korean: "Library ✓", .chinese: "Library ✓", .french: "Library ✓", .german: "Library ✓", .spanish: "Library ✓"],

        // Export
        "export.panelTitle": [.english: "Export Cleanup Report", .vietnamese: "Xuất báo cáo dọn dẹp", .japanese: "クリーンアップレポートを書き出す", .korean: "정리 보고서 내보내기", .chinese: "导出清理报告", .french: "Exporter le rapport", .german: "Bereinigungsbericht exportieren", .spanish: "Exportar informe"],

        // Sidebar reclaimable & batch
        "sidebar.reclaimable": [.english: "~%@ reclaimable", .vietnamese: "~%@ có thể giải phóng", .japanese: "~%@ 回収可能", .korean: "~%@ 회수 가능", .chinese: "~%@ 可释放", .french: "~%@ récupérables", .german: "~%@ freigebbar", .spanish: "~%@ recuperables"],
        "batch.selectMode": [.english: "Select", .vietnamese: "Chọn", .japanese: "選択", .korean: "선택", .chinese: "选择", .french: "Sélectionner", .german: "Auswählen", .spanish: "Seleccionar"],
        "batch.selectMode.help": [.english: "Select multiple apps to uninstall", .vietnamese: "Chọn nhiều app để gỡ hàng loạt", .japanese: "複数アプリを選択して一括アンインストール", .korean: "여러 앱을 선택하여 일괄 제거", .chinese: "选择多个应用批量卸载", .french: "Sélectionner plusieurs apps à désinstaller", .german: "Mehrere Apps zum Deinstallieren auswählen", .spanish: "Seleccionar varias apps para desinstalar"],
        "batch.selectAll": [.english: "Select All", .vietnamese: "Chọn tất cả", .japanese: "すべて選択", .korean: "모두 선택", .chinese: "全选", .french: "Tout sélectionner", .german: "Alle auswählen", .spanish: "Seleccionar todo"],
        "batch.deselectAll": [.english: "Deselect All", .vietnamese: "Bỏ chọn tất cả", .japanese: "すべて解除", .korean: "모두 해제", .chinese: "取消全选", .french: "Tout désélectionner", .german: "Alle abwählen", .spanish: "Deseleccionar todo"],
        "batch.uninstall": [.english: "Uninstall Selected", .vietnamese: "Gỡ đã chọn", .japanese: "選択項目をアンインストール", .korean: "선택 항목 제거", .chinese: "卸载所选", .french: "Désinstaller la sélection", .german: "Auswahl deinstallieren", .spanish: "Desinstalar selección"],
        "batch.confirm.title": [.english: "Batch Uninstall", .vietnamese: "Gỡ hàng loạt", .japanese: "一括アンインストール", .korean: "일괄 제거", .chinese: "批量卸载", .french: "Désinstallation groupée", .german: "Stapel-Deinstallation", .spanish: "Desinstalación en lote"],
        "batch.confirm.message": [.english: "Uninstall %d apps with recommended leftovers?\nTotal: %@", .vietnamese: "Gỡ %d app kèm file rác đề xuất?\nTổng: %@", .japanese: "推奨残留ファイル付きで %d 件のアプリをアンインストールしますか？\n合計: %@", .korean: "권장 잔여 파일과 함께 %d개 앱을 제거할까요?\n합계: %@", .chinese: "卸载 %d 个应用及推荐残留文件？\n总计：%@", .french: "Désinstaller %d apps avec résidus recommandés ?\nTotal : %@", .german: "%d Apps mit empfohlenen Resten deinstallieren?\nGesamt: %@", .spanish: "¿Desinstalar %d apps con residuos recomendados?\nTotal: %@"],
        "batch.confirm.button": [.english: "Uninstall All", .vietnamese: "Gỡ tất cả", .japanese: "すべてアンインストール", .korean: "모두 제거", .chinese: "全部卸载", .french: "Tout désinstaller", .german: "Alle deinstallieren", .spanish: "Desinstalar todo"],
        "batch.progress": [.english: "Uninstalling %@...", .vietnamese: "Đang gỡ %@...", .japanese: "%@ をアンインストール中...", .korean: "%@ 제거 중...", .chinese: "正在卸载 %@...", .french: "Désinstallation de %@...", .german: "Deinstalliere %@...", .spanish: "Desinstalando %@..."],

        // Dashboard
        "dashboard.title": [.english: "Disk Space Overview", .vietnamese: "Tổng quan dung lượng", .japanese: "ディスク容量概要", .korean: "디스크 공간 개요", .chinese: "磁盘空间概览", .french: "Aperçu de l'espace disque", .german: "Festplattenübersicht", .spanish: "Resumen de espacio en disco"],
        "dashboard.totalApps": [.english: "Total Apps", .vietnamese: "Tổng ứng dụng", .japanese: "アプリ総数", .korean: "총 앱", .chinese: "应用总数", .french: "Total apps", .german: "Gesamt-Apps", .spanish: "Total de apps"],
        "dashboard.totalJunk": [.english: "Total Junk", .vietnamese: "Tổng rác", .japanese: "残留ファイル合計", .korean: "총 고아 파일", .chinese: "残留文件总计", .french: "Total déchets", .german: "Gesamte Reste", .spanish: "Total de residuos"],
        "dashboard.orphanJunk": [.english: "Orphan Junk", .vietnamese: "Rác cũ", .japanese: "孤立ファイル", .korean: "고아 파일", .chinese: "孤立文件", .french: "Déchets orphelins", .german: "Verwaiste Reste", .spanish: "Residuos huérfanos"],
        "dashboard.topJunkApps": [.english: "Top Junk Apps", .vietnamese: "App nhiều rác nhất", .japanese: "残留ファイルが多いアプリ", .korean: "잔여 파일이 많은 앱", .chinese: "垃圾最多的应用", .french: "Apps avec le plus de déchets", .german: "Apps mit meisten Resten", .spanish: "Apps con más residuos"],
        "dashboard.categoryBreakdown": [.english: "Category Breakdown", .vietnamese: "Phân tích theo danh mục", .japanese: "カテゴリ別内訳", .korean: "카테고리별 분석", .chinese: "分类明细", .french: "Répartition par catégorie", .german: "Aufschlüsselung nach Kategorie", .spanish: "Desglose por categoría"],
        "dashboard.largeLeftovers": [.english: "Large Leftovers (>%@)", .vietnamese: "File rác lớn (>%@)", .japanese: "大きな残留ファイル (>%@)", .korean: "대형 잔여 파일 (>%@)", .chinese: "大型残留文件 (>%@)", .french: "Gros déchets (>%@)", .german: "Große Reste (>%@)", .spanish: "Residuos grandes (>%@)"],
        "dashboard.noData": [.english: "Scan apps to see statistics", .vietnamese: "Quét ứng dụng để xem thống kê", .japanese: "統計を表示するにはアプリをスキャン", .korean: "통계를 보려면 앱을 스캔하세요", .chinese: "扫描应用以查看统计", .french: "Scannez les apps pour voir les stats", .german: "Apps scannen für Statistiken", .spanish: "Escanee apps para ver estadísticas"],
        "dashboard.lastScan": [.english: "Last scan", .vietnamese: "Lần quét cuối", .japanese: "最終スキャン", .korean: "마지막 스캔", .chinese: "上次扫描", .french: "Dernier scan", .german: "Letzter Scan", .spanish: "Último escaneo"],
        "dashboard.items": [.english: "items", .vietnamese: "mục", .japanese: "件", .korean: "개", .chinese: "项", .french: "éléments", .german: "Einträge", .spanish: "elementos"],

        // App Usage Analysis
        "usage.title": [.english: "App Usage Analysis", .vietnamese: "Phân tích sử dụng app", .japanese: "アプリ使用分析", .korean: "앱 사용 분석", .chinese: "应用使用分析", .french: "Analyse d'utilisation des apps", .german: "App-Nutzungsanalyse", .spanish: "Análisis de uso de apps"],
        "usage.refresh": [.english: "Refresh", .vietnamese: "Làm mới", .japanese: "更新", .korean: "새로 고침", .chinese: "刷新", .french: "Actualiser", .german: "Aktualisieren", .spanish: "Actualizar"],
        "usage.recentlyUsed": [.english: "Recently Used", .vietnamese: "Mới dùng gần đây", .japanese: "最近使用", .korean: "최근 사용", .chinese: "最近使用", .french: "Récemment utilisées", .german: "Kürzlich verwendet", .spanish: "Usadas recientemente"],
        "usage.usedWithinMonth": [.english: "Used Within 30 Days", .vietnamese: "Đã dùng trong 30 ngày", .japanese: "30日以内に使用", .korean: "30일 이내 사용", .chinese: "30天内使用", .french: "Utilisées dans les 30 jours", .german: "In den letzten 30 Tagen verwendet", .spanish: "Usadas en 30 días"],
        "usage.unused1to3Months": [.english: "Unused 1-3 Months", .vietnamese: "Không dùng 1-3 tháng", .japanese: "1〜3ヶ月未使用", .korean: "1-3개월 미사용", .chinese: "1-3个月未使用", .french: "Non utilisées 1-3 mois", .german: "1-3 Monate ungenutzt", .spanish: "Sin usar 1-3 meses"],
        "usage.unusedOver3Months": [.english: "Unused Over 3 Months", .vietnamese: "Không dùng trên 3 tháng", .japanese: "3ヶ月以上未使用", .korean: "3개월 이상 미사용", .chinese: "超过3个月未使用", .french: "Non utilisées depuis plus de 3 mois", .german: "Über 3 Monate ungenutzt", .spanish: "Sin usar más de 3 meses"],
        "usage.unknown": [.english: "Unknown", .vietnamese: "Không xác định", .japanese: "不明", .korean: "알 수 없음", .chinese: "未知", .french: "Inconnu", .german: "Unbekannt", .spanish: "Desconocido"],
        "usage.daysUnused": [.english: "%d days unused", .vietnamese: "%d ngày không dùng", .japanese: "%d日未使用", .korean: "%d일 미사용", .chinese: "%d天未使用", .french: "%d jours non utilisées", .german: "%d Tage ungenutzt", .spanish: "%d días sin usar"],
        "usage.potentialSavings": [.english: "Potential Savings", .vietnamese: "Tiết kiệm tiềm năng", .japanese: "節約可能", .korean: "절감 가능", .chinese: "可节省空间", .french: "Économies potentielles", .german: "Mögliche Einsparungen", .spanish: "Ahorro potencial"],
        "usage.noUnusedApps": [.english: "No unused apps found", .vietnamese: "Không tìm thấy app không dùng", .japanese: "未使用のアプリはありません", .korean: "미사용 앱 없음", .chinese: "未找到未使用的应用", .french: "Aucune app non utilisée", .german: "Keine ungenutzten Apps", .spanish: "No hay apps sin usar"],
        "usage.suggestUninstall": [.english: "Consider uninstalling", .vietnamese: "Cân nhắc gỡ bỏ", .japanese: "アンインストールを検討", .korean: "제거 고려", .chinese: "建议卸载", .french: "Envisager de désinstaller", .german: "Deinstallation in Betracht ziehen", .spanish: "Considerar desinstalar"],

        // Scheduled Scan
        "schedule.title": [.english: "Scheduled Scan", .vietnamese: "Quét định kỳ", .japanese: "定期スキャン", .korean: "정기 스캔", .chinese: "定时扫描", .french: "Scan planifié", .german: "Geplante Überprüfung", .spanish: "Escaneo programado"],
        "schedule.enable": [.english: "Enable Scan Reminders", .vietnamese: "Bật nhắc quét", .japanese: "スキャン通知を有効化", .korean: "스캔 알림 활성화", .chinese: "启用扫描提醒", .french: "Activer les rappels de scan", .german: "Scan-Erinnerungen aktivieren", .spanish: "Activar recordatorios"],
        "schedule.interval": [.english: "Scan Interval", .vietnamese: "Khoảng cách quét", .japanese: "スキャン間隔", .korean: "스캔 간격", .chinese: "扫描间隔", .french: "Intervalle de scan", .german: "Scannintervall", .spanish: "Intervalo de escaneo"],
        "schedule.daily": [.english: "Daily", .vietnamese: "Hàng ngày", .japanese: "毎日", .korean: "매일", .chinese: "每天", .french: "Quotidien", .german: "Täglich", .spanish: "Diario"],
        "schedule.weekly": [.english: "Weekly", .vietnamese: "Hàng tuần", .japanese: "毎週", .korean: "매주", .chinese: "每周", .french: "Hebdomadaire", .german: "Wöchentlich", .spanish: "Semanal"],
        "schedule.monthly": [.english: "Monthly", .vietnamese: "Hàng tháng", .japanese: "毎月", .korean: "매월", .chinese: "每月", .french: "Mensuel", .german: "Monatlich", .spanish: "Mensual"],
        "schedule.lastScan": [.english: "Last completed scan", .vietnamese: "Lần quét hoàn tất gần nhất", .japanese: "最後に完了したスキャン", .korean: "마지막 완료된 스캔", .chinese: "上次完成的扫描", .french: "Dernier scan terminé", .german: "Letzter abgeschlossener Scan", .spanish: "Último escaneo completado"],
        "schedule.nextScan": [.english: "Next scheduled scan", .vietnamese: "Lần quét kế tiếp", .japanese: "次のスケジュールスキャン", .korean: "다음 예약 스캔", .chinese: "下次计划扫描", .french: "Prochain scan programmé", .german: "Nächster geplanter Scan", .spanish: "Próximo escaneo programado"],
        "schedule.never": [.english: "Never", .vietnamese: "Chưa bao giờ", .japanese: "未実行", .korean: "없음", .chinese: "从未", .french: "Jamais", .german: "Nie", .spanish: "Nunca"],

        // Notifications
        "notification.title": [.english: "Time to Clean Up", .vietnamese: "Đã đến lúc dọn dẹp", .japanese: "お掃除の時間です", .korean: "정리할 시간입니다", .chinese: "该清理了", .french: "Il est temps de nettoyer", .german: "Zeit zum Aufräumen", .spanish: "Hora de limpiar"],
        "notification.body": [.english: "Open ApexUninstaller to scan for junk files", .vietnamese: "Mở ApexUninstaller để quét file rác", .japanese: "ApexUninstallerを開いて残留ファイルをスキャン", .korean: "ApexUninstaller를 열어 잔여 파일을 스캔하세요", .chinese: "打开ApexUninstaller扫描残留文件", .french: "Ouvrez ApexUninstaller pour analyser les fichiers", .german: "Öffnen Sie ApexUninstaller zum Scannen", .spanish: "Abra ApexUninstaller para escanear archivos"],

        // Settings
        "settings.title": [.english: "Settings", .vietnamese: "Cài đặt", .japanese: "設定", .korean: "설정", .chinese: "设置", .french: "Paramètres", .german: "Einstellungen", .spanish: "Configuración"],
        "settings.general": [.english: "General", .vietnamese: "Chung", .japanese: "一般", .korean: "일반", .chinese: "通用", .french: "Général", .german: "Allgemein", .spanish: "General"],
        "settings.advanced": [.english: "Advanced", .vietnamese: "Nâng cao", .japanese: "詳細", .korean: "고급", .chinese: "高级", .french: "Avancé", .german: "Erweitert", .spanish: "Avanzado"],
        "settings.largeLeftoverThreshold": [.english: "Large leftover threshold", .vietnamese: "Ngưỡng file rác lớn", .japanese: "大きな残留ファイルのしきい値", .korean: "대형 잔여 파일 기준", .chinese: "大型残留文件阈值", .french: "Seuil de gros déchets", .german: "Schwellwert für große Reste", .spanish: "Umbral de residuos grandes"],
        "settings.mb": [.english: "MB", .vietnamese: "MB", .japanese: "MB", .korean: "MB", .chinese: "MB", .french: "Mo", .german: "MB", .spanish: "MB"],

        // Menu Bar
        "menuBar.title": [.english: "Menu Bar", .vietnamese: "Thanh menu", .japanese: "メニュースペース", .korean: "메뉴 바", .chinese: "菜单栏", .french: "Barre de menu", .german: "Menüleiste", .spanish: "Barra de menú"],
        "menuBar.enable": [.english: "Show in Menu Bar", .vietnamese: "Hiện trong Thanh menu", .japanese: "メニュースペースに表示", .korean: "메뉴 바에 표시", .chinese: "显示在菜单栏", .french: "Afficher dans la barre de menu", .german: "In der Menüleiste anzeigen", .spanish: "Mostrar en barra de menú"],
        "menuBar.reclaimable": [.english: "Reclaimable", .vietnamese: "Có thể giải phóng", .japanese: "回收可能", .korean: "회수 가능", .chinese: "可释放", .french: "Récupérables", .german: "Freigebbar", .spanish: "Recuperables"],
        "menuBar.orphans": [.english: "Orphans", .vietnamese: "Rác cũ", .japanese: "孤立ファイル", .korean: "고아 파일", .chinese: "孤立文件", .french: "Orphelins", .german: "Verwaist", .spanish: "Huérfanos"],
        "menuBar.recent": [.english: "Recent", .vietnamese: "Gần đây", .japanese: "最近", .korean: "최근", .chinese: "最近", .french: "Récent", .german: "Kürzlich", .spanish: "Reciente"],
        "menuBar.openApp": [.english: "Open ApexUninstaller", .vietnamese: "Mở ApexUninstaller", .japanese: "ApexUninstallerを開く", .korean: "ApexUninstaller 열기", .chinese: "打开 ApexUninstaller", .french: "Ouvrir ApexUninstaller", .german: "ApexUninstaller öffnen", .spanish: "Abrir ApexUninstaller"],
        "menuBar.quit": [.english: "Quit", .vietnamese: "Thoát", .japanese: "終了", .korean: "종료", .chinese: "退出", .french: "Quitter", .german: "Beenden", .spanish: "Salir"],

        // Smart Notifications
        "notification.smartEnable": [.english: "Smart Notifications", .vietnamese: "Thông báo thông minh", .japanese: "スマート通知", .korean: "스마트 알림", .chinese: "智能通知", .french: "Notifications intelligentes", .german: "Intelligente Benachrichtigungen", .spanish: "Notificaciones inteligentes"],
        "notification.smartEnable.help": [.english: "Get notified when it's time to clean up", .vietnamese: "Nhận thông báo khi đến lúc dọn dẹp", .japanese: "お掃除のタイミング的通知を受け取る", .korean: "정리할 시간에 알림 받기", .chinese: "在需要清理时收到通知", .french: "Être notifié quand il est temps de nettoyer", .german: "Benachrichtigt werden, wenn es Zeit zum Aufräumen ist", .spanish: "Recibir notificaciones cuando sea hora de limpiar"],
        "notification.junkReminder.title": [.english: "Time to Clean Up", .vietnamese: "Đã đến lúc dọn dẹp", .japanese: "お掃除の時間です", .korean: "정리할 시간입니다", .chinese: "该清理了", .french: "Il est temps de nettoyer", .german: "Zeit zum Aufräumen", .spanish: "Hora de limpiar"],
        "notification.junkReminder.body": [.english: "You have %@ of junk across %d apps. Time to reclaim some space!", .vietnamese: "Bạn có %@ rác từ %d app. Đã đến lúc giải phóng dung lượng!", .japanese: "%@のジャンクが%dアプリにあります。容量を解放しましょう！", .korean: "%@의 정크가 %d개 앱에 있습니다. 용량을 확보할 시간!", .chinese: "您在%d个应用中有%@的垃圾。是时候释放一些空间了！", .french: "Vous avez %@ de déchets dans %d apps. Il est temps de récupérer de l'espace !", .german: "Sie haben %@ an Müll in %d Apps. Zeit, Speicherplatz freizugeben!", .spanish: "Tienes %@ de basura en %d apps. ¡Es hora de reclamar espacio!"],
        "notification.largeLeftover.title": [.english: "Large Leftovers Found", .vietnamese: "Tìm thấy file rác lớn", .japanese: "大きな残留ファイルが見つかりました", .korean: "대형 잔여 파일 발견", .chinese: "发现大型残留文件", .french: "Gros déchets trouvés", .german: "Große Reste gefunden", .spanish: "Residuos grandes encontrados"],
        "notification.largeLeftover.body": [.english: "%@ has %@ of leftovers. Consider cleaning it up!", .vietnamese: "%@ có %@ file rác. Cân nhắc dọn dẹp!", .japanese: "%@には%@の残留ファイルがあります。クリーンアップを検討！", .korean: "%@에 %@의 잔여 파일이 있습니다. 정리를 고려하세요!", .chinese: "%@有%@残留文件。考虑清理！", .french: "%@ a %@ de résidus. Envisagez de nettoyer !", .german: "%@ hat %@ an Resten. Erwägen Sie, es zu bereinigen!", .spanish: "%@ tiene %@ de residuos. ¡Considera limpiarlo!"],
        "notification.cleanupComplete.title": [.english: "Cleanup Complete", .vietnamese: "Dọn dẹp hoàn tất", .japanese: "クリーンアップ完了", .korean: "정리 완료", .chinese: "清理完成", .french: "Nettoyage terminé", .german: "Bereinigung abgeschlossen", .spanish: "Limpieza completada"],
        "notification.cleanupComplete.body": [.english: "%@ cleaned. Reclaimed %@ of disk space!", .vietnamese: "Đã dọn %@. Giải phóng được %@!", .japanese: "%@をクリーン。%@のディスク容量を解放！", .korean: "%@ 정리 완료. %@의 디스크 공간을 확보!", .chinese: "%@已清理。已回收%@磁盘空间！", .french: "%@ nettoyé. %@ d'espace disque récupéré !", .german: "%@ bereinigt. %@ Speicherplatz freigegeben!", .spanish: "%@ limpiado. ¡Se recuperaron %@ de espacio en disco!"],
        "notification.action.clean": [.english: "Clean", .vietnamese: "Dọn", .japanese: "クリーン", .korean: "정리", .chinese: "清理", .french: "Nettoyer", .german: "Bereinigen", .spanish: "Limpiar"],
        "notification.action.dismiss": [.english: "Dismiss", .vietnamese: "Bỏ qua", .japanese: "スキップ", .korean: "건너뛰기", .chinese: "忽略", .french: "Ignorer", .german: "Überspringen", .spanish: "Descartar"],

        // System Junk
        "systemJunk.title": [.english: "System Junk", .vietnamese: "Rác hệ thống", .japanese: "システムジャンク", .korean: "시스템 정크", .chinese: "系统垃圾", .french: "Déchets système", .german: "Systemmüll", .spanish: "Basura del sistema"],
        "systemJunk.browserCache": [.english: "Browser Cache", .vietnamese: "Cache trình duyệt", .japanese: "ブラウザキャッシュ", .korean: "브라우저 캐시", .chinese: "浏览器缓存", .french: "Cache navigateur", .german: "Browser-Cache", .spanish: "Caché del navegador"],
        "systemJunk.systemCache": [.english: "System Cache", .vietnamese: "Cache hệ thống", .japanese: "システムキャッシュ", .korean: "시스템 캐시", .chinese: "系统缓存", .french: "Cache système", .german: "System-Cache", .spanish: "Caché del sistema"],
        "systemJunk.appCaches": [.english: "App Caches", .vietnamese: "Cache ứng dụng", .japanese: "アプリキャッシュ", .korean: "앱 캐시", .chinese: "应用缓存", .french: "Cache apps", .german: "App-Cache", .spanish: "Caché de apps"],
        "systemJunk.logs": [.english: "User Logs", .vietnamese: "Nhật ký người dùng", .japanese: "ユーザーログ", .korean: "사용자 로그", .chinese: "用户日志", .french: "Journaux utilisateur", .german: "Benutzerprotokolle", .spanish: "Registros de usuario"],
        "systemJunk.tempFiles": [.english: "Temporary Files", .vietnamese: "File tạm", .japanese: "一時ファイル", .korean: "임시 파일", .chinese: "临时文件", .french: "Fichiers temporaires", .german: "Temporäre Dateien", .spanish: "Archivos temporales"],
        "systemJunk.xcodeData": [.english: "Xcode Build Data", .vietnamese: "Dữ liệu build Xcode", .japanese: "Xcodeビルドデータ", .korean: "Xcode 빌드 데이터", .chinese: "Xcode构建数据", .french: "Données build Xcode", .german: "Xcode-Build-Daten", .spanish: "Datos de compilación Xcode"],
        "systemJunk.fontCaches": [.english: "Font Caches", .vietnamese: "Cache font", .japanese: "フォントキャッシュ", .korean: "폰트 캐시", .chinese: "字体缓存", .french: "Cache polices", .german: "Schriftarten-Cache", .spanish: "Caché de fuentes"],
        "systemJunk.thumbnails": [.english: "Thumbnail Cache", .vietnamese: "Cache thumbnail", .japanese: "サムネイルキャッシュ", .korean: "썸네일 캐시", .chinese: "缩略图缓存", .french: "Cache miniatures", .german: "Vorschau-Cache", .spanish: "Caché de miniaturas"],
        "systemJunk.totalJunk": [.english: "Total Junk", .vietnamese: "Tổng rác", .japanese: "合計ジャンク", .korean: "총 정크", .chinese: "总垃圾", .french: "Total déchets", .german: "Gesamtmüll", .spanish: "Total basura"],
        "systemJunk.safeToDelete": [.english: "Safe to Delete", .vietnamese: "An toàn để xóa", .japanese: "削除安全", .korean: "삭제 안전", .chinese: "可安全删除", .french: "Supprimable en sécurité", .german: "Sicher zu löschen", .spanish: "Seguro para eliminar"],
        "systemJunk.selectAllSafe": [.english: "Select Safe", .vietnamese: "Chọn an toàn", .japanese: "安全項目を選択", .korean: "안전 항목 선택", .chinese: "选择安全项", .french: "Sélection sûre", .german: "Sichere wählen", .spanish: "Seguro"],
        "systemJunk.cleanComplete": [.english: "Cleanup Complete", .vietnamese: "Dọn dẹp hoàn tất", .japanese: "クリーンアップ完了", .korean: "정리 완료", .chinese: "清理完成", .french: "Nettoyage terminé", .german: "Bereinigung abgeschlossen", .spanish: "Limpieza completada"],
        "systemJunk.freedSpace": [.english: "Moved %@ to Trash. Empty Trash later to reclaim disk space.", .vietnamese: "Đã chuyển %@ vào Thùng rác. Dọn Thùng rác sau để giải phóng dung lượng.", .japanese: "%@をゴミ箱へ移動しました。容量を解放するには後でゴミ箱を空にしてください。", .korean: "%@을(를) 휴지통으로 이동했습니다. 공간 확보를 위해 나중에 휴지통을 비우세요.", .chinese: "已将%@移到废纸篓。稍后清空废纸篓以释放空间。", .french: "%@ déplacé vers la Corbeille. Videz-la ensuite pour récupérer l'espace.", .german: "%@ in den Papierkorb verschoben. Leeren Sie ihn später, um Speicher freizugeben.", .spanish: "%@ movido a la Papelera. Vacíela después para recuperar espacio."],
        "systemJunk.cleanButton": [.english: "Move to Trash", .vietnamese: "Chuyển vào Thùng rác", .japanese: "ゴミ箱へ移動", .korean: "휴지통으로 이동", .chinese: "移到废纸篓", .french: "Mettre à la corbeille", .german: "In Papierkorb", .spanish: "Mover a Papelera"],
        "systemJunk.scanButton": [.english: "Scan Junk", .vietnamese: "Quét rác", .japanese: "ジャンクをスキャン", .korean: "정크 스캔", .chinese: "扫描垃圾", .french: "Analyser", .german: "Scannen", .spanish: "Escanear"],
        "systemJunk.viewDetails": [.english: "Show detailed paths", .vietnamese: "Xem danh sách chi tiết", .japanese: "詳細パスを表示", .korean: "상세 경로 보기", .chinese: "显示详细路径", .french: "Afficher les chemins détaillés", .german: "Detaillierte Pfade anzeigen", .spanish: "Mostrar rutas detalladas"],
        "systemJunk.category.browserCache": [.english: "Browser Cache", .vietnamese: "Bộ nhớ đệm trình duyệt", .japanese: "ブラウザキャッシュ", .korean: "브라우저 캐시", .chinese: "浏览器缓存", .french: "Cache des navigateurs", .german: "Browser-Cache", .spanish: "Caché del navegador"],
        "systemJunk.category.browserCache.description": [.english: "Safari, Chrome, Edge, Brave, Arc and Firefox caches", .vietnamese: "Bộ nhớ đệm Safari, Chrome, Edge, Brave, Arc và Firefox", .japanese: "Safari、Chrome、Edge、Brave、Arc、Firefox のキャッシュ", .korean: "Safari, Chrome, Edge, Brave, Arc 및 Firefox 캐시", .chinese: "Safari、Chrome、Edge、Brave、Arc 和 Firefox 缓存", .french: "Caches de Safari, Chrome, Edge, Brave, Arc et Firefox", .german: "Caches von Safari, Chrome, Edge, Brave, Arc und Firefox", .spanish: "Cachés de Safari, Chrome, Edge, Brave, Arc y Firefox"],
        "systemJunk.category.systemCache": [.english: "System Cache", .vietnamese: "Bộ nhớ đệm hệ thống", .japanese: "システムキャッシュ", .korean: "시스템 캐시", .chinese: "系统缓存", .french: "Cache système", .german: "System-Cache", .spanish: "Caché del sistema"],
        "systemJunk.category.systemCache.description": [.english: "User Library application caches", .vietnamese: "Bộ nhớ đệm ứng dụng trong Thư viện người dùng", .japanese: "ユーザライブラリ内のアプリキャッシュ", .korean: "사용자 라이브러리의 앱 캐시", .chinese: "用户资源库中的应用缓存", .french: "Caches d’applications de la bibliothèque utilisateur", .german: "App-Caches in der Benutzerbibliothek", .spanish: "Cachés de apps en la biblioteca del usuario"],
        "systemJunk.category.applicationCache": [.english: "App Caches", .vietnamese: "Bộ nhớ đệm ứng dụng", .japanese: "アプリキャッシュ", .korean: "앱 캐시", .chinese: "应用缓存", .french: "Caches des apps", .german: "App-Caches", .spanish: "Cachés de apps"],
        "systemJunk.category.applicationCache.description": [.english: "Sandboxed application caches", .vietnamese: "Bộ nhớ đệm của ứng dụng sandbox", .japanese: "サンドボックス化されたアプリのキャッシュ", .korean: "샌드박스 앱 캐시", .chinese: "沙盒应用缓存", .french: "Caches des applications en bac à sable", .german: "Caches von Apps in der Sandbox", .spanish: "Cachés de aplicaciones en sandbox"],
        "systemJunk.category.logs": [.english: "System Logs", .vietnamese: "Nhật ký hệ thống", .japanese: "システムログ", .korean: "시스템 로그", .chinese: "系统日志", .french: "Journaux système", .german: "Systemprotokolle", .spanish: "Registros del sistema"],
        "systemJunk.category.logs.description": [.english: "User application logs", .vietnamese: "Nhật ký ứng dụng của người dùng", .japanese: "ユーザアプリのログ", .korean: "사용자 앱 로그", .chinese: "用户应用日志", .french: "Journaux des applications utilisateur", .german: "Protokolle von Benutzer-Apps", .spanish: "Registros de aplicaciones del usuario"],
        "systemJunk.category.tempFiles": [.english: "Temporary Files", .vietnamese: "Tệp tạm thời", .japanese: "一時ファイル", .korean: "임시 파일", .chinese: "临时文件", .french: "Fichiers temporaires", .german: "Temporäre Dateien", .spanish: "Archivos temporales"],
        "systemJunk.category.tempFiles.description": [.english: "Temporary files", .vietnamese: "Các tệp tạm thời của người dùng", .japanese: "ユーザの一時ファイル", .korean: "사용자 임시 파일", .chinese: "用户临时文件", .french: "Fichiers temporaires de l’utilisateur", .german: "Temporäre Benutzerdateien", .spanish: "Archivos temporales del usuario"],
        "systemJunk.category.xcodeDerivedData": [.english: "Xcode Build Data", .vietnamese: "Dữ liệu build Xcode", .japanese: "Xcode ビルドデータ", .korean: "Xcode 빌드 데이터", .chinese: "Xcode 构建数据", .french: "Données de build Xcode", .german: "Xcode-Build-Daten", .spanish: "Datos de compilación de Xcode"],
        "systemJunk.category.xcodeDerivedData.description": [.english: "Xcode build artifacts", .vietnamese: "Tệp phát sinh từ quá trình build Xcode", .japanese: "Xcode のビルド生成物", .korean: "Xcode 빌드 산출물", .chinese: "Xcode 构建产物", .french: "Artefacts de compilation Xcode", .german: "Xcode-Build-Artefakte", .spanish: "Artefactos de compilación de Xcode"],
        "systemJunk.category.fontCaches": [.english: "Font Caches", .vietnamese: "Bộ nhớ đệm phông chữ", .japanese: "フォントキャッシュ", .korean: "글꼴 캐시", .chinese: "字体缓存", .french: "Caches de polices", .german: "Schrift-Caches", .spanish: "Cachés de fuentes"],
        "systemJunk.category.fontCaches.description": [.english: "Font rendering caches", .vietnamese: "Bộ nhớ đệm hiển thị phông chữ", .japanese: "フォント描画キャッシュ", .korean: "글꼴 렌더링 캐시", .chinese: "字体渲染缓存", .french: "Caches de rendu des polices", .german: "Caches für die Schriftdarstellung", .spanish: "Cachés de renderizado de fuentes"],
        "systemJunk.category.thumbnailCaches": [.english: "Thumbnail Cache", .vietnamese: "Bộ nhớ đệm ảnh thu nhỏ", .japanese: "サムネイルキャッシュ", .korean: "미리보기 캐시", .chinese: "缩略图缓存", .french: "Cache des vignettes", .german: "Vorschaubild-Cache", .spanish: "Caché de miniaturas"],
        "systemJunk.category.thumbnailCaches.description": [.english: "Image and preview thumbnails", .vietnamese: "Ảnh thu nhỏ và bản xem trước", .japanese: "画像とプレビューのサムネイル", .korean: "이미지 및 미리보기 썸네일", .chinese: "图像和预览缩略图", .french: "Vignettes d’images et d’aperçus", .german: "Bild- und Vorschau-Miniaturen", .spanish: "Miniaturas de imágenes y vistas previas"],
        "systemJunk.noDetails": [.english: "No detailed paths found.", .vietnamese: "Không có mục chi tiết.", .japanese: "詳細パスはありません。", .korean: "상세 경로가 없습니다.", .chinese: "未找到详细路径。", .french: "Aucun chemin détaillé trouvé.", .german: "Keine detaillierten Pfade gefunden.", .spanish: "No se encontraron rutas detalladas."],
        "systemJunk.scanSystem": [.english: "System Junk Cleaner", .vietnamese: "Trình dọn rác hệ thống", .japanese: "システムジャンククリーナー", .korean: "시스템 정크 클리너", .chinese: "系统垃圾清理器", .french: "Nettoyeur de déchets système", .german: "Systemmüll-Bereiniger", .spanish: "Limpiador de basura del sistema"],
        "systemJunk.scanDescription": [.english: "Scan user-level caches, logs, temporary data, and Xcode build data that you can review before cleaning.", .vietnamese: "Quét cache, nhật ký người dùng, dữ liệu tạm và dữ liệu build Xcode để bạn xem trước khi dọn.", .japanese: "ユーザー領域のキャッシュ、ログ、一時データ、Xcodeデータを確認してから削除できます。", .korean: "사용자 캐시, 로그, 임시 데이터, Xcode 빌드 데이터를 검토 후 정리합니다.", .chinese: "扫描用户级缓存、日志、临时数据和 Xcode 构建数据，清理前可查看。", .french: "Analyse les caches, journaux utilisateur, données temporaires et données Xcode à vérifier avant nettoyage.", .german: "Scannt Benutzer-Caches, Protokolle, temporäre Daten und Xcode-Daten zur Prüfung vor dem Bereinigen.", .spanish: "Escanea cachés de usuario, registros, temporales y datos Xcode para revisar antes de limpiar."],
        "systemJunk.scanningFiles": [.english: "Scanning cleanup locations...", .vietnamese: "Đang quét vị trí có thể dọn...", .japanese: "クリーンアップ場所をスキャン中...", .korean: "정리 위치 스캔 중...", .chinese: "正在扫描可清理位置...", .french: "Analyse des emplacements à nettoyer...", .german: "Bereinigungsorte werden gescannt...", .spanish: "Escaneando ubicaciones de limpieza..."],
        "systemJunk.scanningNote": [.english: "This may take a moment", .vietnamese: "Có thể mất một lát", .japanese: "しばらくかかる場合があります", .korean: "잠시 걸릴 수 있습니다", .chinese: "可能需要一些时间", .french: "Cela peut prendre un moment", .german: "Dies kann einen Moment dauern", .spanish: "Esto puede tardar un momento"],
        "systemJunk.selectItems": [.english: "Select items to clean", .vietnamese: "Chọn mục để dọn", .japanese: "クリーンする項目を選択", .korean: "정리할 항목 선택", .chinese: "选择要清理的项目", .french: "Sélectionnez les éléments à nettoyer", .german: "Elemente zum Bereinigen auswählen", .spanish: "Seleccione elementos para limpiar"],
        "systemJunk.selectedCount": [.english: "selected", .vietnamese: "đã chọn", .japanese: "選択済み", .korean: "선택됨", .chinese: "已选择", .french: "sélectionné(s)", .german: "ausgewählt", .spanish: "seleccionado(s)"],
        "systemJunk.cleaning": [.english: "Cleaning...", .vietnamese: "Đang dọn...", .japanese: "クリーン中...", .korean: "정리 중...", .chinese: "正在清理...", .french: "Nettoyage...", .german: "Bereinige...", .spanish: "Limpiando..."],
        "systemJunk.confirm.title": [.english: "Move Selected Junk to Trash?", .vietnamese: "Chuyển rác đã chọn vào Thùng rác?", .japanese: "選択したジャンクをゴミ箱へ移動しますか？", .korean: "선택한 정크를 휴지통으로 이동할까요?", .chinese: "将所选垃圾移到废纸篓？", .french: "Mettre les déchets sélectionnés à la corbeille ?", .german: "Ausgewählten Müll in den Papierkorb?", .spanish: "¿Mover basura seleccionada a Papelera?"],
        "systemJunk.confirm.message": [.english: "%d selected items will be moved to Trash.\nTotal: %@", .vietnamese: "%d mục đã chọn sẽ được chuyển vào Thùng rác.\nTổng: %@", .japanese: "%d件の選択項目をゴミ箱へ移動します。\n合計: %@", .korean: "선택한 %d개 항목을 휴지통으로 이동합니다.\n합계: %@", .chinese: "将 %d 个所选项目移到废纸篓。\n总计：%@", .french: "%d éléments sélectionnés seront déplacés vers la Corbeille.\nTotal : %@", .german: "%d ausgewählte Einträge werden in den Papierkorb verschoben.\nGesamt: %@", .spanish: "%d elementos seleccionados se moverán a la Papelera.\nTotal: %@"],
        "systemJunk.confirm.button": [.english: "Move to Trash", .vietnamese: "Chuyển vào Thùng rác", .japanese: "ゴミ箱へ移動", .korean: "휴지통으로 이동", .chinese: "移到废纸篓", .french: "Mettre à la corbeille", .german: "In Papierkorb", .spanish: "Mover a Papelera"],
        "systemJunk.cleanupSuccess": [.english: "Successfully freed %@ of disk space!", .vietnamese: "Đã giải phóng %@ dung lượng đĩa!", .japanese: "%@のディスク容量を解放しました！", .korean: "%@의 디스크 공간을 확보했습니다!", .chinese: "已成功释放%@磁盘空间！", .french: "%@ d'espace disque libéré avec succès !", .german: "%@ Speicherplatz erfolgreich freigegeben!", .spanish: "¡Se liberaron exitosamente %@ de espacio en disco!"],
        "systemJunk.itemCount": [.english: "items", .vietnamese: "mục", .japanese: "件", .korean: "개", .chinese: "项", .french: "éléments", .german: "Einträge", .spanish: "elementos"],
        "systemJunk.deselectAll": [.english: "Deselect All", .vietnamese: "Bỏ chọn tất cả", .japanese: "すべて解除", .korean: "모두 해제", .chinese: "取消全选", .french: "Tout désélectionner", .german: "Alle abwählen", .spanish: "Deseleccionar todo"],
        "systemJunk.done": [.english: "Done", .vietnamese: "Xong", .japanese: "完了", .korean: "완료", .chinese: "完成", .french: "Terminé", .german: "Fertig", .spanish: "Listo"],

        // Settings
        "settings.menuBarAccess": [.english: "Quick access from the menu bar", .vietnamese: "Truy cập nhanh từ thanh menu", .japanese: "メニューバーからクイックアクセス", .korean: "메뉴 바에서 빠른 액세스", .chinese: "从菜单栏快速访问", .french: "Accès rapide depuis la barre de menu", .german: "Schnellzugriff aus der Menüleiste", .spanish: "Acceso rápido desde la barra de menú"],
        "settings.pendingCleanups": [.english: "Pending cleanups", .vietnamese: "Chờ dọn dẹp", .japanese: "保留中のクリーンアップ", .korean: "보류 중인 정리", .chinese: "待清理", .french: "Nettoyages en attente", .german: "Ausstehende Bereinigungen", .spanish: "Limpiezas pendientes"],
        "settings.reminderThreshold": [.english: "Reminder threshold", .vietnamese: "Ngưỡng nhắc nhở", .japanese: "リマインダーしきい値", .korean: "알림 기준", .chinese: "提醒阈值", .french: "Seuil de rappel", .german: "Erinnerungsschwelle", .spanish: "Umbral de recordatorio"],
        "settings.getNotified": [.english: "Get notified when it's time to clean up", .vietnamese: "Nhận thông báo khi đến lúc dọn dẹp", .japanese: "お掃除のタイミング的通知を受け取る", .korean: "정리할 시간에 알림 받기", .chinese: "在需要清理时收到通知", .french: "Être notifié quand il est temps de nettoyer", .german: "Benachrichtigt werden, wenn es Zeit zum Aufräumen ist", .spanish: "Recibir notificaciones cuando sea hora de limpiar"],
        "settings.launchAtLogin": [.english: "Launch at Login", .vietnamese: "Khởi động cùng hệ điều hành", .japanese: "ログイン時に起動", .korean: "로그인 시 실행", .chinese: "登录时启动", .french: "Lancer au démarrage", .german: "Beim Anmelden starten", .spanish: "Iniciar al arrancar"],
        "settings.launchAtLogin.requiresApproval": [.english: "Requires approval in System Settings", .vietnamese: "Cần cấp quyền trong Cài đặt hệ thống", .japanese: "システム設定で承認が必要", .korean: "시스템 설정에서 승인 필요", .chinese: "需要在系统设置中批准", .french: "Nécessite une approbation dans les paramètres", .german: "Erfordert Genehmigung in Systemeinstellungen", .spanish: "Requiere aprobación en Ajustes del sistema"],
        "settings.leftoverThreshold": [.english: "Leftovers larger than this will be highlighted", .vietnamese: "File rác lớn hơn sẽ được đánh dấu", .japanese: "これより大きい残留ファイルはハイライト表示されます", .korean: "이보다 큰 잔여 파일은 강조 표시됩니다", .chinese: "大于此的残留文件将被高亮显示", .french: "Les résidus plus volumineux seront mis en surbrillance", .german: "Reste größer als dieser werden hervorgehoben", .spanish: "Los residuos mayores que esto se resaltarán"],
        "settings.clearAll": [.english: "Clear All", .vietnamese: "Xóa tất cả", .japanese: "すべて消去", .korean: "모두 지우기", .chinese: "清除全部", .french: "Tout effacer", .german: "Alle löschen", .spanish: "Borrar todo"],
        "settings.direct.title": [.english: "Direct Distribution", .vietnamese: "Bản phân phối trực tiếp", .japanese: "直接配布版", .korean: "직접 배포 버전", .chinese: "直接分发版", .french: "Distribution directe", .german: "Direktvertrieb", .spanish: "Distribución directa"],
        "settings.direct.edition": [.english: "ApexUninstaller Direct", .vietnamese: "ApexUninstaller Direct", .japanese: "ApexUninstaller Direct", .korean: "ApexUninstaller Direct", .chinese: "ApexUninstaller Direct", .french: "ApexUninstaller Direct", .german: "ApexUninstaller Direct", .spanish: "ApexUninstaller Direct"],
        "settings.direct.description": [.english: "Not sandboxed. Your Library folder is scanned directly without a folder picker.", .vietnamese: "Không dùng sandbox. Thư mục Library được quét trực tiếp mà không cần chọn lại.", .japanese: "サンドボックスなし。フォルダ選択なしでLibraryを直接スキャンします。", .korean: "샌드박스 없이 폴더 선택 과정 없이 Library를 직접 스캔합니다.", .chinese: "不使用沙盒，无需文件夹选择器即可直接扫描 Library。", .french: "Sans sandbox. Le dossier Library est analysé directement, sans sélecteur.", .german: "Ohne Sandbox. Der Library-Ordner wird ohne Ordnerauswahl direkt gescannt.", .spanish: "Sin sandbox. La carpeta Library se analiza directamente sin selector."],
        "settings.direct.fullDiskHelp": [.english: "Full Disk Access is optional and must be granted by you in System Settings. ApexUninstaller never enables it automatically.", .vietnamese: "Full Disk Access là tùy chọn và phải do bạn cấp trong Cài đặt hệ thống. ApexUninstaller không bao giờ tự bật quyền này.", .japanese: "フルディスクアクセスは任意で、システム設定から手動で許可する必要があります。", .korean: "전체 디스크 접근은 선택 사항이며 시스템 설정에서 직접 허용해야 합니다.", .chinese: "完全磁盘访问权限是可选的，必须由您在系统设置中手动授予。", .french: "L’accès complet au disque est facultatif et doit être accordé dans Réglages Système.", .german: "Festplattenvollzugriff ist optional und muss in den Systemeinstellungen erteilt werden.", .spanish: "El acceso total al disco es opcional y debes concederlo en Ajustes del Sistema."],
        "settings.direct.fullDisk": [.english: "Full Disk Access", .vietnamese: "Full Disk Access", .japanese: "フルディスクアクセス", .korean: "전체 디스크 접근", .chinese: "完全磁盘访问", .french: "Accès complet", .german: "Vollzugriff", .spanish: "Acceso total"],
        "settings.direct.source": [.english: "Source Code", .vietnamese: "Mã nguồn", .japanese: "ソースコード", .korean: "소스 코드", .chinese: "源代码", .french: "Code source", .german: "Quellcode", .spanish: "Código fuente"],
        "settings.direct.sponsor": [.english: "Sponsor", .vietnamese: "Ủng hộ", .japanese: "支援", .korean: "후원", .chinese: "赞助", .french: "Soutenir", .german: "Unterstützen", .spanish: "Apoyar"],

        // Menu Bar
        "menuBar.appName": [.english: "ApexUninstaller", .vietnamese: "ApexUninstaller", .japanese: "ApexUninstaller", .korean: "ApexUninstaller", .chinese: "ApexUninstaller", .french: "ApexUninstaller", .german: "ApexUninstaller", .spanish: "ApexUninstaller"],
        "menuBar.menuBar": [.english: "Menu Bar", .vietnamese: "Thanh menu", .japanese: "メニュースペース", .korean: "메뉴 바", .chinese: "菜单栏", .french: "Barre de menu", .german: "Menüleiste", .spanish: "Barra de menú"],
        "menuBar.reclaimableSpace": [.english: "Reclaimable", .vietnamese: "Có thể giải phóng", .japanese: "回収可能", .korean: "회수 가능", .chinese: "可释放", .french: "Récupérables", .german: "Freigebbar", .spanish: "Recuperables"],
        "menuBar.orphanFiles": [.english: "Orphans", .vietnamese: "Rác cũ", .japanese: "孤立ファイル", .korean: "고아 파일", .chinese: "孤立文件", .french: "Orphelins", .german: "Verwaist", .spanish: "Huérfanos"],
        "menuBar.recentItems": [.english: "Recent", .vietnamese: "Gần đây", .japanese: "最近", .korean: "최근", .chinese: "最近", .french: "Récent", .german: "Kürzlich", .spanish: "Reciente"],

        // Dashboard
        "dashboard.noLargeLeftovers": [.english: "No large leftovers found", .vietnamese: "Không tìm thấy file rác lớn", .japanese: "大きな残留ファイルは見つかりません", .korean: "대형 잔여 파일 없음", .chinese: "未找到大型残留文件", .french: "Aucun gros résidu trouvé", .german: "Keine großen Reste gefunden", .spanish: "No se encontraron residuos grandes"],
        "dashboard.categoryCount": [.english: "%d items", .vietnamese: "%d mục", .japanese: "%d件", .korean: "%d개", .chinese: "%d项", .french: "%d éléments", .german: "%d Einträge", .spanish: "%d elementos"],

        // Usage Analysis
        "usage.analyzing": [.english: "Analyzing app usage...", .vietnamese: "Đang phân tích sử dụng app...", .japanese: "アプリ使用状況を分析中...", .korean: "앱 사용 분석 중...", .chinese: "正在分析应用使用...", .french: "Analyse de l'utilisation des apps...", .german: "Analysiere App-Nutzung...", .spanish: "Analizando uso de apps..."],
        "usage.analyzingApps": [.english: "Analyzing app usage...", .vietnamese: "Đang phân tích sử dụng app...", .japanese: "アプリ使用状況を分析中...", .korean: "앱 사용 분석 중...", .chinese: "正在分析应用使用...", .french: "Analyse de l'utilisation des apps...", .german: "Analysiere App-Nutzung...", .spanish: "Analizando uso de apps..."],
        "usage.appsAnalyzed": [.english: "%d apps analyzed", .vietnamese: "Đã phân tích %d app", .japanese: "%d件のアプリを分析", .korean: "%d개 앱 분석됨", .chinese: "已分析 %d 个应用", .french: "%d apps analysées", .german: "%d Apps analysiert", .spanish: "%d apps analizadas"],
        "usage.scanFirst": [.english: "Scan apps first to analyze usage", .vietnamese: "Quét app trước để phân tích sử dụng", .japanese: "使用状況を分析するには、まずアプリをスキャン", .korean: "사용량을 분석하려면 먼저 앱을 스캔하세요", .chinese: "先扫描应用以分析使用情况", .french: "Scannez d'abord les apps pour analyser l'utilisation", .german: "Scannen Sie zuerst Apps zur Nutzungsanalyse", .spanish: "Escanee primero las apps para analizar el uso"],
        "usage.appCount": [.english: "%d apps", .vietnamese: "%d app", .japanese: "%d件", .korean: "%d개", .chinese: "%d个应用", .french: "%d apps", .german: "%d Apps", .spanish: "%d apps"],
        "usage.moreApps": [.english: "+ %d more", .vietnamese: "+ %d còn lại", .japanese: "+ %d件", .korean: "+ %d개", .chinese: "+ %d 更多", .french: "+ %d de plus", .german: "+ %d weitere", .spanish: "+ %d más"],

        // Scan Progress
        "scan.progress": [.english: "%d%%", .vietnamese: "%d%%", .japanese: "%d%%", .korean: "%d%%", .chinese: "%d%%", .french: "%d%%", .german: "%d%%", .spanish: "%d%%"],

        // Duplicate Finder
        "duplicate.title": [.english: "Duplicates", .vietnamese: "Tệp trùng lặp", .japanese: "重複ファイル", .korean: "중복 파일", .chinese: "重复文件", .french: "Doublons", .german: "Duplikate", .spanish: "Duplicados"],
        "duplicate.findDuplicates": [.english: "Find Duplicate Files", .vietnamese: "Tìm tệp trùng lặp", .japanese: "重複ファイルを検索", .korean: "중복 파일 찾기", .chinese: "查找重复文件", .french: "Trouver les fichiers en double", .german: "Doppelte Dateien finden", .spanish: "Buscar archivos duplicados"],
        "duplicate.howItWorks": [.english: "Scans selected folders to find identical files by comparing file content using SHA256 hash. Keeps one copy and lets you safely remove the rest.", .vietnamese: "Quét thư mục đã chọn để tìm tệp trùng lặp bằng cách so sánh nội dung SHA256. Giữ một bản và xóa các bản còn lại an toàn.", .japanese: "選択したフォルダをスキャンし、SHA256ハッシュでファイル内容を比較して同一ファイルを検索します。1つのコピーを保持し、残りを安全に削除できます。", .korean: "선택한 폴더를 스캔하여 SHA256 해시로 파일 내용을 비교하여 동일한 파일을 찾습니다. 하나의 사본을 유지하고 나머지를 안전하게 제거할 수 있습니다.", .chinese: "扫描所选文件夹，通过 SHA256 哈希比较文件内容来查找相同文件。保留一份副本，安全删除其余副本。", .french: "Analyse les dossiers sélectionnés pour trouver les fichiers identiques en comparant le contenu par hash SHA256. Garde une copie et supprime safely les autres.", .german: "Scannt ausgewählte Ordner nach identischen Dateien per SHA256-Hash-Vergleich. Behaltet eine Kopie und entfernt sicher den Rest.", .spanish: "Escanea carpetas seleccionadas para encontrar archivos idénticos comparando el contenido mediante hash SHA256. Mantiene una copia y elimina safely el resto."],
        "duplicate.startScan": [.english: "Start Scan", .vietnamese: "Bắt đầu quét", .japanese: "スキャン開始", .korean: "스캔 시작", .chinese: "开始扫描", .french: "Démarrer l'analyse", .german: "Scan starten", .spanish: "Iniciar escaneo"],
        "duplicate.changeFolder": [.english: "Change", .vietnamese: "Đổi", .japanese: "変更", .korean: "변경", .chinese: "更改", .french: "Changer", .german: "Ändern", .spanish: "Cambiar"],
        "duplicate.selectFolder": [.english: "Select Folder to Scan", .vietnamese: "Chọn thư mục quét", .japanese: "スキャンするフォルダを選択", .korean: "스캔할 폴더 선택", .chinese: "选择要扫描的文件夹", .french: "Sélectionner le dossier à analyser", .german: "Zu scannenden Ordner auswählen", .spanish: "Seleccionar carpeta a escanear"],
        "duplicate.noDuplicates": [.english: "No Duplicates Found", .vietnamese: "Không tìm thấy tệp trùng", .japanese: "重複ファイルなし", .korean: "중복 파일 없음", .chinese: "未找到重复文件", .french: "Aucun doublon trouvé", .german: "Keine Duplikate gefunden", .spanish: "No se encontraron duplicados"],
        "duplicate.noDuplicatesDesc": [.english: "The scanned folders do not contain duplicate files.", .vietnamese: "Thư mục đã quét không chứa tệp trùng lặp.", .japanese: "スキャンしたフォルダには重複ファイルがありません。", .korean: "스캔한 폴더에 중복 파일이 없습니다.", .chinese: "扫描的文件夹不包含重复文件。", .french: "Les dossiers analysés ne contiennent pas de fichiers en double.", .german: "Die gescannten Ordner enthalten keine doppelten Dateien.", .spanish: "Las carpetas escaneadas no contienen archivos duplicados."],
        "duplicate.groups": [.english: "groups", .vietnamese: "nhóm", .japanese: "グループ", .korean: "그룹", .chinese: "组", .french: "groupes", .german: "Gruppen", .spanish: "grupos"],
        "duplicate.wasted": [.english: "wasted", .vietnamese: "lãng phí", .japanese: "無駄", .korean: "낭비", .chinese: "浪费", .french: "gaspillé", .german: "verschwendet", .spanish: "desperdiciado"],
        "duplicate.filesScanned": [.english: "scanned", .vietnamese: "đã quét", .japanese: "スキャン済み", .korean: "스캔됨", .chinese: "已扫描", .french: "analysés", .german: "gescannt", .spanish: "escaneados"],
        "duplicate.selectAll": [.english: "Select All", .vietnamese: "Chọn tất cả", .japanese: "すべて選択", .korean: "모두 선택", .chinese: "全选", .french: "Tout sélectionner", .german: "Alle auswählen", .spanish: "Seleccionar todo"],
        "duplicate.deselectAll": [.english: "Deselect", .vietnamese: "Bỏ chọn", .japanese: "選択解除", .korean: "선택 해제", .chinese: "取消全选", .french: "Tout désélectionner", .german: "Alle abwählen", .spanish: "Deseleccionar todo"],
        "duplicate.files": [.english: "files", .vietnamese: "tệp", .japanese: "ファイル", .korean: "파일", .chinese: "文件", .french: "fichiers", .german: "Dateien", .spanish: "archivos"],
        "duplicate.selected": [.english: "selected", .vietnamese: "đã chọn", .japanese: "選択済み", .korean: "선택됨", .chinese: "已选择", .french: "sélectionné(s)", .german: "ausgewählt", .spanish: "seleccionado(s)"],
        "duplicate.selectToClean": [.english: "Select duplicate groups to clean up", .vietnamese: "Chọn nhóm trùng lặp để dọn dẹp", .japanese: "クリーンする重複グループを選択", .korean: "정리할 중복 그룹 선택", .chinese: "选择要清理的重复组", .french: "Sélectionnez les groupes de doublons à nettoyer", .german: "Duplikatgruppen zum Bereinigen auswählen", .spanish: "Seleccione grupos duplicados para limpiar"],
        "duplicate.cleanSelected": [.english: "Clean Selected", .vietnamese: "Dọn đã chọn", .japanese: "選択をクリーン", .korean: "선택 항목 정리", .chinese: "清理所选", .french: "Nettoyer la sélection", .german: "Auswahl bereinigen", .spanish: "Limpiar selección"],
        "duplicate.cleanComplete": [.english: "Cleanup Complete", .vietnamese: "Dọn dẹp hoàn tất", .japanese: "クリーンアップ完了", .korean: "정리 완료", .chinese: "清理完成", .french: "Nettoyage terminé", .german: "Bereinigung abgeschlossen", .spanish: "Limpieza completada"],
        "duplicate.freedSpace": [.english: "Freed %@ of disk space!", .vietnamese: "Đã giải phóng %@!", .japanese: "%@のディスク容量を解放！", .korean: "%@의 디스크 공간을 확보!", .chinese: "已释放%@磁盘空间！", .french: "%@ d'espace disque libéré !", .german: "%@ Speicherplatz freigegeben!", .spanish: "¡Se liberaron %@ de espacio en disco!"],
        // Folder Picker
        "folder.home": [.english: "Home", .vietnamese: "Trang chủ", .japanese: "ホーム", .korean: "홈", .chinese: "主目录", .french: "Accueil", .german: "Startseite", .spanish: "Inicio"],
        "folder.documents": [.english: "Documents", .vietnamese: "Tài liệu", .japanese: "書類", .korean: "문서", .chinese: "文档", .french: "Documents", .german: "Dokumente", .spanish: "Documentos"],
        "folder.downloads": [.english: "Downloads", .vietnamese: "Tải về", .japanese: "ダウンロード", .korean: "다운로드", .chinese: "下载", .french: "Téléchargements", .german: "Downloads", .spanish: "Descargas"],
        "folder.pictures": [.english: "Pictures", .vietnamese: "Hình ảnh", .japanese: "ピクチャ", .korean: "사진", .chinese: "图片", .french: "Photos", .german: "Bilder", .spanish: "Imágenes"],
        "folder.desktop": [.english: "Desktop", .vietnamese: "Màn hình", .japanese: "デスクトップ", .korean: "데스크탑", .chinese: "桌面", .french: "Bureau", .german: "Schreibtisch", .spanish: "Escritorio"],
        "folder.movies": [.english: "Movies", .vietnamese: "Phim", .japanese: "ムービー", .korean: "영화", .chinese: "电影", .french: "Films", .german: "Filme", .spanish: "Películas"],
        "folder.music": [.english: "Music", .vietnamese: "Nhạc", .japanese: "ミュージック", .korean: "음악", .chinese: "音乐", .french: "Musique", .german: "Musik", .spanish: "Música"],
        "folder.custom": [.english: "Choose Custom Folder...", .vietnamese: "Chọn thư mục tùy chỉnh...", .japanese: "カスタムフォルダを選択...", .korean: "사용자 지정 폴더 선택...", .chinese: "选择自定义文件夹...", .french: "Choisir un dossier personnalisé...", .german: "Benutzerdefinierten Ordner wählen...", .spanish: "Elegir carpeta personalizada..."],
        "folder.select": [.english: "Choose", .vietnamese: "Chọn", .japanese: "選択", .korean: "선택", .chinese: "选择", .french: "Choisir", .german: "Auswählen", .spanish: "Elegir"],

        "duplicate.done": [.english: "Done", .vietnamese: "Xong", .japanese: "完了", .korean: "완료", .chinese: "完成", .french: "Terminé", .german: "Fertig", .spanish: "Listo"],
        "duplicate.subtitle": [.english: "Find duplicate files and large files", .vietnamese: "Tìm tệp trùng lặp và tệp lớn", .japanese: "重複ファイルと大きなファイルを検索", .korean: "중복 파일 및 큰 파일 찾기", .chinese: "查找重复文件和大文件", .french: "Trouver les fichiers en double et les gros fichiers", .german: "Doppelte und große Dateien finden", .spanish: "Encontrar archivos duplicados y grandes"],
        "duplicate.tabDuplicates": [.english: "Duplicates", .vietnamese: "Trùng lặp", .japanese: "重複", .korean: "중복", .chinese: "重复", .french: "Doublons", .german: "Duplikate", .spanish: "Duplicados"],
        "duplicate.tabLargeFiles": [.english: "Large Files", .vietnamese: "Tệp lớn", .japanese: "大きなファイル", .korean: "큰 파일", .chinese: "大文件", .french: "Gros fichiers", .german: "Große Dateien", .spanish: "Archivos grandes"],

        // Large Files
        "largeFiles.title": [.english: "Large Files", .vietnamese: "Tệp lớn", .japanese: "大きなファイル", .korean: "큰 파일", .chinese: "大文件", .french: "Gros fichiers", .german: "Große Dateien", .spanish: "Archivos grandes"],
        "largeFiles.findLargeFiles": [.english: "Find Large Files", .vietnamese: "Tìm tệp lớn", .japanese: "大きなファイルを探す", .korean: "큰 파일 찾기", .chinese: "查找大文件", .french: "Trouver les gros fichiers", .german: "Große Dateien finden", .spanish: "Buscar archivos grandes"],
        "largeFiles.howItWorks": [.english: "Scan folders to find files larger than a minimum size threshold. Useful for reclaiming disk space taken by large downloads, media files, and archives.", .vietnamese: "Quét thư mục để tìm tệp lớn hơn kích thước tối thiểu. Hữu ích để giải phóng dung lượng từ các tệp tải lớn, phương tiện và lưu trữ.", .japanese: "フォルダをスキャンして最小サイズ以上のファイルを探します。大きなダウンロード、メディアファイル、アーカイブのディスク領域を解放するのに便利です。", .korean: "폴더를 스캔하여 최소 크기 이상의 파일을 찾습니다. 큰 다운로드, 미디어 파일, 아카이브의 디스크 공간을 확보하는 데 유용합니다.", .chinese: "扫描文件夹查找超过最小大小阈值的文件。有助于回收大型下载、媒体文件和存档占用的磁盘空间。", .french: "Analyse les dossiers pour trouver les fichiers dépassant une taille minimale. Utile pour récupérer l'espace disque pris par les gros téléchargements, fichiers médias et archives.", .german: "Scannt Ordner nach Dateien über einer Mindestgröße. Nützlich um Speicherplatz von großen Downloads, Mediendateien und Archiven freizugeben.", .spanish: "Escanea carpetas para encontrar archivos mayores a un tamaño mínimo. Útil para recuperar espacio en disco de grandes descargas, archivos multimedia y archivos."],
        "largeFiles.startScan": [.english: "Start Scan", .vietnamese: "Bắt đầu quét", .japanese: "スキャン開始", .korean: "스캔 시작", .chinese: "开始扫描", .french: "Démarrer l'analyse", .german: "Scan starten", .spanish: "Iniciar escaneo"],
        "largeFiles.minSize": [.english: "Min size:", .vietnamese: "Kích thước tối thiểu:", .japanese: "最小サイズ:", .korean: "최소 크기:", .chinese: "最小大小:", .french: "Taille min:", .german: "Mindestgröße:", .spanish: "Tamaño mínimo:"],
        "largeFiles.noLargeFiles": [.english: "No Large Files Found", .vietnamese: "Không tìm thấy tệp lớn", .japanese: "大きなファイルなし", .korean: "큰 파일 없음", .chinese: "未找到大文件", .french: "Aucun gros fichier trouvé", .german: "Keine großen Dateien gefunden", .spanish: "No se encontraron archivos grandes"],
        "largeFiles.noLargeFilesDesc": [.english: "No files larger than %@ were found in the selected folder.", .vietnamese: "Không tìm thấy tệp nào lớn hơn %@ MB trong thư mục đã chọn.", .japanese: "選択したフォルダには%@ MB以上のファイルはありませんでした。", .korean: "선택한 폴더에서 %@ MB 이상의 파일을 찾지 못했습니다.", .chinese: "在所选文件夹中未找到大于%@ MB的文件。", .french: "Aucun fichier supérieur à %@ n'a été trouvé dans le dossier sélectionné.", .german: "Keine Dateien größer als %@ im ausgewählten Ordner gefunden.", .spanish: "No se encontraron archivos mayores a %@ MB en la carpeta seleccionada."],
        "largeFiles.found": [.english: "found", .vietnamese: "tìm thấy", .japanese: "件", .korean: "개", .chinese: "个", .french: "trouvés", .german: "gefunden", .spanish: "encontrados"],
        "largeFiles.totalSize": [.english: "total", .vietnamese: "tổng cộng", .japanese: "合計", .korean: "총계", .chinese: "总计", .french: "total", .german: "gesamt", .spanish: "total"],
        "largeFiles.selectToClean": [.english: "Select files to clean up", .vietnamese: "Chọn tệp để dọn dẹp", .japanese: "クリーンするファイルを選択", .korean: "정리할 파일 선택", .chinese: "选择要清理的文件", .french: "Sélectionnez les fichiers à nettoyer", .german: "Dateien zum Bereinigen auswählen", .spanish: "Seleccione archivos para limpiar"],

        // Other
        "other.noAppsSelected": [.english: "No apps selected", .vietnamese: "Chưa chọn app nào", .japanese: "アプリが選択されていません", .korean: "선택된 앱 없음", .chinese: "未选择应用", .french: "Aucune app sélectionnée", .german: "Keine Apps ausgewählt", .spanish: "No hay apps seleccionadas"],
    ]

    static func string(_ key: String, language: AppLanguage) -> String { t[key]?[language] ?? t[key]?[.english] ?? key }

    static func string(_ key: String, language: AppLanguage, _ args: CVarArg...) -> String {
        let template = string(key, language: language)
        guard !args.isEmpty else { return template }
        return String(format: template, locale: Locale(identifier: language.rawValue), arguments: args)
    }
}
