local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"
local plenary = require "plenary"
local utils = require "telescope.previewers.utils"
local log = require("plenary.log").new {
  plugin = "telescope_docker",
  level = "info",
}

local M = {}

M._make_docker_command = function(args)
  local job_opts = {
    command = "docker",
    args = vim.tbl_flatten { args, "--format", "json" },
  }
  log.info("Running job", job_opts)
  local job = plenary.job:new(job_opts):sync()
  log.info("Ran job", vim.inspect(job))
  return job
end

local docker_compose = function(opts)
  pickers
    .new(opts, {
      finder = finders.new_dynamic {
        fn = function()
          return M._make_docker_command { "compose", "ls" }
        end,

        entry_maker = function(entry)
          log.info("Got entry", entry)
          local process = vim.json.decode(entry)
          log.info("Got entry", process)
          if process then
            return {
              value = process,
              display = process.Name,
              ordinal = process.Name .. " " .. process.Status,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      -- previewer = previewers.new_buffer_previewer {
      --   title = "Process Details",
      --   define_preview = function(self, entry)
      --     local formatted = {
      --       "# ID: " .. entry.value.ID,
      --       "",
      --       "*Names*: " .. entry.value.Names,
      --       "*Command*: " .. entry.value.Command,
      --       "*Labels*: " .. entry.value.Labels,
      --       "",
      --       "*Image*: " .. entry.value.Image,
      --       "*LocalVolumes*: " .. entry.value.LocalVolumes,
      --       "*Mounts*: " .. entry.value.Mounts,
      --       "*Networks*: " .. entry.value.Networks,
      --       "*Ports*: " .. entry.value.Ports,
      --       "",
      --       "*Size*: " .. entry.value.Size,
      --       "",
      --       "*State*: " .. entry.value.State,
      --       "*Status*: " .. entry.value.Status,
      --       "*CreatedAt*: " .. entry.value.CreatedAt,
      --       "*RunningFor*: " .. entry.value.RunningFor,
      --     }
      --
      --     vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)
      --     utils.highlighter(self.state.bufnr, "markdown")
      --   end,
      -- },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end

-- to execute the function
docker_compose()
