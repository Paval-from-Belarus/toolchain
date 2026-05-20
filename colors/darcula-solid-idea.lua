vim.opt.background = 'dark'
vim.g.colors_name = 'darcula-solid-idea'
local lush = require('lush')
local darcula_solid = require('lush_theme.darcula-solid')
local spec = lush.extends({darcula_solid}).with(function(injected_functions)
local sym = injected_functions.sym
local keyword_color = "#E37F4E";

local colors = {
  gray = lush.hsl(220, 10, 50), 
}

  return {
    Constant { fg = lush.hsl("#c77dbb") },
    RustLifetime { fg = lush.hsl("#20999d")},
    sym("@comment.documentation") { fg = lush.hsl("#7cc22d")},
    sym("@function.call") { fg = lush.hsl("#39A6d0") },
    sym("@function.macro") { fg = lush.hsl("#35adff") },
    sym("@function") { fg = lush.hsl("#56a8f5") },
    sym("@variable.member") { fg = lush.hsl("#de66dc") },
    sym("@variable.type") { fg = lush.hsl("#de66dc") },
    sym("@type") { fg = lush.hsl("#f7ffc2") },
    sym("@variable") { fg = lush.hsl("#d9b76e") },
    -- sym("@attribute") { fg = lush.hsl("#e9d700") },
    sym("@type.builtin") { fg = lush.hsl(keyword_color) },
    Module { fg = lush.hsl("#c4c1bc") },
    String { fg = lush.hsl("#5BA130") },
    Label { fg = lush.hsl("#20999D") },
    LspInlayHint { fg = colors.gray },
  }
end)
lush(spec)
