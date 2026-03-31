-- Nuke all default status bar children and add clean replacements
-- Remove defaults (left side IDs 1-10, right side IDs 1-10)
for i = 1, 10 do
  pcall(Status.children_remove, Status, i, Status.LEFT)
  pcall(Status.children_remove, Status, i, Status.RIGHT)
end

-- Left: file name
Status:children_add(function()
  local h = cx.active.current.hovered
  if not h then return ui.Line({}) end
  return ui.Line({ ui.Span(" " .. h.name):fg("#cdd6f4") })
end, 500, Status.LEFT)

-- Right: modified date + permissions + position
Status:children_add(function()
  local h = cx.active.current.hovered
  if not h then return ui.Line({}) end

  local spans = {}

  -- Modified date
  if h.cha.mtime then
    local ts = tonumber(h.cha.mtime)
    if ts and ts > 0 then
      table.insert(spans, ui.Span(os.date("%Y-%m-%d %H:%M", math.floor(ts))):fg("#a6adc8"))
      table.insert(spans, ui.Span("  "))
    end
  end

  -- Permissions
  if h.cha.perm then
    table.insert(spans, ui.Span(tostring(h.cha:perm())):fg("#7f849c"))
    table.insert(spans, ui.Span("  "))
  end

  -- Position
  local cur = cx.active.current
  table.insert(spans, ui.Span(tostring(cur.cursor + 1) .. "/" .. tostring(#cur.files)):fg("#a6adc8"))
  table.insert(spans, ui.Span(" "))

  return ui.Line(spans)
end, 500, Status.RIGHT)
