vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "faseel_todo.md",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()

		-- 1. Setup Tag Coloring
		local palette = {
			"#8be9fd",
			"#50fa7b",
			"#f1fa8c",
			"#ffb86c",
			"#ff5555",
			"#ff79c6",
			"#bd93f9",
			"#8ae234",
			"#729fcf",
			"#ad7fa8",
		}

		local syntax_cmds = {
			[[syntax match Comment "(Created: \d\d\d\d-\d\d-\d\d)"]],
			[[syntax match TodoTag "@[a-zA-Z_]\w*"]],
			[[highlight default TodoTag guibg=#bd93f9 guifg=#282a36 ctermbg=Magenta ctermfg=Black]],
		}

		for i = 0, 50 do
			local color = palette[(i % #palette) + 1]
			local group_name = "TodoTagNum" .. i
			table.insert(syntax_cmds, string.format([[syntax match %s "@%d-[a-zA-Z0-9_-]\+"]], group_name, i))
			table.insert(
				syntax_cmds,
				string.format(
					[[highlight default %s guibg=%s guifg=#282a36 ctermbg=White ctermfg=Black]],
					group_name,
					color
				)
			)
		end

		vim.cmd(table.concat(syntax_cmds, "\n"))

		-- 2. Run Auto-Rollover and Formatting
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local current_date = os.date("%Y-%m-%d")

		-- STEP A: Parse the entire document safely into Days
		local parsed_days = {}
		local current_day = nil
		local preamble = {}

		for _, line in ipairs(lines) do
			-- Ignore existing standalone month headers so we can cleanly regenerate them dynamically
			if string.match(line, "^# %d%d%d%d%-%d%d$") then
				-- skip
			else
				-- STRICTLY match H2 dates now that migration is complete
				local date_match = string.match(line, "^## (%d%d%d%d%-%d%d%-%d%d)")
				if date_match then
					current_day = { date = date_match, lines = {} }
					table.insert(parsed_days, current_day)
				else
					if current_day then
						table.insert(current_day.lines, line)
					else
						table.insert(preamble, line)
					end
				end
			end
		end

		-- STEP B: Process Task Blocks and Rollover
		local unchecked_tasks = {}
		local final_days = {}

		for _, day in ipairs(parsed_days) do
			local is_today = (day.date == current_date)
			local processed_lines = {}
			local current_task_block = nil

			-- Group day's lines into blocks (Task vs Normal Text)
			for _, line in ipairs(day.lines) do
				local is_top_task = string.match(line, "^%- %[.%]")
				local is_indented = string.match(line, "^%s+")
				local is_blank = not string.match(line, "%S")

				if is_top_task then
					if current_task_block then
						table.insert(processed_lines, current_task_block)
					end
					current_task_block = { lines = { line }, has_unchecked = string.match(line, "^%- %[ %]") ~= nil }
				elseif current_task_block and (is_indented or is_blank) then
					table.insert(current_task_block.lines, line)
					if string.match(line, "%- %[ %]") then
						current_task_block.has_unchecked = true
					end
				else
					if current_task_block then
						table.insert(processed_lines, current_task_block)
						current_task_block = nil
					end
					table.insert(processed_lines, { lines = { line }, is_normal = true })
				end
			end

			if current_task_block then
				table.insert(processed_lines, current_task_block)
			end

			-- Evaluate blocks
			local day_content = {}
			for _, block in ipairs(processed_lines) do
				if block.is_normal or is_today then
					for _, l in ipairs(block.lines) do
						table.insert(day_content, l)
					end
				else
					if block.has_unchecked then
						-- Rollover logic
						block.lines[1] = string.gsub(block.lines[1], "^%- %[x%]", "- [ ]")
						local task_text = string.match(block.lines[1], "^%- %[ %] (.*)")
						if task_text and not string.match(task_text, "%(Created: %d%d%d%d%-%d%d%-%d%d%)") then
							block.lines[1] = string.gsub(block.lines[1], "%s*$", "") .. " (Created: " .. day.date .. ")"
						end
						for _, l in ipairs(block.lines) do
							table.insert(unchecked_tasks, l)
						end
					else
						for _, l in ipairs(block.lines) do
							table.insert(day_content, l)
						end
					end
				end
			end

			day.lines = day_content
			table.insert(final_days, day)
		end

		-- STEP C: Rebuild the document
		local new_lines = {}
		for _, line in ipairs(preamble) do
			table.insert(new_lines, line)
		end

		-- Ensure today exists in our day list
		local today_obj = nil
		for _, day in ipairs(final_days) do
			if day.date == current_date then
				today_obj = day
				break
			end
		end

		if not today_obj then
			today_obj = { date = current_date, lines = {} }
			table.insert(final_days, today_obj)
		end

		-- Prepend rolled-over tasks right under today's date
		if #unchecked_tasks > 0 then
			local updated_today_lines = {}
			for _, t in ipairs(unchecked_tasks) do
				table.insert(updated_today_lines, t)
			end
			for _, l in ipairs(today_obj.lines) do
				table.insert(updated_today_lines, l)
			end
			today_obj.lines = updated_today_lines
		end

		-- Render everything with Month Headers
		local last_seen_month = nil
		for _, day in ipairs(final_days) do
			local has_content = false
			for _, l in ipairs(day.lines) do
				if string.match(l, "%S") then
					has_content = true
					break
				end
			end

			if has_content or day.date == current_date then
				local block_month = string.sub(day.date, 1, 7)

				if block_month ~= last_seen_month then
					if #new_lines > 0 and new_lines[#new_lines] ~= "" then
						table.insert(new_lines, "")
					end
					table.insert(new_lines, "# " .. block_month)
					last_seen_month = block_month
				end

				table.insert(new_lines, "")
				table.insert(new_lines, "## " .. day.date)
				for _, l in ipairs(day.lines) do
					table.insert(new_lines, l)
				end
			end
		end

		-- Clean up redundant blank lines
		local cleaned_lines = {}
		for _, line in ipairs(new_lines) do
			if line == "" and #cleaned_lines > 0 and cleaned_lines[#cleaned_lines] == "" then
				-- skip duplicate blanks
			else
				table.insert(cleaned_lines, line)
			end
		end

		while #cleaned_lines > 0 and cleaned_lines[1] == "" do
			table.remove(cleaned_lines, 1)
		end
		while #cleaned_lines > 0 and cleaned_lines[#cleaned_lines] == "" do
			table.remove(cleaned_lines)
		end

		-- STEP D: Diff check and Save
		local changed = false
		if #lines ~= #cleaned_lines then
			changed = true
		else
			for k, v in ipairs(lines) do
				if v ~= cleaned_lines[k] then
					changed = true
					break
				end
			end
		end

		if changed then
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, cleaned_lines)
			vim.cmd("silent! write")
		end

		vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
	end,
})
