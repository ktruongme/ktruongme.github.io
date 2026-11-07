-- Adds a "TL;DR" box to the top of any post with `tldr:` metadata.
-- Runs before series.lua, so the series box stays above it.
--
-- One line:
--   tldr: "Handy is a free, offline dictation app."
-- Or bullet points:
--   tldr:
--     - "First point."
--     - "Second point."

function Pandoc(doc)
  if not quarto.doc.is_format("html") then return nil end
  local tldr = doc.meta.tldr
  if tldr == nil then return nil end

  local content
  local kind = pandoc.utils.type(tldr)
  if kind == "List" then
    local items = {}
    for _, item in ipairs(tldr) do
      table.insert(items, { pandoc.Plain(item) })
    end
    content = pandoc.Blocks({ pandoc.BulletList(items) })
  elseif kind == "Blocks" then
    content = tldr
  else
    content = pandoc.Blocks({ pandoc.Para(tldr) })
  end

  -- quarto.Callout returns more than one value; keep only the node.
  local box = quarto.Callout({ type = "tip", title = "TL;DR", content = content })
  table.insert(doc.blocks, 1, box)
  return doc
end
