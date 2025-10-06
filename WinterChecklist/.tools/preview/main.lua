-- Minimal visual mock for your Checklist addon.
local tasks = {
  { text = "Turn in daily quests", done = false },
  { text = "Farm herbs", done = true },
  { text = "Check AH", done = false },
}
local input = { text = "", focused = false, cursor = 0 }
local modeIdx = 1 -- 1=Daily, 2=Weekly
local showHelp = false
local minimapShown = true
local zoneName = "Elwynn Forest"
local selectedIdx, scroll = nil, 0

local M = { pad=10, hdrH=40, rowH=28, inputH=28, btnW=28, checkbox=18 }

local function layout(w,h)
  local x,y = M.pad,M.pad
  local hdr={x=x,y=y,w=w-2*M.pad,h=M.hdrH}; y=y+M.hdrH+M.pad
  local row={x=x,y=y,w=w-2*M.pad,h=M.rowH}; y=y+M.rowH+M.pad
  local list={x=x,y=y,w=w-2*M.pad,h=h-y-(M.pad+love.graphics.getFont():getHeight()+8)}
  local footer={x=x,y=h-M.pad-(love.graphics.getFont():getHeight()+8),w=w-2*M.pad,h=love.graphics.getFont():getHeight()+8}
  return hdr,row,list,footer
end
local function tW(s) return love.graphics.getFont():getWidth(s) end
local function tH() return love.graphics.getFont():getHeight() end
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end
local function hit(mx,my,r) return mx>=r.x and mx<=r.x+r.w and my>=r.y and my<=r.y+r.h end

local function drawButton(x,y,w,h,label,hot)
  love.graphics.setColor(hot and 0.85 or 0.75,0.75,0.75)
  love.graphics.rectangle("fill",x,y,w,h,6,6)
  love.graphics.setColor(0.15,0.15,0.15)
  love.graphics.rectangle("line",x,y,w,h,6,6)
  love.graphics.print(label, x+(w-tW(label))/2, y+(h-tH())/2)
end
local function drawCheckbox(x,y,checked)
  love.graphics.setColor(1,1,1); love.graphics.rectangle("fill",x,y,M.checkbox,M.checkbox,3,3)
  love.graphics.setColor(0,0,0); love.graphics.rectangle("line",x,y,M.checkbox,M.checkbox,3,3)
  if checked then love.graphics.setLineWidth(2); love.graphics.line(x+4,y+M.checkbox/2,x+M.checkbox/2,y+M.checkbox-4,x+M.checkbox-4,y+4); love.graphics.setLineWidth(1) end
end
local function drawInput(x,y,w,h)
  love.graphics.setColor(1,1,1); love.graphics.rectangle("fill",x,y,w,h,6,6)
  love.graphics.setColor(0,0,0); love.graphics.rectangle("line",x,y,w,h,6,6)
  local tx=x+8
  if input.focused then
    love.graphics.print(input.text,tx,y+(h-tH())/2)
    local pre=input.text:sub(1,input.cursor); local cx=tx+tW(pre)
    love.graphics.line(cx,y+6,cx,y+h-6)
  else
    if input.text=="" then love.graphics.setColor(0.55,0.55,0.55); love.graphics.print("New task…",tx,y+(h-tH())/2); love.graphics.setColor(0,0,0)
    else love.graphics.print(input.text,tx,y+(h-tH())/2) end
  end
end

local function drawHelpOverlay(w,h)
  love.graphics.setColor(0,0,0,0.75); love.graphics.rectangle("fill",0,0,w,h)
  love.graphics.setColor(1,1,1)
  local lines={
    "Checklist — quick help","","• + add task (type first).",
    "• E edit selected. • − delete selected.","• Toggle Daily/Weekly.",
    "• Click checkboxes to complete.","• MM toggles minimap icon (sim).",
    "• Click zone name to 'open map'.","","Command-line examples:",
    "/checklist add \"Buy reagents\"","/checklist daily",
  }
  local x,y=32,32; for _,ln in ipairs(lines) do love.graphics.print(ln,x,y); y=y+tH()+6 end
end

