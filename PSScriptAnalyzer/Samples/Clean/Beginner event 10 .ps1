#
# Summer 2009 Scripting games 
# Beginner Event 10 - The 1,500-Meter race
# http://blogs.technet.com/heyscriptingguy/archive/2009/06/18/hey-scripting-guy-2009-scripting-games-event-10-details-beginner-and-advanced-1-500-meter-race.aspx
#
# ToDo: In this event, you must write a script that will count down from three minutes 
# to zero seconds. When the three minutes have expired,
# display a message indicating that the given amount of time has elapsed. 
#
# This solution uses the .Net System.Windows.Form and ...Drawing classes to produce a kind
# of GUI with a "stop-watch touch"
#
# The Start-Button starts the countdwon ... not very surpisingly :-)
# The countdown can be suspended by pressing the Stop-Button ... obviously
# You can Set the countdown timer in a range up to an hour ( 59:59 [mm:ss] )
# using the Set-Button. After entering a new valid mm:ss value press the Set-Button again
# to take these new values into effect
# I won't tell you, what the Exit-button might do for us :-)
#
# All the positioning and sizing has been done using the VS2008 designer too to avoid me
# having a heart attack trying to adjust pixelwise ... 
# But I'm no artist, so I didn't spent too much time beautifying the layout!
#
# Klaus Schulte, 06/26/2009

# It'll be a three minutes countdown
$Script:countdownTime = 3*60

#
# This is the usual more a less VStudio 2008 designer generated "don't touch me" part of the code
# used to define the Form derived visual components 
#
function InitializeComponent ()
{
    # load the required additional GUI assemblies  
    [void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][reflection.assembly]::LoadWithPartialName("System.Drawing")

    # We will have the form itself, a textbox displaying the remainig time,
    # four buttons to control the countdown and ( surprise, surprise! ) a timer :-)
    # It is good to have a timer for the heavy work that allows us to asynchronically
    # react on timer events that would otherwise block the GUI and make it unresponsive
    # if we use busy, active wait loops or a Sleep command to control the clock
    
    $formCountdown = New-Object System.Windows.Forms.Form
    $tbRemainingTime = New-Object System.Windows.Forms.TextBox
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStop = New-Object System.Windows.Forms.Button
    $btnSet = New-Object System.Windows.Forms.Button
    $btnExit = New-Object System.Windows.Forms.Button
    $timer1 = New-Object System.Windows.Forms.Timer
    $formCountdown.SuspendLayout()
    # 
    # tbRemainingTime
    # I used the Algerian font, size 72 here, which you can easily change to your gusto
    # The digits should be red on black background
    # Only up to 5 chars can be entered into this textbox
    # 
    $tbRemainingTime.BackColor = [System.Drawing.Color]::Black
    $tbRemainingTime.Font = New-Object System.Drawing.Font "Algerian", 72
    $tbRemainingTime.ForeColor = [System.Drawing.Color]::Red
    $tbRemainingTime.Location = New-Object System.Drawing.Point(0, 0)
    $tbRemainingTime.MaxLength = 5
    $tbRemainingTime.Name = "tbRemainingTime"
    $tbRemainingTime.Size = New-Object System.Drawing.Size(270, 134)
    $tbRemainingTime.TabIndex = 0
    # 
    # btnStart
    # There is a lightgreen Start-button with a btnStart_Click eventhandler
    # 
    $btnStart.BackColor = [System.Drawing.Color]::LightGreen
    $btnStart.Font = New-Object System.Drawing.Font "Courier New", 12
    $btnStart.Location = New-Object System.Drawing.Point(269, 0)
    $btnStart.Name = "btnStart"
    $btnStart.Size = New-Object System.Drawing.Size(82, 32)
    $btnStart.TabIndex = 0
    $btnStart.Text = "Start"
    $btnStart.UseVisualStyleBackColor = $false
    $btnStart.Add_Click({btnStart_Click})
    # 
    # btnStop
    # ... there is a salmon(lighted) Start-button with a btnStop_Click eventhandler
    # 
    $btnStop.BackColor = [System.Drawing.Color]::Salmon
    $btnStop.Enabled = $false
    $btnStop.Font = New-Object System.Drawing.Font "Courier New", 12
    $btnStop.Location = New-Object System.Drawing.Point(269, 32)
    $btnStop.Name = "btnStop"
    $btnStop.Size = New-Object System.Drawing.Size(82, 32)
    $btnStop.TabIndex = 1
    $btnStop.Text = "Stop"
    $btnStop.UseVisualStyleBackColor = $false
    $btnStop.Add_Click({btnStop_Click})
    # 
    # btnSet
    # ... there is a yellow Set-button with a btnSet_Click eventhandler
    # 
    $btnSet.BackColor = [System.Drawing.Color]::Yellow
    $btnSet.Font = New-Object System.Drawing.Font "Courier New", 12
    $btnSet.Location = New-Object System.Drawing.Point(269, 64)
    $btnSet.Name = "btnSet"
    $btnSet.Size = New-Object System.Drawing.Size(82, 32)
    $btnSet.TabIndex = 2
    $btnSet.Text = "Set"
    $btnSet.UseVisualStyleBackColor = $false
    $btnSet.Add_Click({btnSet_Click})
    # 
    # btnExit
    # ... and a white Exit-button with a btnExit_Click eventhandler
    # 
    $btnExit.BackColor = [System.Drawing.Color]::White
    $btnExit.Font = New-Object System.Drawing.Font "Courier New", 12
    $btnExit.Location = New-Object System.Drawing.Point(269, 96)
    $btnExit.Name = "btnExit"
    $btnExit.Size = New-Object System.Drawing.Size(82, 32)
    $btnExit.TabIndex = 3
    $btnExit.Text = "Exit"
    $btnExit.UseVisualStyleBackColor = $false
    $btnExit.Add_Click({btnExit_Click})
    # 
    # timer1
    # the timer has an eventhadler timer1_tick attached to it
    # 
    $timer1.Add_Tick({timer1_Tick})
    $timer1.Stop()
    #
    # 
    # frmCountdown
    # The rest of the form is defined here
    # and all the previously defined controls are added to it
    #
    $formCountdown.BackColor = [System.Drawing.Color]::Black
    $formCountdown.ClientSize = New-Object System.Drawing.Size(349, 127)
    # $formCountdown.ControlBox = $false
    $formCountdown.Controls.Add($btnExit)
    $formCountdown.Controls.Add($btnSet)
    $formCountdown.Controls.Add($btnStop)
    $formCountdown.Controls.Add($btnStart)
    $formCountdown.Controls.Add($tbRemainingTime)
    $formCountdown.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $formCountdown.MaximizeBox = $false
    $formCountdown.MinimizeBox = $false
    $formCountdown.Name = "formCountdown"
    $formCountdown.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
    $formCountdown.Text = "Countdown"
    $formCountdown.ResumeLayout($false)
    $formCountdown.PerformLayout()
    $formCountdown.Load
    #
    # To have a well defined start state, we preset some properties of the controls here
    #
    $btnStart.Enabled = $true
    $btnStop.Enabled = $false
    $btnSet.Enabled = $true
    $btnExit.Enabled = $true
    $tbRemainingTime.ReadOnly = $true
    DisplayCountdownTime($Script:countdownTime)
    $formCountdown.ShowDialog()
}

