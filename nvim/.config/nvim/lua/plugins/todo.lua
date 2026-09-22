vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "faseel_todo.md",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()

		vim.cmd([[syntax match Comment "(Created: \d\d\d\d-\d\d-\d\d)"]])

		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local current_date = os.date("%Y-%m-%d")

		local new_lines = {}
		local unchecked_tasks = {}
		local found_today = false

		local i = 1
		while i <= #lines do
			local line = lines[i]
			local date_match = string.match(line, "^# (%d%d%d%d%-%d%d%-%d%d)")

			if date_match then
				if date_match == current_date then
					found_today = true
				end

				local section_header = line
				local section_body = {}
				local has_content = false

				i = i + 1
				while i <= #lines do
					local next_line = lines[i]

					if string.match(next_line, "^# %d%d%d%d%-%d%d%-%d%d") then
						break
					end

					-- Check if this line starts a task block (checked or unchecked)
					local is_task_start = string.match(next_line, "^%s*%- %[.%]")

					if is_task_start and date_match ~= current_date then
						-- Gather this entire task block (parent + all indented children/notes)
						local block = { next_line }
						local block_has_unchecked = string.match(next_line, "%- %[ %]") ~= nil

						i = i + 1
						while i <= #lines do
							local child_line = lines[i]
							local is_indented = string.match(child_line, "^%s+")
							local is_blank = not string.match(child_line, "%S")
							local is_next_task = string.match(child_line, "^%s*%- %[.%]")

							if string.match(child_line, "^# %d%d%d%d%-%d%d%-%d%d") or is_next_task then
								i = i - 1 -- step back so outer loop catches it
								break
							end

							if is_indented or is_blank then
								table.insert(block, child_line)
								if string.match(child_line, "%- %[ %]") then
									block_has_unchecked = true
								end
							else
								i = i - 1
								break
							end
							i = i + 1
						end

						-- If the block contains any unchecked item, it rolls over
						if block_has_unchecked then
							-- Ensure parent is unchecked (- [ ]) if it was marked checked
							block[1] = string.gsub(block[1], "%- %[x%]", "- [ ]")

							-- Append creation tag to parent if missing
							local task_content = string.match(block[1], "^%s*%- %[ %] (.*)")
							if task_content and not string.match(task_content, "%(Created: %d%d%d%d%-%d%d%-%d%d%)") then
								-- Strips any trailing spaces/tabs, then appends the date cleanly
								block[1] = string.gsub(block[1], "%s*$", "") .. " (Created: " .. date_match .. ")"
							end

							for _, bline in ipairs(block) do
								table.insert(unchecked_tasks, bline)
							end
						else
							-- Fully checked block stays in the old section
							for _, bline in ipairs(block) do
								table.insert(section_body, bline)
								if string.match(bline, "%S") then
									has_content = true
								end
							end
						end
					else
						table.insert(section_body, next_line)
						if string.match(next_line, "%S") then
							has_content = true
						end
					end

					i = i + 1
				end

				if has_content or date_match == current_date then
					table.insert(new_lines, section_header)
					for _, body_line in ipairs(section_body) do
						table.insert(new_lines, body_line)
					end
				end
			else
				table.insert(new_lines, line)
				i = i + 1
			end
		end

		if found_today then
			return
		end

		while #new_lines > 0 and new_lines[#new_lines] == "" do
			table.remove(new_lines)
		end

		if #new_lines > 0 then
			table.insert(new_lines, "")
		end

		table.insert(new_lines, "# " .. current_date)
		for _, task in ipairs(unchecked_tasks) do
			table.insert(new_lines, task)
		end

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
		vim.api.nvim_win_set_cursor(0, { #new_lines, 0 })

		vim.cmd("silent! write")
	end,
})
