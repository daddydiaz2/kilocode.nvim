local M = {}

function M.check()
  vim.health.start("kilocode.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim version >= 0.9.0")
  else
    vim.health.error("Neovim version must be >= 0.9.0")
  end

  -- Check for plenary
  local has_plenary, _ = pcall(require, "plenary")
  if has_plenary then
    vim.health.ok("plenary.nvim is installed")
  else
    vim.health.warn("plenary.nvim is not installed (optional but recommended)")
  end

  -- Check for KiloCode CLI
  local handle = io.popen("which kilo 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result ~= "" then
      vim.health.ok("KiloCode CLI found at: " .. result:gsub("%s+$", ""))
      
      -- Check version
      local ver_handle = io.popen("kilo --version 2>&1")
      if ver_handle then
        local ver = ver_handle:read("*a")
        ver_handle:close()
        if ver then
          vim.health.info("KiloCode version: " .. ver:gsub("%s+$", ""))
        end
      end
    else
      vim.health.error("KiloCode CLI not found. Install with: npm install -g @kilocode/cli")
    end
  end

  -- Check configuration
  local ok, config = pcall(require, "kilocode.config")
  if ok then
    vim.health.ok("Configuration loaded successfully")
  else
    vim.health.error("Failed to load configuration: " .. tostring(config))
  end

  -- Check for common issues
  vim.health.start("Common Issues")
  
  -- Check if in tmux (can affect terminal rendering)
  if os.getenv("TMUX") then
    vim.health.warn("Running inside tmux - ensure tmux is configured for Unicode support")
  end

  -- Check for compatible terminal
  local term = os.getenv("TERM")
  if term then
    vim.health.info("Terminal: " .. term)
  end
end

return M
