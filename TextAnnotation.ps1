# Declare global variables
$Global:AnnotationData = @{}
$Global:ImageList = @()
$Global:CurrentIndex = 0

# Add .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define output CSV path
$Global:OutputFile = "D:\Project\July\ImageAnnotations-TextPresence.csv"

# Load existing annotations
if (Test-Path $Global:OutputFile) {
    $Global:AnnotatedImages = Import-Csv -Path $Global:OutputFile | Select-Object -ExpandProperty ImageName
} else {
    $Global:AnnotatedImages = @()
}

# Global form elements
$Form = New-Object System.Windows.Forms.Form
$PictureBox = New-Object System.Windows.Forms.PictureBox
$RadioYes = New-Object System.Windows.Forms.RadioButton
$RadioNo = New-Object System.Windows.Forms.RadioButton
$TextBox = New-Object System.Windows.Forms.TextBox
$SubmitButton = New-Object System.Windows.Forms.Button

function Update-FormContent {
    $ImagePath = $Global:ImageList[$Global:CurrentIndex]
    if ($PictureBox.Image -ne $null) {
        $PictureBox.Image.Dispose()
    }    
    $PictureBox.Image = [System.Drawing.Image]::FromFile($ImagePath)
    $RadioYes.Checked = $false
    $RadioNo.Checked = $false
    $TextBox.Text = ""
    $TextBox.Visible = $false
}

function Show-SingleForm {
    $Form.Text = "Image Annotation - Text Presence"
    $Form.Size = [System.Drawing.Size]::new(800, 600)
    $Form.StartPosition = "CenterScreen"

    $PictureBox.Size = [System.Drawing.Size]::new(600, 400)
    $PictureBox.Location = [System.Drawing.Point]::new(($Form.ClientSize.Width - $PictureBox.Width) / 2, 10)
    $PictureBox.SizeMode = "Zoom"
    $Form.Controls.Add($PictureBox)

    $RadioYes.Text = "Yes"
    $RadioYes.AutoSize = $true
    $RadioYes.Location = [System.Drawing.Point]::new(($Form.ClientSize.Width / 2) - 50, 420)
    $Form.Controls.Add($RadioYes)

    $RadioNo.Text = "No"
    $RadioNo.AutoSize = $true
    $RadioNo.Location = [System.Drawing.Point]::new(($Form.ClientSize.Width / 2) + 10, 420)
    $Form.Controls.Add($RadioNo)

    $TextBox.Size = [System.Drawing.Size]::new(500, 30)
    $TextBox.Location = [System.Drawing.Point]::new(($Form.ClientSize.Width - $TextBox.Width) / 2, 460)
    $TextBox.Visible = $false
    $Form.Controls.Add($TextBox)

    $RadioYes.Add_CheckedChanged({ $TextBox.Visible = $RadioYes.Checked })
    $RadioNo.Add_CheckedChanged({ if ($RadioNo.Checked) { $TextBox.Visible = $false } })

    $SubmitButton.Text = "Submit"
    $SubmitButton.Size = [System.Drawing.Size]::new(100, 30)
    $SubmitButton.Location = [System.Drawing.Point]::new(($Form.ClientSize.Width - $SubmitButton.Width) / 2, 500)
    $Form.Controls.Add($SubmitButton)

    $SubmitButton.Add_Click({
        $CurrentImageName = [System.IO.Path]::GetFileName($Global:ImageList[$Global:CurrentIndex])
        $ContainsText = $RadioYes.Checked
        $AnnotatedText = if ($ContainsText) { $TextBox.Text } else { "N/A" }

        $ImageData = [PSCustomObject]@{
            ImageName     = $CurrentImageName
            ContainsText  = $ContainsText
            AnnotatedText = $AnnotatedText
        }

        $ImageData | Export-Csv -Path $Global:OutputFile -NoTypeInformation -Append -Encoding UTF8
        Write-Host "Saved: $($ImageData | Out-String)"

        $Global:CurrentIndex++
        if ($Global:CurrentIndex -lt $Global:ImageList.Count) {
            Update-FormContent
        } else {
            [System.Windows.Forms.MessageBox]::Show("Annotation Completed!", "Done", "OK", "Information")
            $Form.Close()
        }
    })

    Update-FormContent
    $Form.ShowDialog() | Out-Null
}

function Invoke-Images {
    param (
        [string]$ImageDirectory
    )

    $Global:ImageList = (Get-ChildItem -Path $ImageDirectory -Recurse -File -Include *.jpg, *.jpeg, *.png).FullName
    $Global:ImageList = $Global:ImageList | Where-Object { (Split-Path $_ -Leaf) -notin $Global:AnnotatedImages }

    if ($Global:ImageList.Count -gt 0) {
        Show-SingleForm
    } else {
        Write-Host "All images have been annotated!"
    }
}

# Set directory and run
$ImageDirectory = "D:\Project\July\PreprocessedGraffitiImages(DO NOT UPLOAD)\PreprocessedGraffitiImages"
Invoke-Images -ImageDirectory $ImageDirectory
