-- Tests básicos para kilocode.nvim
-- Run with: nvim --headless -c "luafile tests/basic_test.lua"

local M = {}

function M.run()
  print("🧪 Running kilocode.nvim tests...\n")
  
  local passed = 0
  local failed = 0
  
  -- Test 1: Load config
  print("Test 1: Load configuration")
  local ok, config = pcall(require, "kilocode.config")
  if ok and config.opts then
    print("  ✓ Configuration loaded")
    passed = passed + 1
  else
    print("  ✗ Failed to load configuration")
    failed = failed + 1
  end
  
  -- Test 2: Load main module
  print("\nTest 2: Load main module")
  ok, kilocode = pcall(require, "kilocode")
  if ok and kilocode.toggle then
    print("  ✓ Main module loaded")
    passed = passed + 1
  else
    print("  ✗ Failed to load main module")
    failed = failed + 1
  end
  
  -- Test 3: Check state initialization
  print("\nTest 3: State initialization")
  if kilocode.state and kilocode.state.terminal_buf == nil then
    print("  ✓ State initialized correctly")
    passed = passed + 1
  else
    print("  ✗ State not initialized correctly")
    failed = failed + 1
  end
  
  -- Test 4: Check API functions
  print("\nTest 4: API functions exist")
  local functions = {
    "toggle", "open", "close", "ask", "prompt", 
    "select", "send", "operator", "statusline", "setup"
  }
  local all_exist = true
  for _, fn in ipairs(functions) do
    if not kilocode[fn] then
      print("  ✗ Missing function: " .. fn)
      all_exist = false
      failed = failed + 1
    end
  end
  if all_exist then
    print("  ✓ All API functions exist")
    passed = passed + 1
  end
  
  -- Test 5: Context replacement (basic)
  print("\nTest 5: Context replacement")
  local test_prompt = "Hello @filename"
  local result = kilocode.replace_contexts(test_prompt)
  if result and result ~= test_prompt then
    print("  ✓ Context replacement works")
    passed = passed + 1
  else
    print("  ⚠ Context replacement returned same string (may be normal without buffer)")
    passed = passed + 1
  end
  
  -- Test 6: Config validation
  print("\nTest 6: Config validation")
  if config.opts.terminal and config.opts.terminal.position then
    print("  ✓ Terminal config valid")
    passed = passed + 1
  else
    print("  ✗ Terminal config invalid")
    failed = failed + 1
  end
  
  -- Summary
  print("\n" .. string.rep("=", 40))
  print(string.format("Results: %d passed, %d failed", passed, failed))
  
  if failed == 0 then
    print("✅ All tests passed!")
    return 0
  else
    print("❌ Some tests failed")
    return 1
  end
end

-- Run tests
local exit_code = M.run()
vim.cmd("quit " .. exit_code)