#
# The Exit Button eventhandler just closes the form which shutsdown the application
# All the cleanup stuff could be done here especially if COM objects have been allocated
# you should release them somewhere before you shut the application down.
#
function btnExit_Click()
{
    $formCountdown.Close()
}

#
# the Set Button event handler distinguishes between two "modes"
# depending on the readonly property of the (remaing countdowntime) textbox
# If you press the Set Button once, you enter edit mode to change the value
# of the countdown. Having changed the value you should hit the Set-button again
# to commit the changes. Before the commit is performed the string is checked
# against the regular expression $TimePattern to validate it. if it is invalid
# you are prompted with an error message and stay in set mode, otherwise the new
# value is used to start the countdown.  
#
function btnSet_Click()
{
    $TimePattern = "[0-5][0-9]:[0-5][0-9]"
    
    if ($tbRemainingTime.ReadOnly)
    {
        $btnStart.Enabled = $false
        $btnStop.Enabled = $false
        $btnSet.Enabled = $true
        $btnExit.Enabled = $true
        $tbRemainingTime.ReadOnly = $false
        $tbRemainingTime.BackColor = [System.Drawing.Color]::White
        $tbRemainingTime.Focus
    }
    else
    {
        if (!([regex]::IsMatch($tbRemainingTime.Text, $TimePattern)))
        {
            [Windows.Forms.MessageBox]::Show("Please enter a time value in the form of 'mm:ss`r`n" `
                + "where 'mm' and 'ss' are less or equal to '59'")
            return
        }
        $Script:countdownTime = 60 * [int]($tbRemainingTime.Text.Substring(0, 2)) +
            [int]($tbRemainingTime.Text.Substring(3, 2))
        DisplayCountdownTime($Script:countdownTime)

        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        $btnSet.Enabled = $true
        $btnExit.Enabled = $true
        $tbRemainingTime.BackColor = [System.Drawing.Color]::Black
        $tbRemainingTime.ReadOnly = $true
    }
}

#
# Pressing the Stop-Button will pause the countdown
#
function btnStop_Click()
{
    $timer1.Stop()
    $btnStart.Enabled = $true
    $btnStop.Enabled = $false
    $btnSet.Enabled = $true
    $btnExit.Enabled = $true
    [Windows.Forms.MessageBox]::Show("Countdown paused!")
}

#
# Pressing the Start-Button will start the countdown
# The Timer interval is set to 1000 ms, which allows us to see a change of the countdown value
# each second
#
function btnStart_Click()
{
    $btnStart.Enabled = $false
    $btnStop.Enabled = $true
    $btnSet.Enabled = $false
    $btnExit.Enabled = $true
    $timer1.Interval = 1000
    $timer1.Start()
}

#
# just a helper function to convert an [int] to the display format: 'mm:ss' 
# Values greater or equal to an hour are SilentlyIgnored :-)
#
function DisplayCountdownTime($seconds)
{
    if ($seconds -lt 60*60)
    {
        $tbRemainingTime.Text = [string]::Format("{0:00}:{1:00}",
            [Math]::floor($seconds / 60), $seconds % 60)
    }
}

#
# this function just decrents the remaining time to countdown by one and displays the new value
# if the remaining time is greater than zero. If it is zero, the countdown is over and the requested
# message is displayed. The countdown could be restarted setting another value now. 
#
function Countdown()
{
    $Script:countdownTime--
    DisplayCountdownTime($Script:countdownTime)
    if ($Script:countdownTime -le 0)
    {
        $timer1.Stop()
        $btnStart.Enabled = $false
        $btnStop.Enabled = $false
        $btnSet.Enabled = $true
        $btnExit.Enabled = $true
        [Windows.Forms.MessageBox]::Show("Countdown finished!")
    }
}

#
# The timer event handler fires each second and calls Countdown to do the work
#
function timer1_Tick()
{
    Countdown
}

#
# The main entry point to to what it is called ,..
#
InitializeComponent

