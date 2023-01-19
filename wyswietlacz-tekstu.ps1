Add-Type -AssemblyName System.Windows.Forms
$form = New-Object Windows.Forms.Form
$form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::None
$form.WindowState = [Windows.Forms.FormWindowState]::Maximized
$form.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
$label = New-Object Windows.Forms.Label
$label.Text = "



      Prosze o zwrot sprzetu do RASP laptop wraz z torba i zasilaczem
       telefon axxx 
       monitor xxxx 
       Nr. kontaktowy 500 500 500"
$label.AutoSize = $true
$label.Dock = [Windows.Forms.DockStyle]::None
$label.TextAlign = [Windows.Forms.ContentAlignment]::MiddleCenter
$label.Font = New-Object System.Drawing.Font("Arial", 30)
$label.Size = New-Object System.Drawing.Size(200,50)
$label.Padding = New-Object System.Windows.Forms.Padding(0,10,0,0)
$label.Top = 50
$label.Left = 10
$form.Controls.Add($label)

$form.ShowDialog()
