# Record the 20-second product example.
# Maintainer-only (this file does not ship). From repo root:
#   vhs docs/guides/example.tape
#
# Regenerates tmp/example.gif + tmp/example.mp4. Upload with:
#   gh release upload demo-assets tmp/example.gif --clobber -R jnun/sprintbias

Output tmp/example.gif
Output tmp/example.mp4

Require python3

Set Shell "bash"
Set FontFamily "Menlo"
Set FontSize 15
Set Width 1100
Set Height 800
Set Padding 22
Set WindowBar Colorful
Set WindowBarSize 36
Set BorderRadius 8
Set Margin 14
Set MarginFill "#050505"
Set Framerate 12
Set PlaybackSpeed 1.0
Set Theme {"name":"SprintBias","black":"#0c0c0c","red":"#ff6b6b","green":"#2ecf6a","yellow":"#ffd633","blue":"#3a9bff","magenta":"#c79bff","cyan":"#2ec8c8","white":"#f5f5f5","brightBlack":"#8a8a8a","brightRed":"#ff6b6b","brightGreen":"#2ecf6a","brightYellow":"#ffd633","brightBlue":"#3a9bff","brightMagenta":"#c79bff","brightCyan":"#2ec8c8","brightWhite":"#ffffff","background":"#0c0c0c","foreground":"#f5f5f5","cursorColor":"#ffb000","selectionBackground":"#2a2a2a"}

Hide
Type@0ms "export COLUMNS=80 LINES=32"
Enter
Type@0ms "clear"
Enter
Type@0ms "python3 docs/sprintbias/learning/example.py"
Enter
Show
Sleep 21s
