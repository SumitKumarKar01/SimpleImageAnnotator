# Declare global variable for annotation data
$Global:AnnotationData = @{}

# Add necessary .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-ImageAnnotationForm {
    param (
        [string]$ImagePath
    )

    # Create the form
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Image Annotation"
    $Form.Size = [System.Drawing.Size]::new(800, 600)
    $Form.StartPosition = "CenterScreen"
    $Form.KeyPreview = $true  # Enable key event processing

    # Add a PictureBox to display the image
    $PictureBox = New-Object System.Windows.Forms.PictureBox
    $PictureBox.Size = [System.Drawing.Size]::new(600, 400)
    $PictureBox.Location = [System.Drawing.Point]::new(10, 10)
    $PictureBox.SizeMode = "Zoom"
    $PictureBox.Image = [System.Drawing.Image]::FromFile($ImagePath)
    $PictureBox.TabStop = $false  # Prevent PictureBox from intercepting Tab key
    $Form.Controls.Add($PictureBox)

    # Add text boxes and labels for inputs
    $Labels = "Theme", "Sub-Theme", "Category", "Annotation"
    $TextBoxes = @()

    for ($i = 0; $i -lt $Labels.Count; $i++) {
        # Create and configure labels
        $Label = New-Object System.Windows.Forms.Label
        $Label.Text = $Labels[$i]
        $Label.Location = [System.Drawing.Point]::new(10, 420 + ($i * 30))
        $Form.Controls.Add($Label)

        # Create and configure textboxes
        $TextBox = New-Object System.Windows.Forms.TextBox
        $TextBox.Size = [System.Drawing.Size]::new(250, 30)
        $TextBox.Location = [System.Drawing.Point]::new(150, 420 + ($i * 30))
        $Form.Controls.Add($TextBox)
        $TextBoxes += $TextBox
    }

    # Add a button to save the data
    $SaveButton = New-Object System.Windows.Forms.Button
    $SaveButton.Text = "Save"
    $SaveButton.Location = [System.Drawing.Point]::new(300, 540)
    $Form.Controls.Add($SaveButton)

    # Button click event
    $SaveButton.Add_Click({
        # Collect the data from the textboxes and update the global variable
        $Global:AnnotationData = @{
            Theme      = $TextBoxes[0].Text
            SubTheme   = $TextBoxes[1].Text
            Category   = $TextBoxes[2].Text
            Annotation = $TextBoxes[3].Text
        }

        Write-Host "Annotation Data Captured: $($Global:AnnotationData | Out-String)"
        $Form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $Form.Close()
    })

    # Focus on the first textbox when the form loads
    $Form.Add_Shown({
        $TextBoxes[0].Focus()
    })

    # Show the form
    if ($Form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $Global:AnnotationData
    } else {
        Write-Host "Form was closed without saving."
        return $null
    }
}

function Process-Images {
    param (
        [string]$ImageDirectory,
        [string]$OutputFile
    )

    # Check if the output file exists and read existing annotations
    $AnnotatedImages = @{}
    if (Test-Path $OutputFile) {
        $AnnotatedImages = Import-Csv -Path $OutputFile | ForEach-Object { $_.ImageName }
    }

    # Get all image files in the directory
    $imageFiles = Get-ChildItem -Path $ImageDirectory -Recurse -File -Include *.jpg, *.png, *.jpeg

    # Filter out already annotated images
    $unannotatedImages = $imageFiles | Where-Object { $_.Name -notin $AnnotatedImages }

    if ($unannotatedImages.Count -eq 0) {
        Write-Host "No new images to annotate."
        return
    } else {
        Write-Host "$($unannotatedImages.Count) unannotated image(s) found."
    }

    # Loop through all unannotated images
    $unannotatedImages | ForEach-Object {
        $ImagePath = $_.FullName
        $RelativePath = $_.DirectoryName -replace [regex]::Escape($ImageDirectory), ""

        # Show the annotation form for each image
        $Annotation = Show-ImageAnnotationForm -ImagePath $ImagePath
        if ($Annotation) {
            Write-Host "Annotation received: $($Annotation | Out-String)"

            $ImageData = [PSCustomObject]@{
                ImageName      = $_.Name
                Theme          = $Annotation.Theme
                SubTheme       = $Annotation.SubTheme
                Category       = $Annotation.Category
                Annotation     = $Annotation.Annotation
                ImageDirectory = $RelativePath.TrimStart('\')
            }

            # Append data to the CSV file
            $ImageData | Export-Csv -Path $OutputFile -NoTypeInformation -Append

            Write-Host "Data saved to $OutputFile"
        }
    }
}

# Set parameters
$ImageDirectory = "C:\Users\Sumit\Downloads\Graffiti Image - Preprocessed (DO  NOT UPLOAD)"  # Replace with your image directory
$OutputFile = "C:\Users\Sumit\Documents\ImageAnnotations.csv"

# Run the script
Process-Images -ImageDirectory $ImageDirectory -OutputFile $OutputFile
