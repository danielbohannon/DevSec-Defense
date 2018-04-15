$frmMain_OnLoad= {
  $m_BrushSize = New-Object Drawing.Rectangle(0, 0, $picDemo.Width, $picDemo.Height)

  $wm = [Drawing.Drawing2D.WrapMode]
  $cboWraM.Items.AddRange(@($wm::Clamp, $wm::Tile, $wm::TileFlipX, $wm::TileFlipY, $wm::TileFlipXY))
  $cboWraM.SelectedIndex = 0

  [int]$maxHatchStyle = 53

  for ($i = [Convert]::ToInt32([Drawing.Drawing2D.HatchStyle]::Min); $i -lt $maxHatchStyle; $i++) {
    $cboHatS.Items.Add([Drawing.Drawing2D.HatchStyle] $i)
  }
  $cboHatS.SelectedIndex = 0

  $lgm = [Drawing.Drawing2D.LinearGradientMode]
  $cboGraM.Items.AddRange(@($lgm::BackwardDiagonal, $lgm::ForwardDiagonal, `
                            $lgm::Horizontal, $lgm::Vertical))
  $cboGraM.SelectedIndex = 0
}

$btnCol1_OnClick= {
  $cdlg = New-Object Windows.Forms.ColorDialog

  if ($cdlg.ShowDialog() -eq [Windows.Forms.Dialogresult]::OK) {
    $col1 = $cdlg.Color
    $txtCol1.Text = $cdlg.Color.ToString()
    $txtCol1.BackColor = $cdlg.Color
  }
}

$btnCol2_OnClick= {
  $cdlg = New-Object Windows.Forms.ColorDialog

  if ($cdlg.ShowDialog() -eq [Windows.Forms.Dialogresult]::OK) {
    $col2 = $cdlg.Color
    $txtCol2.Text = $cdlg.Color.ToString()
    $txtCol2.BackColor = $cdlg.Color
  }
}

$cboBruS_OnSelectedIndexChanged= {
  switch ($cboBruS.Text) {
    "Large" {
      $m_BrushSize = New-Object Drawing.Rectangle(0, 0, $picDemo.Width, $picDemo.Height)
      break
    }
    "Medium" {
      $m_BrushSize = New-Object Drawing.Rectangle(0, 0, [Convert]::ToInt32($picDemo.Width / 2), `
                                                         [Convert]::ToInt32($picDemo.Height / 2))
      break
    }
    "Small" {
      $m_BrushSize = New-Object Drawing.Rectangle(0, 0, [Convert]::ToInt32($picDemo.Width / 4), `
                                                         [Convert]::ToInt32($picDemo.Height / 4))
      break
    }
  }
  RedrawPicture
}

function RedrawPicture {
  $picDemo.CreateGraphics().Clear([Drawing.Color]::White)
  $picDemo.Refresh()

  switch ($cboBruT.Text) {
    "Solid" {
      $txtCol2.Enabled = $false
      $btnCol2.Enabled = $false
      $cboBruS.Enabled = $false
      $cboWraM.Enabled = $false
      $cboHatS.Enabled = $false
      $nudRota.Enabled = $false
      $nudGraB.Enabled = $false
      $cboGraM.Enabled = $false

      $brush = New-Object Drawing.SolidBrush $col1
      break
    }
    "Hatch" {
      $txtCol1.Enabled = $true
      $btnCol1.Enabled = $true
      $txtCol2.Enabled = $true
      $btnCol2.Enabled = $true
      $cboBruS.Enabled = $false
      $cboWraM.Enabled = $false
      $cboHatS.Enabled = $true
      $nudRota.Enabled = $false
      $nudGraB.Enabled = $false
      $cboGraM.Enabled = $false

      $brush = New-Object `
    Drawing.Drawing2D.HatchBrush([Drawing.Drawing2D.HatchStyle]$cboHatS.SelectedItem, $col1, $col2)
      break
    }
    "Texture" {
      $txtCol1.Enabled = $false
      $btnCol1.Enabled = $false
      $txtCol2.Enabled = $false
      $btnCol2.Enabled = $false
      $cboBruS.Enabled = $true
      $cboWraM.Enabled = $true
      $cboHatS.Enabled = $false
      $nudRota.Enabled = $true
      $nudGraB.Enabled = $false
      $cboGraM.Enabled = $false

      $file = "$env:allusersprofile\\&#1044;&#1086;&#1082;&#1091;&#1084;&#1077;&#1085;&#1090;&#1099;\\&#1052;&#1086;&#1080; &#1088;&#1080;&#1089;&#1091;&#1085;&#1082;&#1080;\\&#1054;&#1073;&#1088;&#1072;&#1079;&#1094;&#1099; &#1088;&#1080;&#1089;&#1091;&#1085;&#1082;&#1086;&#1074;\\&#1047;&#1072;&#1082;&#1072;&#1090;.jpg"
      $pic = New-Object Drawing.Bitmap($file)
      $brush = New-Object Drawing.TextureBrush($pic, $m_BrushSize)
      $brush.WrapMode = [Drawing.Drawing2D.WrapMode]$cboWraM.SelectedItem
      $brush.RotateTransform([Convert]::ToSingle($nudRota.Value))
      break
    }
    "LinearGradient" {
      $txtCol1.Enabled = $true
      $btnCol1.Enabled = $true
      $txtCol2.Enabled = $true
      $btnCol2.Enabled = $true
      $cboBruS.Enabled = $true
      $cboWraM.Enabled = $false
      $cboHatS.Enabled = $false
      $nudGraB.Enabled = $true
      $cboGraM.Enabled = $true

      $brush = New-Object Drawing.Drawing2D.LinearGradientBrush($m_BrushSize, $col1, $col2, `
                                 [Drawing.Drawing2D.LinearGradientMode]$cboGraM.SelectedItem)
      $brush.RotateTransform([Convert]::ToSingle($nudRota.Value))
      $brush.SetBlendTriangularShape([Convert]::ToSingle($nudGraB.Value))
      break
    }
  }

  $g = $picDemo.CreateGraphics()

  switch ($cboDraw.Text) {
    "Fill" {
      $g.FillRectangle($brush, 0, 0, $picDemo.Width, $picDemo.Height)
      break
    }
    "Ellipses" {
      $g.FillEllipse($brush, $picDemo.Width / 10, $picDemo.Height / 10, `
                             $picDemo.Width / 2, $picDemo.Height / 2)
      $g.FillEllipse($brush, $picDemo.Width / 3, $picDemo.Height / 3, `
                             $picDemo.Width / 2, $picDemo.Height / 2)
      break
    }
    "Lines" {
      $pen = New-Object Drawing.Pen($brush, 40)

      $g.DrawLine($pen, 0, 0, $picDemo.Width, $picDemo.Height)
      $g.DrawLine($pen, 0, 0, 0, $picDemo.Height)
      $g.DrawLine($pen, 0, 0, $picDemo.Height, 0)
      $g.DrawLine($pen, $picDemo.Width, 0, $picDemo.Width, $picDemo.Height)
      $g.DrawLine($pen, 0, $picDemo.Height, $picDemo.Width, $picDemo.Height)
      $g.DrawLine($pen, $picDemo.Width, 0, 0, $picDemo.Height)
      break
    }
  }
}

function ShowMainWindow {
  [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")

  [Windows.Forms.Application]::EnableVisualStyles()

  $col1 = [Drawing.Color]::Blue
  $col2 = [Drawing.Color]::White

  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MainMenu
  $mnuFile = New-Object Windows.Forms.MenuItem
  $mnuExit = New-Object Windows.Forms.MenuItem
  $mnuHelp = New-Object Windows.Forms.MenuItem
  $mnuInfo = New-Object Windows.Forms.MenuItem
  $lblBruT = New-Object Windows.Forms.Label
  $lblDraw = New-Object Windows.Forms.Label
  $lblCol1 = New-Object Windows.Forms.Label
  $lblCol2 = New-Object Windows.Forms.Label
  $lblBruS = New-Object Windows.Forms.Label
  $lblWraM = New-Object Windows.Forms.Label
  $lblHatS = New-Object Windows.Forms.Label
  $lblRota = New-Object Windows.Forms.Label
  $lblGraB = New-Object Windows.Forms.Label
  $lblGraM = New-Object Windows.Forms.Label
  $cboBruT = New-Object Windows.Forms.ComboBox
  $cboDraw = New-Object Windows.Forms.ComboBox
  $txtCol1 = New-Object Windows.Forms.TextBox
  $txtCol2 = New-Object Windows.Forms.TextBox
  $btnCol1 = New-Object Windows.Forms.Button
  $btnCol2 = New-Object Windows.Forms.Button
  $cboBruS = New-Object Windows.Forms.ComboBox
  $cboWraM = New-Object Windows.Forms.ComboBox
  $cboHatS = New-Object Windows.Forms.ComboBox
  $nudRota = New-Object Windows.Forms.NumericUpDown
  $nudGraB = New-Object Windows.Forms.NumericUpDown
  $cboGraM = New-Object Windows.Forms.ComboBox
  $picDemo = New-Object Windows.Forms.PictureBox

  #mnuMain
  $mnuMain.MenuItems.AddRange(@($mnuFile, $mnuHelp))

  #mnuFile
  $mnuFile.MenuItems.AddRange(@($mnuExit))
  $mnuFile.Text = "&File"

  #mnuExit
  $mnuExit.Shortcut = "CtrlX"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click( { $frmMain.Close() } )

  #mnuHelp
  $mnuHelp.MenuItems.AddRange(@($mnuInfo))
  $mnuHelp.Text = "&Help"

  #mnuInfo
  $mnuInfo.Text = "About..."
  $mnuInfo.Add_Click( { ShowAboutWindow } )

  #lblBruT
  $lblBruT.Location = New-Object Drawing.Point(8, 16)
  $lblBruT.Size = New-Object Drawing.Size(96, 23)
  $lblBruT.Text = "Brush Type:"

  #lblDraw
  $lblDraw.Location = New-Object Drawing.Point(8, 40)
  $lblDraw.Size = New-Object Drawing.Size(96, 23)
  $lblDraw.Text = "Drawing:"

  #lblCol1
  $lblCol1.Location = New-Object Drawing.Point(8, 80)
  $lblCol1.Size = New-Object Drawing.Size(96, 23)
  $lblCol1.Text = "Color 1:"

  #lblCol2
  $lblCol2.Location = New-Object Drawing.Point(8, 104)
  $lblCol2.Size = New-Object Drawing.Size(96, 23)
  $lblCol2.Text = "Color 2:"

  #lblBruS
  $lblBruS.Location = New-Object Drawing.Point(8, 152)
  $lblBruS.Size = New-Object Drawing.Size(96, 23)
  $lblBruS.Text = "Brush Size:"

  #lblWraM
  $lblWraM.Location = New-Object Drawing.Point(8, 184)
  $lblWraM.Size = New-Object Drawing.Size(96, 23)
  $lblWraM.Text = "Wrap Mode:"

  #lblHatS
  $lblHatS.Location = New-Object Drawing.Point(8, 216)
  $lblHatS.Size = New-Object Drawing.Size(96, 23)
  $lblHatS.Text = "Hatch Style:"

  #lblRota
  $lblRota.Location = New-Object Drawing.Point(8, 248)
  $lblRota.Size = New-Object Drawing.Size(96, 23)
  $lblRota.Text = "Rotation:"

  #lblGraB
  $lblGraB.Location = New-Object Drawing.Point(8, 280)
  $lblGraB.Size = New-Object Drawing.Size(104, 23)
  $lblGraB.Text = "Gradient Blend:"

  #lblGraM
  $lblGraM.Location = New-Object Drawing.Point(8, 312)
  $lblGraM.Size = New-Object Drawing.Size(104, 23)
  $lblGraM.Text = "Gradient Mode:"

  #cboBruT
  $cboBruT.Items.AddRange(@("Solid", "Hatch", "Texture", "LinearGradient"))
  $cboBruT.Location = New-Object Drawing.Point(112, 13)
  $cboBruT.SelectedItem = "Solid"
  $cboBruT.Size = New-Object Drawing.Size(176, 24)
  $cboBruT.Add_SelectedIndexChanged( { RedrawPicture } )

  #cboDraw
  $cboDraw.Items.AddRange(@("Fill", "Ellipses", "Lines"))
  $cboDraw.Location = New-Object Drawing.Point(112, 40)
  $cboDraw.SelectedItem = "Fill"
  $cboDraw.Size = New-Object Drawing.Size(176, 24)
  $cboDraw.Add_SelectedIndexChanged( { RedrawPicture } )

  #txtCol1
  $txtCol1.BackColor = "Blue"
  $txtCol1.Location = New-Object Drawing.Point(112, 77)
  $txtCol1.Size = New-Object Drawing.Size(144, 23)
  $txtCol1.Text = "Color [Blue]"
  $txtCol1.Add_TextChanged( { RedrawPicture } )

  #txtCol2
  $txtCol2.Location = New-Object Drawing.Point(112, 102)
  $txtCol2.Size = New-Object Drawing.Size(144, 23)
  $txtCol2.Text = "Color [White]"
  $txtCol2.Add_TextChanged( { RedrawPicture } )

  #btnCol1
  $btnCol1.Location = New-Object Drawing.Point(256, 76)
  $btnCol1.Size = New-Object Drawing.Size(32, 25)
  $btnCol1.Text = "..."
  $btnCol1.Add_Click($btnCol1_OnClick)

  #btnCol2
  $btnCol2.Location = New-Object Drawing.Point(256, 101)
  $btnCol2.Size = New-Object Drawing.Size(32, 25)
  $btnCol2.Text = "..."
  $btnCol2.Add_Click($btnCol2_OnClick)

  #cboBruS
  $cboBruS.Items.AddRange(@("Large", "Medium", "Small"))
  $cboBruS.Location = New-Object Drawing.Point(112, 149)
  $cboBruS.SelectedItem = "Large"
  $cboBruS.Size = New-Object Drawing.Size(176, 24)
  $cboBruS.Add_SelectedIndexChanged($cboBruS_OnSelectedIndexChanged)

  #cboWraM
  $cboWraM.Location = New-Object Drawing.Point(112, 181)
  $cboWraM.Size = New-Object Drawing.Size(176, 24)
  $cboWraM.Add_SelectedIndexChanged( { RedrawPicture } )

  #cboHatS
  $cboHatS.Location = New-Object Drawing.Point(112, 213)
  $cboHatS.Size = New-Object Drawing.Size(176, 24)
  $cboHatS.Add_SelectedIndexChanged( { RedrawPicture } )

  #nudRota
  [decimal]$nudRota.Increment = [int[]](5, 0, 0, 0)
  $nudRota.Location = New-Object Drawing.Point(112, 245)
  [decimal]$nudRota.Maximum = [int[]](180, 0, 0, 0)
  $nudRota.Size = New-Object Drawing.Size(176, 23)
  $nudRota.Add_ValueChanged( { RedrawPicture } )

  #nudGraB
  $nudGraB.DecimalPlaces = 2;
  [decimal]$nudGraB.Increment = [int[]](1, 0, 0, 65536)
  $nudGraB.Location = New-Object Drawing.Point(112, 277)
  [decimal]$nudGraB.Maximum = [int[]](1, 0, 0, 0)
  $nudGraB.Size = New-Object Drawing.Size(176, 23)
  [decimal]$nudGraB.Value = [int[]](1, 0, 0, 0)
  $nudGraB.Add_ValueChanged( { RedrawPicture } )

  #cboGraM
  $cboGraM.Location = New-Object Drawing.Point(112, 309)
  $cboGraM.Size = New-Object Drawing.Size(176, 24)
  $cboGraM.Add_SelectedIndexChanged( { RedrawPicture } )

  #picDemo
  $picDemo.BorderStyle = "FixedSingle"
  $picDemo.Location = New-Object Drawing.Point(304, 16)
  $picDemo.Size = New-Object Drawing.Size(312, 320)

  #frmMain
  $frmMain.ClientSize = New-Object Drawing.Size(626, 371)
  $frmMain.Controls.AddRange(@($lblBruT, $lblDraw, $lblCol1, $lblCol2, $lblBruS, $lblWraM, `
                               $lblHatS, $lblRota, $lblGraB, $lblGraM, $cboBruT, $cboDraw, `
                               $txtCol1, $txtCol2, $btnCol1, $btnCol2, $cboBruS, $cboWraM, `
                               $cboHatS, $nudRota, $nudGraB, $cboGraM, $picDemo))
  $frmMain.Font = New-Object Drawing.Font("Microsoft Sans Serif", 10)
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.MaximizeBox = $false
  $frmMain.Menu = $mnuMain
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Brushes"
  $frmMain.Add_Load($frmMain_OnLoad)

  [void]$frmMain.ShowDialog()
}

function ShowAboutWindow {
  $frmMain = New-Object Windows.Forms.Form
  $lblThis = New-Object Windows.Forms.Label
  $btnExit = New-Object Windows.Forms.Button

  #lblThis
  $lblThis.Location = New-Object Drawing.Point(5, 29)
  $lblThis.Size = New-Object Drawing.Size(330, 50)
  $lblThis.Text = "(C) 2012 Grigori Zakharov `n
  This is just an example that you can make better."
  $lblThis.TextAlign = "MiddleCenter"

  #btnExit
  $btnExit.Location = New-Object Drawing.Point(132, 97)
  $btnExit.Text = "Close"
  $btnExit.Add_Click( { $frmMain.Close() } )

  #frmMain
  $frmMain.ClientSize = New-Object Drawing.Size(350, 137)
  $frmMain.ControlBox = $false
  $frmMain.Controls.AddRange(@($lblThis, $btnExit))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.ShowInTaskbar = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "About..."

  [void]$frmMain.ShowDialog()
}

ShowMainWindow
