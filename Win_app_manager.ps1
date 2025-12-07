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
    @{ Type="Winget"; Id="Eassos.DiskGenius"; Name="DiskGenius (Disk Recovery)" },
    @{ Type="Winget"; Id="BleachBit.BleachBit"; Name="BleachBit (Disk Cleaner)" },
    @{ Type="Winget"; Id="ClashVergeRev.ClashVergeRev"; Name="Clash Verge Rev (Proxy Client)" },
    @{ Type="Winget"; Id="QL-Win.QuickLook"; Name="QuickLook (File Preview)" },
    @{ Type="Winget"; Id="OliverSchwendener.ueli"; Name="Ueli (Launcher)" },
    # @{ Type="Winget"; Id="9PFXXSHC64H3"; Name="Raycast (Launcher Beta)" },

    # ==========================================
    # File & Software Management
    # ==========================================
    @{ Type="Title"; Name="File & Software Management" },
    @{ Type="Winget"; Id="GeekUninstaller.GeekUninstaller"; Name="Geek Uninstaller" },
    @{ Type="Winget"; Id="Google.GoogleDrive"; Name="Google Drive" },
    @{ Type="Manual"; Name="Resilio Sync"; Link="https://www.resilio.com/sync/"; Desc="P2P File Sync" },
    @{ Type="Manual"; Name="Odrive sync"; Link="https://www.odrive.com/"; Desc="Unified Cloud Storage" },
    @{ Type="Winget"; Id="7zip.7zip"; Name="7-Zip" },
    @{ Type="Winget"; Id="TGRMNSoftware.BulkRenameUtility"; Name="Bulk Rename Utility" },
    @{ Type="Winget"; Id="SoftDeluxe.FreeDownloadManager"; Name="Free Download Manager" },
    @{ Type="Winget"; Id="IPFS.IPFS-Desktop"; Name="IPFS Desktop" },

    # ==========================================
    # Daily Use
    # ==========================================
    @{ Type="Title"; Name="Daily Use" },
    @{ Type="Winget"; Id="Google.Chrome.EXE"; Name="Google Chrome" },
    @{ Type="Winget"; Id="Obsidian.Obsidian"; Name="Obsidian (Notes)" },
    @{ Type="Winget"; Id="Xmind.Xmind"; Name="Xmind (Mind Map)" },
    @{ Type="Manual"; Name="Kuaitie"; Link="https://kuaitie.cloud/"; Desc="Clipboard Sync" },
    @{ Type="Winget"; Id="ShareX.ShareX"; Name="ShareX (Screen Capture)" },
    @{ Type="Winget"; Id="Uzero.ScanScan"; Name="Baimiao (OCR Tool)" },
    @{ Type="Winget"; Id="VideoLAN.VLC"; Name="VLC Media Player" },
    @{ Type="Winget"; Id="calibre.calibre"; Name="Calibre (E-book)" },
    @{ Type="Winget"; Id="EuSoft.Eudic"; Name="Eudic Dictionary" },
    @{ Type="Winget"; Id="Tencent.WeChat"; Name="WeChat" },
    @{ Type="Winget"; Id="Tencent.QQMusic"; Name="QQ Music" },
    @{ Type="Winget"; Id="NetEase.CloudMusic"; Name="NetEase Cloud Music" },

    # ==========================================
    # Production Tools
    # ==========================================
    @{ Type="Title"; Name="Production Tools" },
    @{ Type="Winget"; Id="Microsoft.VisualStudioCode"; Name="VS Code" },
    @{ Type="Manual"; Name="YingDao"; Link="https://www.yingdao.com/"; Desc="RPA Automation" },
    @{ Type="Winget"; Id="Figma.Figma"; Name="Figma (UI Design)" },
    @{ Type="Winget"; Id="GIMP.GIMP.3"; Name="GIMP 3.0 (Beta)" },
    @{ Type="Winget"; Id="Inkscape.Inkscape"; Name="Inkscape (Vector Graphics)" },
    @{ Type="Winget"; Id="SaeraSoft.CaesiumImageCompressor"; Name="Caesium (Image Compressor)" },
    @{ Type="Manual"; Name="Collagelt"; Link="https://www.collageitfree.com/"; Desc="Photo Collage" },
    @{ Type="Winget"; Id="HandBrake.HandBrake"; Name="HandBrake (Video Transcoder)" }
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