function love.load() love.keyboard.setKeyRepeat(true) end
function love.draw()
  local w,h=love.graphics.getWidth(),love.graphics.getHeight()
  local hdr,row,list,footer=layout(w,h)
  love.graphics.setColor(0.92,0.94,0.96); love.graphics.rectangle("fill",0,0,w,h)
  love.graphics.setColor(0.2,0.2,0.2); love.graphics.rectangle("line",0,0,w,h,12,12)
  love.graphics.setColor(0.82,0.86,0.9); love.graphics.rectangle("fill",hdr.x,hdr.y,hdr.w,hdr.h,10,10)
  love.graphics.setColor(0.1,0.1,0.1); love.graphics.print("Checklist",hdr.x+10,hdr.y+(hdr.h-tH())/2)

  -- top row: [input][Daily/Weekly][+][E][−][MM][?]
  local x=row.x; local btnGap=6; local modeW=90; local btnW=M.btnW; local btnH=row.h; local mmW=40
  local inputW=row.w-(modeW+3*btnW+mmW+2*btnGap+2*btnGap+28)
  drawInput(x,row.y,inputW,row.h); local inputBox={x=x,y=row.y,w=inputW,h=row.h}; x=x+inputW+btnGap
  drawButton(x,row.y,modeW,row.h,(modeIdx==1 and "Daily" or "Weekly")); local mRect={x=x,y=row.y,w=modeW,h=row.h}; x=x+modeW+btnGap
  local addRect={x=x,y=row.y,w=btnW,h=btnH}; x=x+btnW+4
  local editRect={x=x,y=row.y,w=btnW,h=btnH}; x=x+btnW+4
  local delRect={x=x,y=row.y,w=btnW,h=btnH}; x=x+btnW+btnGap
  local mmRect={x=x,y=row.y,w=mmW,h=btnH}; x=x+mmW+btnGap
  local qRect={x=x,y=row.y,w=btnW,h=btnH}
  drawButton(addRect.x,addRect.y,addRect.w,addRect.h,"+")
  drawButton(editRect.x,editRect.y,editRect.w,editRect.h,"E")
  drawButton(delRect.x,delRect.y,delRect.w,delRect.h,"−")
  drawButton(mmRect.x,mmRect.y,mmRect.w,mmRect.h, minimapShown and "MM✓" or "MM")
  drawButton(qRect.x,qRect.y,qRect.w,qRect.h,"?")

  -- list
  love.graphics.setScissor(list.x,list.y,list.w,list.h)
  local oy=list.y-scroll; local lh=26
  for i,t in ipairs(tasks) do
    drawCheckbox(list.x, oy+(i-1)*lh+4, t.done)
    local tx=list.x+M.checkbox+8
    if selectedIdx==i then love.graphics.setColor(0.85,0.9,1); love.graphics.rectangle("fill",tx-4,oy+(i-1)*lh,list.w-(M.checkbox+16),lh,6,6); end
    love.graphics.setColor(0,0,0); love.graphics.printf(t.text,tx,oy+(i-1)*lh+(lh-tH())/2,list.w-(M.checkbox+16)); love.graphics.setColor(1,1,1)
  end
  love.graphics.setScissor()

  -- footer (zone)
  love.graphics.setColor(0.15,0.15,0.15); love.graphics.print(zoneName, footer.x, footer.y+2)

  if showHelp then drawHelpOverlay(w,h) end

  -- store clickable rects in upvalue for mouse handler
  love._rects={inputBox=inputBox,mRect=mRect,addRect=addRect,editRect=editRect,delRect=delRect,mmRect=mmRect,qRect=qRect,list=list,footer=footer}
end

function love.wheelmoved(_,y)
  local list=love._rects.list; local lh=26
  local maxScroll=math.max(0,#tasks*lh - list.h)
  scroll=clamp(scroll - y*lh*2,0,maxScroll)
end

function love.mousepressed(mx,my,btn)
  if btn~=1 then return end
  local r=love._rects
  if hit(mx,my,r.inputBox) then input.focused=true; input.cursor=#input.text; return else input.focused=false end
  if hit(mx,my,r.mRect) then modeIdx=3-modeIdx; return end
  if hit(mx,my,r.addRect) then local txt=input.text:gsub("^%s+",""):gsub("%s+$",""); if #txt>0 then table.insert(tasks,{text=txt,done=false}); input.text=""; input.cursor=0 end; return end
  if hit(mx,my,r.editRect) and selectedIdx then input.text=tasks[selectedIdx].text; input.cursor=#input.text; input.focused=true; return end
  if hit(mx,my,r.delRect) and selectedIdx then table.remove(tasks,selectedIdx); selectedIdx=nil; return end
  if hit(mx,my,r.mmRect) then minimapShown=not minimapShown; return end
  if hit(mx,my,r.qRect) then showHelp=not showHelp; return end
  if hit(mx,my,r.list) then local lh=26; local i=math.floor((my - r.list.y + scroll)/lh)+1; if tasks[i] then
    local cbx={x=r.list.x,y=r.list.y+(i-1)*lh - scroll + 4,w=M.checkbox,h=M.checkbox}
    if hit(mx,my,cbx) then tasks[i].done=not tasks[i].done else selectedIdx=(selectedIdx==i) and nil or i end
  end; return end
  local zn={x=r.footer.x,y=r.footer.y,w=tW(zoneName)+10,h=r.footer.h}
  if hit(mx,my,zn) then print("[preview] open map for zone:", zoneName) end
end

function love.textinput(t)
  if not input.focused then return end
  input.text=input.text:sub(1,input.cursor)..t..input.text:sub(input.cursor+1)
  input.cursor=input.cursor+#t
end
function love.keypressed(key)
  if key=="escape" then love.event.quit() end
  if not input.focused then return end
  if key=="backspace" and input.cursor>0 then
    input.text=input.text:sub(1,input.cursor-1)..input.text:sub(input.cursor+1); input.cursor=input.cursor-1
  elseif key=="left" then input.cursor=math.max(0,input.cursor-1)
  elseif key=="right" then input.cursor=math.min(#input.text,input.cursor+1)
  elseif key=="return" then local txt=input.text:gsub("^%s+",""):gsub("%s+$",""); if #txt>0 then table.insert(tasks,{text=txt,done=false}) end; input.text=""; input.cursor=0; input.focused=false end
end
