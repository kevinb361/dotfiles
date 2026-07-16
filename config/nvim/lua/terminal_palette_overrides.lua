-- =========================================
-- Blackout Moss Neovim highlights
-- Graphite cockpit surfaces, moss/phosphor text, amber warnings.
-- Terminal-first and OLED-friendly: most backgrounds stay transparent.
-- =========================================

local c = {
  bg = "#050706",
  bg2 = "#0A0D0B",
  surface = "#101510",
  surface2 = "#161D16",
  text = "#A8B995",
  muted = "#6F7F69",
  accent = "#23301F",
  accent2 = "#A3C179",
  amber = "#C79545",
  red = "#B85C57",
  blue = "#7EA089",
}

local function hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- Core editor surfaces
hl("Normal", { fg = c.text, bg = "NONE" })
hl("NormalNC", { fg = c.muted, bg = "NONE" })
hl("EndOfBuffer", { fg = c.bg2, bg = "NONE" })
hl("Comment", { fg = c.muted, italic = true })
hl("CursorLine", { bg = "NONE" })
hl("CursorLineNr", { fg = c.accent2, bold = true })
hl("LineNr", { fg = c.muted })
hl("SignColumn", { bg = "NONE" })
hl("ColorColumn", { bg = c.surface })
hl("Visual", { bg = "#23301F" })
hl("Search", { fg = c.bg, bg = c.amber, bold = true })
hl("IncSearch", { fg = c.bg, bg = c.accent2, bold = true })

-- Syntax-ish defaults
hl("String", { fg = "#A7C080" })
hl("Function", { fg = c.accent2 })
hl("Identifier", { fg = c.text })
hl("Keyword", { fg = c.blue, bold = true })
hl("Type", { fg = "#9BBF8A" })
hl("Constant", { fg = "#D3B86C" })
hl("Statement", { fg = c.blue })
hl("PreProc", { fg = c.amber })

-- UI chrome
hl("Pmenu", { fg = c.text, bg = c.surface })
hl("PmenuSel", { fg = c.bg, bg = c.accent })
hl("PmenuSbar", { bg = c.surface2 })
hl("PmenuThumb", { bg = c.accent })
hl("NormalFloat", { fg = c.text, bg = c.bg2 })
hl("FloatBorder", { fg = c.accent, bg = c.bg2 })
hl("WinSeparator", { fg = c.surface2, bg = "NONE" })
hl("StatusLine", { fg = c.text, bg = c.bg2 })
hl("StatusLineNC", { fg = c.muted, bg = c.bg2 })
hl("TabLineSel", { fg = c.bg, bg = c.accent })
hl("TabLine", { fg = c.muted, bg = c.bg2 })
hl("TabLineFill", { bg = c.bg })

-- Diagnostics / git
hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.amber })
hl("DiagnosticInfo", { fg = c.blue })
hl("DiagnosticHint", { fg = c.accent })
hl("GitSignsAdd", { fg = c.accent })
hl("GitSignsChange", { fg = c.amber })
hl("GitSignsDelete", { fg = c.red })
hl("DiffAdd", { fg = c.accent, bg = "#122016" })
hl("DiffChange", { fg = c.amber, bg = "#211B10" })
hl("DiffDelete", { fg = c.red, bg = "#211010" })

-- Telescope / WhichKey friendliness
hl("TelescopeBorder", { fg = c.accent, bg = c.bg2 })
hl("TelescopePromptBorder", { fg = c.accent2, bg = c.bg2 })
hl("TelescopeSelection", { fg = c.accent2, bg = c.surface })
hl("TelescopeMatching", { fg = c.amber, bold = true })
hl("WhichKey", { fg = c.accent2 })
hl("WhichKeyDesc", { fg = c.text })
hl("WhichKeyGroup", { fg = c.blue })
