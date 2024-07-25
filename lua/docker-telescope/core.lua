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

docker_volumes = function(opts)
  pickers
    .new(opts, {
      finder = finders.new_dynamic {
        fn = function()
          return M._make_docker_command { "volume", "ls" }
        end,

        entry_maker = function(entry)
          local volume = vim.json.decode(entry)
          log.info("Calling entry maker", volume)
          if volume then
            return {
              value = volume,
              display = volume.Name,
              ordinal = volume.Name,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      previewer = previewers.new_buffer_previewer {
        title = "Volume Details",
        define_preview = function(self, entry)
          local formatted = {
            "# " .. entry.display,
            "",
            "*Labels*: " .. entry.value.Labels,
            "*Availability*: " .. entry.value.Availability,
            "*Driver*: " .. entry.value.Driver,
            "*Group*: " .. entry.value.Group,
            "*Links*: " .. entry.value.Links,
            "*Scope*: " .. entry.value.Scope,
            "*Size*: " .. entry.value.Size,
            "*Status*: " .. entry.value.Status,
            "*Mountpoint*: " .. entry.value.Mountpoint,
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)

          utils.highlighter(self.state.bufnr, "markdown")
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end
local docker_images = function(opts)
  pickers
    .new(opts, {
      finder = finders.new_dynamic {
        fn = function()
          return M._make_docker_command { "images" }
        end,

        entry_maker = function(entry)
          local image = vim.json.decode(entry)
          log.debug("Calling entry maker", image)
          if image then
            return {
              value = image,
              display = image.Repository,
              ordinal = image.Repository,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      previewer = previewers.new_buffer_previewer {
        title = "Image Details",
        define_preview = function(self, entry)
          local formatted = {
            "# " .. entry.display,
            "",
            "*ID*: " .. entry.value.ID,
            "*Tag*: " .. entry.value.Tag,
            "*Containers*: " .. entry.value.Containers,
            "*Digest*: " .. entry.value.Digest,
            "",
            "*CreatedAt*: " .. entry.value.CreatedAt,
            "*CreatedSince*: " .. entry.value.CreatedSince,
            "",
            "*SharedSize*: " .. entry.value.SharedSize,
            "*Size*: " .. entry.value.Size,
            "*UniqueSize*: " .. entry.value.UniqueSize,
            "*VirtualSize*: " .. entry.value.VirtualSize,
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)
          utils.highlighter(self.state.bufnr, "markdown")
        end,
      },

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          log.debug("Selected", selection)
          local command = {
            "edit",
            "term://docker",
            "run",
            "-it",
            selection.value.Repository,
          }
          log.debug("Running", command)
          vim.cmd(vim.fn.join(command, " "))
        end)
        return true
      end,
    })
    :find()
end

-- to execute the function
docker_volumes()
