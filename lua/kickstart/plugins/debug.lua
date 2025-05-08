-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)
return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',
    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,
      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},
      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }
    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })
    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
    -- Install golang specific config
    require('dap-go').setup()

    -- ADD CUSTOM CONFIGURATION FOR TOWNCENTRE BELOW THIS LINE

    -- Add custom configuration for TownCentre
    if not dap.configurations.go then
      dap.configurations.go = {}
    end
    table.insert(dap.configurations.go, {
      type = 'go',
      name = 'Debug TownCentre',
      request = 'launch',
      program = '${workspaceFolder}/cmd/web',
      -- Auto-read environment variables from .env file if present
      envFile = '${workspaceFolder}/.env',
      env = {
        -- Add default environment variables here
        DB_HOST = 'localhost',
        DB_PORT = '3306',
      },
      args = {},
    })

    -- Add a command to verify Delve installation
    vim.api.nvim_create_user_command('CheckDebugger', function()
      local handle = io.popen "which dlv 2>/dev/null || echo 'not found'"
      local result = handle:read '*a'
      handle:close()

      if result:match 'not found' then
        print 'Delve debugger (dlv) not found in PATH.'
        print 'Install it with: go install github.com/go-delve/delve/cmd/dlv@latest'
      else
        print('Delve debugger found at: ' .. result)
        -- Also check dap-go installation
        local status, dapgo = pcall(require, 'dap-go')
        if not status then
          print 'dap-go module not properly loaded. Check your configuration.'
        else
          print 'dap-go module loaded successfully.'
        end
      end
    end, {})

    -- Enhanced command for debugging TownCentre with better feedback
    vim.api.nvim_create_user_command('DebugTownCentre', function()
      -- Check if configurations exist
      if not dap.configurations.go then
        print 'No Go configurations found. Make sure dap-go is properly set up.'
        return
      end

      -- Verbose feedback
      print 'Looking for TownCentre configuration...'
      local found = false

      -- Find TownCentre configuration and start it
      for i, config in ipairs(dap.configurations.go) do
        if config.name == 'Debug TownCentre' then
          print('Found TownCentre configuration at position ' .. i)
          print 'Starting debug session...'
          found = true
          dap.run(config)
          return
        end
      end

      -- Handle configuration not found
      if not found then
        print 'TownCentre configuration not found. Creating one...'
        local config = {
          type = 'go',
          name = 'Debug TownCentre',
          request = 'launch',
          program = '${workspaceFolder}/cmd/web',
          envFile = '${workspaceFolder}/.env',
        }

        -- Add the configuration
        if not dap.configurations.go then
          dap.configurations.go = {}
        end
        table.insert(dap.configurations.go, config)

        -- Run with the new configuration
        print 'Starting debug session with new configuration...'
        dap.run(config)
      end
    end, {})

    -- Add convenient key mappings for TownCentre debugging
    vim.keymap.set('n', '<leader>dt', ':DebugTownCentre<CR>', { desc = 'Debug: TownCentre' })

    -- Add a direct keybinding that bypasses the command
    vim.keymap.set('n', '<leader>dt', function()
      -- Define the configuration inline to avoid any lookup issues
      local config = {
        type = 'go',
        name = 'Debug TownCentre Direct',
        request = 'launch',
        program = '${workspaceFolder}/cmd/web',
        envFile = '${workspaceFolder}/.env',
      }

      print 'Starting TownCentre debug session directly...'
      dap.run(config)
    end, { desc = 'Debug: Start TownCentre (Direct)' })

    -- Quick toggle for HTTP handler logging in Go files
    vim.api.nvim_create_user_command('AddHandlerLogging', function()
      local line = vim.fn.line '.'
      local text = 'log.Printf("HTTP %s %s: Handler called", r.Method, r.URL.Path)'
      vim.api.nvim_buf_set_lines(0, line, line, false, { text })
    end, {})
    vim.keymap.set('n', '<leader>hl', ':AddHandlerLogging<CR>', { desc = 'Add Handler Logging' })

    -- Database query debugging helper
    vim.api.nvim_create_user_command('AddQueryLogging', function()
      local line = vim.fn.line '.'
      local text = 'log.Printf("SQL Query: %s", "Your query here")'
      vim.api.nvim_buf_set_lines(0, line, line, false, { text })
    end, {})
    vim.keymap.set('n', '<leader>ql', ':AddQueryLogging<CR>', { desc = 'Add Query Logging' })

    -- HTMX event debugging helper for frontend work
    vim.api.nvim_create_user_command('AddHtmxDebug', function()
      local line = vim.fn.line '.'
      local text = 'hx-on:before-request="console.log(\'HTMX Request:\', event.detail)"'
      vim.api.nvim_buf_set_lines(0, line, line, false, { text })
    end, {})
    vim.keymap.set('n', '<leader>hx', ':AddHtmxDebug<CR>', { desc = 'Add HTMX Debug Attribute' })

    -- Add a debug checklist command
    vim.api.nvim_create_user_command('DebugChecklist', function()
      local checklist = {
        '# TownCentre Debugging Checklist',
        '',
        '## Backend',
        '- [ ] Set breakpoint at handler entry point (`<leader>b`)',
        '- [ ] Check middleware execution flow',
        '- [ ] Verify database query execution',
        '- [ ] Test error handling paths',
        '',
        '## Frontend',
        '- [ ] Verify HTMX swap behavior',
        '- [ ] Check browser console for errors',
        '- [ ] Test form submission flow',
        '',
        '## Key Commands',
        '- `<F5>` - Start/continue debugging',
        '- `<F1>` - Step into',
        '- `<F2>` - Step over',
        '- `<F3>` - Step out',
        '- `<F7>` - Toggle debug UI',
        '- `<leader>dt` - Debug TownCentre',
        '- `<leader>dd` - Debug TownCentre (Direct)',
        '- `<leader>b` - Toggle breakpoint',
        '- `<leader>B` - Set conditional breakpoint',
      }

      -- Create a new buffer for the checklist
      vim.cmd 'vsplit'
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, checklist)
      vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), buf)
      vim.cmd 'setlocal filetype=markdown'
      vim.cmd 'setlocal nomodified'
      vim.cmd 'setlocal buftype=nofile'
    end, {})
    vim.keymap.set('n', '<leader>dc', ':DebugChecklist<CR>', { desc = 'Debug: Show Checklist' })
  end,
}
