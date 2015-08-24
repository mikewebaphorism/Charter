' 
'   Start Mad Men
'

Function doMadMen() As Integer

    o = SetupStream("MadMen")
    o.setup()
    o.paint()   
    o.eventloop()

End Function

Sub SetupStream(streamW) As Object

    streamW = "Default"

    this = {
        port:      CreateObject("roMessagePort")
        progress:  0 'buffering progress
        position:  0 'playback position (in seconds)
        paused:    false 'is the video currently paused?
        fonts:     CreateObject("roFontRegistry") 'global font registry
        canvas:    CreateObject("roImageCanvas") 'user interface
        player:    CreateObject("roVideoPlayer")
        setup:     SetupFramedCanvas
        paint:     PaintFramedCanvas
        eventloop: EventLoop
    } 

    this.help = "Mad Men the show live :  EST 813-817 0390 "
    this.fonts.Register("pkg:/fonts/caps.otf")
    this.textcolor = "#406040"

    'Setup image canvas:
    this.canvas.SetMessagePort(this.port)
    this.canvas.SetLayer(0, { Color: "#000000" })
    this.canvas.Show()

    '  I made some edits here to move location of video
    'Resolution-specific settings:
    mode = CreateObject("roDeviceInfo").GetDisplayMode()
    if mode = "720p"
        this.layout = {
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   0, w:1280, h: 130 }
            left:   { x: 665, y: 177, w: 391, h: 291 }
            right:  { x: 700, y: 177, w: 350, h: 291 }
            bottom: { x: 300, y: 550, w: 780, h: 300 }
        }
        this.background = "pkg:/images/back-hd.jpg"
        this.headerfont = this.fonts.get("lmroman10 caps", 50, 50, false)
    else 
        this.layout = { 
            full:   this.canvas.GetCanvasRect()
            top:    { x:   0, y:   0, w: 720, h:  80 }
            left:   { x: 100, y: 100, w: 280, h: 210 }
            right:  { x: 400, y: 100, w: 220, h: 210 }
            bottom: { x: 100, y: 340, w: 520, h: 140 }
        }
        this.background = "pkg:/images/back-sd.jpg"
        this.headerfont = this.fonts.get("lmroman10 caps", 30, 50, false) 
    end if 
  
    this.player.SetMessagePort(this.port)
    this.player.SetLoop(true)
    this.player.SetPositionNotificationPeriod(1)
    this.player.SetDestinationRect(this.layout.left)
    this.player.SetContentList([{
        'Stream: { url: "http://sike42.blob.core.windows.net/videos/20140625210730.mp4" }
        Stream : { url: "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"  }   

        StreamFormat: "hls"
        SwitchingStrategy: "full-adaptation"
    }])
    this.player.Play()

    return this
End Sub

Sub EventLoop()

nag = 0

    while true
        msg = wait(0, m.port)
 


        if msg <> invalid
            'If this is a startup progress status message, record progress
            'and update the UI accordingly:
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                end if

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                m.paint()

            'If the <UP> key is pressed, jump out of this context:
            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                if index = 2  '<UP>
                    return
                else if index = 3 '<DOWN> (toggle fullscreen)
                        if m.paint = PaintFullscreenCanvas
                        m.setup = SetupFramedCanvas
                        m.paint = PaintFramedCanvas
                        rect = m.layout.left
                      else
                         m.setup = SetupFullscreenCanvas
                         m.paint = PaintFullscreenCanvas
                         rect = { x:0, y:0, w:0, h:0 } 'fullscreen
                         m.player.SetDestinationRect(0, 0, 0, 0) 'fullscreen
                      end if
                       m.setup()
                       m.player.SetDestinationRect(rect)
                

                else if index = 4 or index = 8  '<LEFT> or <REV>
                   ' m.position = m.position - 60
                    ' m.player.Seek(m.position * 1000)
                   return


                else if index = 5 or index = 9  '<RIGHT> or <FWD>
                  '  m.position = m.position + 60
                  '  m.player.Seek(m.position * 1000)


                   return 

                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
                end if

            else if msg.isPaused()
                m.paused = true
                m.paint()

            else if msg.isResumed()
                m.paused = false
                m.paint()

            end if
            'Output events for debug
            print msg.GetType(); ","; msg.GetIndex(); ": "; msg.GetMessage()
            if msg.GetInfo() <> invalid print msg.GetInfo();
        end if
    end while
