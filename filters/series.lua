-- Adds a "Part N of <series>" box to the top of any post with `series:` metadata.
-- It scans the sibling post folders for posts in the same series, so the box
-- updates by itself when you add a new part (on the next full `quarto render`).
--
-- In a post:
--   series: "Data modelling"
--   series-part: 2
-- The series page is expected at series/<slug>.qmd, e.g. series/data-modelling.qmd.

local stringify = pandoc.utils.stringify

local function meta_str(meta, key)
  if meta[key] == nil then return nil end
  return stringify(meta[key])
end

local function slugify(s)
  return (s:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", ""))
end

local function escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function read_front_matter(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local text = fh:read("a")
  fh:close()
  local yaml = text:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-")
  if not yaml then return nil end
  return pandoc.read("---\n" .. yaml .. "\n---\n", "markdown").meta
end

function Pandoc(doc)
  if not quarto.doc.is_format("html") then return nil end
  local series = meta_str(doc.meta, "series")
  if not series then return nil end

  local this_dir = pandoc.path.directory(quarto.doc.input_file)
  local this_name = pandoc.path.filename(this_dir)
  local posts_root = pandoc.path.directory(this_dir)

  -- Collect every non-draft post in the same series
  local parts = {}
  for _, name in ipairs(pandoc.system.list_directory(posts_root)) do
    local meta = read_front_matter(pandoc.path.join({ posts_root, name, "index.qmd" }))
    if meta and meta_str(meta, "series") == series and meta_str(meta, "draft") ~= "true" then
      table.insert(parts, {
        name = name,
        title = meta_str(meta, "title") or name,
        part = tonumber(meta_str(meta, "series-part") or "") or 999,
      })
    end
  end
  table.sort(parts, function(a, b) return a.part < b.part end)

  -- Build the box
  local current = 0
  local items = {}
  for i, p in ipairs(parts) do
    if p.name == this_name then
      current = i
      table.insert(items, string.format('<li class="current"><span>%s</span></li>', escape(p.title)))
    else
      table.insert(items, string.format('<li><a href="../%s/">%s</a></li>', p.name, escape(p.title)))
    end
  end

  local html = string.format([[
<div class="series-box">
  <div class="series-label">Part %d of %d · <a href="../../series/%s.html">%s</a></div>
  <ol class="series-list">
%s
  </ol>
</div>]], current, #parts, slugify(series), escape(series), table.concat(items, "\n"))

  table.insert(doc.blocks, 1, pandoc.RawBlock("html", html))
  return doc
end
