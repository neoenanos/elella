function convert_softbreaks_inlines(inlines)
  local newcontent = {}

  for _, inline in ipairs(inlines) do
    if inline.t == "SoftBreak" then
      table.insert(newcontent, pandoc.LineBreak())
    else
      table.insert(newcontent, inline)
    end
  end

  return newcontent
end


function convert_softbreaks_block(block)

  -- Paragraphs / plain blocks
  if block.t == "Para" or block.t == "Plain" then
    block.content = convert_softbreaks_inlines(block.content)

  -- Recurse into blockquotes
  elseif block.t == "BlockQuote" then
    local newblocks = {}

    for _, b in ipairs(block.content) do
      table.insert(newblocks, convert_softbreaks_block(b))
    end

    block.content = newblocks

  -- Recurse into Divs
  elseif block.t == "Div" then
    local newblocks = {}

    for _, b in ipairs(block.content) do
      table.insert(newblocks, convert_softbreaks_block(b))
    end

    block.content = newblocks
  end

  return block
end


function Pandoc(doc)
  local newblocks = {}
  local i = 1
  local blocks = doc.blocks

  while i <= #blocks do
    local el = blocks[i]

    -- Verse header
    if el.t == "Header" and el.classes:includes("verse") then

      -- Remove the class so it doesn't affect other formats
      local newclasses = {}

      for _, c in ipairs(el.classes) do
        if c ~= "verse" then
          table.insert(newclasses, c)
        end
      end

      el.classes = newclasses

      -- Output header
      table.insert(newblocks, el)

      -- Open verse
      table.insert(newblocks,
        pandoc.RawBlock("latex", "\\begin{verse}"))

      i = i + 1

      -- Collect blocks until next header
      while i <= #blocks and blocks[i].t ~= "Header" do
        local nextel = blocks[i]

        nextel = convert_softbreaks_block(nextel)

        table.insert(newblocks, nextel)

        i = i + 1
      end

      -- Close verse
      table.insert(newblocks,
        pandoc.RawBlock("latex", "\\end{verse}"))

    else
      table.insert(newblocks, el)
      i = i + 1
    end
  end

  return pandoc.Pandoc(newblocks, doc.meta)
end


function Div(el)
  if el.classes:includes("verse") then
    local blocks = {}

    table.insert(blocks,
      pandoc.RawBlock("latex", "\\begin{verse}"))

    for _, block in ipairs(el.content) do
      block = convert_softbreaks_block(block)
      table.insert(blocks, block)
    end

    table.insert(blocks,
      pandoc.RawBlock("latex", "\\end{verse}"))

    return blocks
  end
end


function Span(el)
  if el.classes:includes("inline-indent") then
    return {
      pandoc.RawInline("latex", "\\hspace{2em}"),
      el
    }
  end
end