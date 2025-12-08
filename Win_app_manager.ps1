<#
.SYNOPSIS
    Windows Software Automation System
#>

# -------------------------------------------------------------------------
# Note: Run this via "Start.bat" to ensure Admin privileges.
# -------------------------------------------------------------------------

# 1. Admin Privilege Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Admin privileges required. Please right-click and select 'Run as Administrator'."
    Break
}

# 2. Initialize Storage
$ManualItems = @()

# 3. Define Software List
$AppList = @(
    # ==========================================
    # OS Enhancements
    # ==========================================
    @{ Type="Title"; Name="OS Enhancements" },
    @{ Type="Winget"; Id="Eassos.DiskGenius"; Name="DiskGenius"; Desc="Disk management and recovery tool." },
    @{ Type="Winget"; Id="BleachBit.BleachBit"; Name="BleachBit"; Desc="Disk cleaning tool." },
    @{ Type="Winget"; Id="ClashVergeRev.ClashVergeRev"; Name="Clash Verge Rev"; Desc="Proxy Client." },
    @{ Type="Winget"; Id="QL-Win.QuickLook"; Name="QuickLook"; Desc="File preview by pressing spacebar, bringing macOS QuickLook functionality to Windows." },
    @{ Type="Winget"; Id="OliverSchwendener.ueli"; Name="Ueli"; Desc="Launcher that requires some habit change, but becomes a productivity powerhouse once accustomed." },
    # @{ Type="Winget"; Id="9PFXXSHC64H3"; Name="Raycast"; Desc="Launcher that requires some habit change, but becomes a productivity powerhouse once accustomed." },

    # ==========================================
    # File & Software Management
    # ==========================================
    @{ Type="Title"; Name="File & Software Management" },
    @{ Type="Winget"; Id="GeekUninstaller.GeekUninstaller"; Name="Geek Uninstaller"; Desc="Uninstaller and cleanup tool." },
    @{ Type="Winget"; Id="Google.GoogleDrive"; Name="Google Drive"; Desc="Cloud drive and sync tool." },
    @{ Type="Manual"; Name="Resilio Sync"; Link="https://www.resilio.com/sync/"; Desc="P2P sync tool, no cloud storage." },
    @{ Type="Manual"; Name="Odrive sync"; Link="https://www.odrive.com/"; Desc="Unified cloud storage sync tool that connects to Google Drive/OneDrive/Dropbox, bypassing network and client restrictions." },
    @{ Type="Winget"; Id="7zip.7zip"; Name="7-Zip"; Desc="File compression and extraction tool." },
    @{ Type="Winget"; Id="TGRMNSoftware.BulkRenameUtility"; Name="Bulk Rename Utility"; Desc="Powerful rename tool that can handle almost any batch renaming requirement." },
    @{ Type="Winget"; Id="SoftDeluxe.FreeDownloadManager"; Name="Free Download Manager"; Desc="Download manager tool." },
    @{ Type="Winget"; Id="IPFS.IPFS-Desktop"; Name="IPFS Desktop"; Desc="Decentralized storage." },

    # ==========================================
    # Daily Use
    # ==========================================
    @{ Type="Title"; Name="Daily Use" },
    @{ Type="Winget"; Id="Google.Chrome.EXE"; Name="Google Chrome"; Desc="Browser." },
    @{ Type="Winget"; Id="Obsidian.Obsidian"; Name="Obsidian"; Desc="Notes and personal library." },
    @{ Type="Manual"; Name="Kuaitie"; Link="https://kuaitie.cloud/"; Desc="Clipboard sync tool with mobile device support." },
    @{ Type="Winget"; Id="ShareX.ShareX"; Name="ShareX"; Desc="Screenshot and screen recording tool with extensive shortcuts, supports scrolling capture, local highlighting, step annotation. Includes utilities: image stitching, splitting, adding borders to screenshots." },
    @{ Type="Winget"; Id="Uzero.ScanScan"; Name="Baimiao"; Desc="Screenshot OCR tool with high accuracy for Chinese text recognition." },
    @{ Type="Winget"; Id="VideoLAN.VLC"; Name="VLC Media Player"; Desc="Local multimedia player supporting a wide range of formats." },
    @{ Type="Winget"; Id="calibre.calibre"; Name="Calibre"; Desc="E-book management tool." },
    @{ Type="Winget"; Id="EuSoft.Eudic"; Name="Eudic Dictionary"; Desc="Dictionary software." },
    @{ Type="Winget"; Id="Tencent.WeChat"; Name="WeChat"; Desc="Dominant Chinese IM." },
    @{ Type="Winget"; Id="Tencent.QQMusic"; Name="QQ Music"; Desc="Rich music library." },
    @{ Type="Winget"; Id="NetEase.CloudMusic"; Name="NetEase Cloud Music"; Desc="Supplementary music library." },

    # ==========================================
    # Production Tools
    # ==========================================
    @{ Type="Title"; Name="Production Tools" },
    @{ Type="Winget"; Id="Microsoft.VisualStudioCode"; Name="VS Code"; Desc="Popular IDE." },
    @{ Type="Manual"; Name="YingDao"; Link="https://www.yingdao.com/"; Desc="Extremely powerful automation workflow tool, like iPhone Shortcuts on computer but much more powerful." },
    @{ Type="Winget"; Id="Xmind.Xmind"; Name="Xmind"; Desc="Mind Map." },
    @{ Type="Winget"; Id="Figma.Figma"; Name="Figma"; Desc="UI Design." },
    @{ Type="Winget"; Id="GIMP.GIMP.3"; Name="GIMP 3.0"; Desc="Lightweight image processing, free alternative to Photoshop. Complete basic features, fast startup, convenient for quick tasks like resizing. Can change tool shortcuts to Photoshop style." },
    @{ Type="Winget"; Id="Inkscape.Inkscape"; Name="Inkscape"; Desc="Vector graphics tool, free alternative to Illustrator. Opens .ai files with good fidelity, sufficient for downloading assets and saving as images." },
    @{ Type="Winget"; Id="SaeraSoft.CaesiumImageCompressor"; Name="Caesium"; Desc="Image compression tool." },
    @{ Type="Manual"; Name="Collagelt"; Link="https://www.collageitfree.com/"; Desc="Collage tool for quickly creating photo walls and mood boards. Free version has watermark." },
    @{ Type="Winget"; Id="HandBrake.HandBrake"; Name="HandBrake"; Desc="Large video compression for easy transfer. Also converts videos from other formats to MP4." }
)