End Sub

Sub SetupFullscreenCanvas()
    m.canvas.AllowUpdates(false)
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintFullscreenCanvas()
    list = []

    if m.progress < 100
        color = "#000000" 'opaque black
        list.Push({
            Text: "Loading...2" + m.progress.tostr() + "%"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else if m.paused
        color = "#80000000" 'semi-transparent black
        list.Push({
            Text: "Paused"
            TextAttrs: { font: "huge" }
            TargetRect: m.layout.full
        })
    else
        color = "#00000000" 'fully transparent
    end if

    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)
End Sub



Sub SetupFramedCanvas()
    m.canvas.AllowUpdates(false)
    m.canvas.Clear()
    m.canvas.SetLayer(0, [
        { 'Background:
            Url: m.background
            CompositionMode: "Source"
        },
        { 'The title:
            Text: "  "
             TargetRect: m.layout.top
            TextAttrs: { valign: "bottom", font: m.headerfont, color: m.textcolor }
        },
        { 'Help text:
            Text: m.help
            TargetRect: m.layout.right
            TextAttrs: { halign: "left", valign: "top", color: m.textcolor }
        }
    ])
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintFramedCanvas()
    list = []
    if m.progress < 100  'Video is currently buffering
        list.Push({
            Color: "#80000000"
            TargetRect: m.layout.left
        })
        list.Push({
            Text: "Loading...4" + m.progress.tostr() + "%"
            TargetRect: m.layout.left
        })
    else  'Video is currently playing
        if m.paused
            list.Push({
                Color: "#80000000"
                TargetRect: m.layout.left
                CompositionMode: "Source"
            })
            list.Push({
                Text: "Paused"
                TargetRect: m.layout.left
            })
        else  'not paused
            list.Push({
                Color: "#00000000"
                TargetRect: m.layout.left
                CompositionMode: "Source"
            })
        end if
        list.Push({
            Text: "Current position: " + m.position.tostr() + " seconds"
            TargetRect: m.layout.bottom
            TextAttrs: { halign: "left", valign: "top", color: m.textcolor }



        })
    end if
    m.canvas.SetLayer(1, list)
End Sub





'''''  Put here





'***************************************************************
' The retryInterval is used to control how often we retry and
' check for registration success. its generally sent by the
' service and if this hasn't been done, we just return defaults 
'***************************************************************
Function getRetryInterval() As Integer
    if m.retryInterval < 1 then m.retryInterval = 30
    return m.retryInterval
End Function


'**************************************************************
' The retryDuration is used to control how long we attempt to 
' retry. this value is generally obtained from the service
' if this hasn't yet been done, we just return the defaults 
'**************************************************************
Function getRetryDuration() As Integer
    if m.retryDuration < 1 then m.retryDuration = 900
    return m.retryDuration
End Function


'******************************************************
'Load/Save RegistrationToken to registry
'******************************************************

Function loadRegistrationToken() As dynamic
    m.RegToken =  RegRead("RegToken", "Authentication")
    if m.RegToken = invalid then m.RegToken = ""
    return m.RegToken 
End Function

Sub saveRegistrationToken(token As String)
    RegWrite("RegToken", token, "Authentication")
End Sub

Sub deleteRegistrationToken()
    RegDelete("RegToken", "Authentication")
    m.RegToken = ""
End Sub

Function isLinked() As Dynamic
    if Len(m.RegToken) > 0  then return true
    return false
End Function
