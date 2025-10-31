-- ╭─────────────────────────╮
-- │  Homelab Noevim Config  │
-- ╰─────────────────────────╯

local ansible_files = {
  "bootstrap.yml",
  "devboards.yml",
  "server.yml",
}

local patterns = {}
for _, file in ipairs(ansible_files) do
  patterns[file] = "yaml.ansible"
end

vim.filetype.add({ pattern = patterns })