# 4. Core Functions
function Ensure-App {
    param ([string]$Id, [string]$Name)
    Write-Host "   Checking: [$Name]..." -NoNewline
    
    # Check if installed
    $null = winget list --id $Id --exact --source winget 2>$null
    $isInstalled = $LASTEXITCODE -eq 0

    # Fallback for MS Store apps (Store ID detection)
    if (-not $isInstalled -and $Id -match "^[A-Z0-9]{12}$") {
        $null = winget list --id $Id --exact 2>$null
        $isInstalled = $LASTEXITCODE -eq 0
    }

    if ($isInstalled) {
        Write-Host " [Installed]" -NoNewline -ForegroundColor Yellow
        
        # Pre-check for updates
        $updateCheck = winget list --upgrade-available --id $Id --exact 2>$null
        
        if ($updateCheck -match $Id) {
            Write-Host " -> Update Found!" -ForegroundColor Cyan
            # ASCII Safe: Used ">>" instead of Emoji
            Write-Host "      >>  Starting Upgrade..." -ForegroundColor DarkGray
            winget upgrade --id $Id --silent --accept-package-agreements --accept-source-agreements
        } else {
            Write-Host " -> Up to date." -ForegroundColor Green
        }

    } else {
        Write-Host " [Missing] -> Installing..." -ForegroundColor Magenta
        # ASCII Safe: Used ">>" instead of Emoji
        Write-Host "      >>  Downloading..." -ForegroundColor DarkGray
        winget install --id $Id --silent --accept-package-agreements --accept-source-agreements
    }
}

function Show-Manual {
    param ([string]$Name, [string]$Link, [string]$Desc)
    Write-Host "   [Manual] $Name" -ForegroundColor DarkGray -NoNewline
    Write-Host " ($Desc)" -ForegroundColor DarkGray
    Write-Host "      URL: $Link" -ForegroundColor DarkGray
}

# 5. Execution Loop
Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Winget Automation System (Windows)" -ForegroundColor Cyan
Write-Host "=========================================================="

try {
    foreach ($Item in $AppList) {
        switch ($Item.Type) {
            "Title" {
                Write-Host ""
                Write-Host " $($Item.Name)" -ForegroundColor Magenta
                Write-Host " ----------------------------------" -ForegroundColor Gray
            }
            "Winget" {
                Ensure-App -Id $Item.Id -Name $Item.Name
            }
            "Manual" {
                Show-Manual -Name $Item.Name -Link $Item.Link -Desc $Item.Desc
                $ManualItems += $Item
            }
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# 6. Summary Report
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Execution Finished" -ForegroundColor Cyan
Write-Host "=========================================================="
Write-Host ""

if ($ManualItems.Count -gt 0) {
    Write-Host "To-Do List (Manual Download):" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
    foreach ($m in $ManualItems) {
        Write-Host " - $($m.Name)" -NoNewline -ForegroundColor White
        Write-Host " -> $($m.Link)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Tip: Ctrl+Click to open links." -ForegroundColor Gray
}

Write-Host "=========================================================="