local M = {}

local function find_venv(start_dir)
  local dir = start_dir

  while dir ~= "/" do
    local venv_python = dir .. "/.venv/bin/python"

    if vim.fn.executable(venv_python) == 1 then
      return venv_python
    end

    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return nil
end

local function run_python(file)
  local dir = vim.fn.fnamemodify(file, ":h")
  local python = find_venv(dir)

  if not python then
    vim.notify("No .venv found", vim.log.levels.ERROR)
    return
  end

  vim.cmd("botright split | terminal " .. vim.fn.shellescape(python) .. " " .. vim.fn.shellescape(file))
end

function M.run_current()
  local file = vim.fn.expand("%:p")

  if file == "" then
    vim.notify("No file to run", vim.log.levels.WARN)
    return
  end

  if vim.bo.filetype ~= "python" then
    vim.notify("Current file is not Python", vim.log.levels.WARN)
    return
  end

  run_python(file)
end

function M.run_main()
  local current = vim.fn.expand("%:p")
  local dir = vim.fn.fnamemodify(current, ":h")

  while dir ~= "/" do
    local main = dir .. "/main.py"

    if vim.fn.filereadable(main) == 1 then
      run_python(main)
      return
    end

    dir = vim.fn.fnamemodify(dir, ":h")
  end

  vim.notify("Could not find main.py", vim.log.levels.ERROR)
end

return M
