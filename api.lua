local S, modname = ...

bookz.contexts = {}

bookz.max_pages = 65

local function string_is_empty(str)
	return str == nil or str == ''
end

--Boolean Check
local function bool_check(value)
	if value == "true" then
		return true
	else
		return false
	end
end

local book = {
	title = "",
	author = "",
	creator = "",
	pages = {""},
	signed = "false",
	user_name = "",
	writable = "true",
	fields = nil,

	calc_ripped_sheets  = function(self, fields)
		local pag_1, pag_2
		if fields.rip_sheet_verso then
			local verso = self:get_verso()
			pag_1 = verso - 1
			pag_2 = verso
		else
			local recto = self:get_recto()
			pag_1 = recto
			pag_2 = recto + 1
		end
		return pag_1, pag_2
	end,

	clear_page = function(self, page_idx)
		if not page_idx then
			return
		end
		self.pages[page_idx] = ""
	end,

	confirm = function(self, msg1, msg2, fields)
		local btn_yes, btn_no
		if fields.sign then
			btn_yes = "yes_sign"
			btn_no = "no_sign"
		elseif fields.rip_sheet_verso or fields.rip_sheet_recto then
			btn_yes = "yes_rip_sheet"
			btn_no = "no_rip_sheet"
		end
		local render = {
			"size[4.5,2]",
			"bgcolor[#fce6d2]",
			"label[0,0;"..S(msg1).."]",
			"label[0,0.35;"..S(msg2).."]",
			"button_exit[1,1.25;1,1;"..btn_no..";"..S("No").."]",
			"button_exit[2.5,1.25;1,1;"..btn_yes..";"..S("Yes").."]"
		}
		self.fields = fields
		minetest.show_formspec(self.user_name, modname..":confirm", table.concat(render, ""))
	end,

	confirm_rip_sheet = function(self, fields)
		local pag_1, pag_2 = self:calc_ripped_sheets(fields)
		self:confirm("Do you want to delete the sheet, pages".." "..tostring(pag_1).."-"..tostring(pag_2).."?",
			"It will be definitive!", fields)
	end,

	confirm_sign = function(self, fields)
		self:confirm("Do you want to sign this book?", "You will not be able to edit it again!", fields)
	end,

	create = function(self, player, _title, _author, content)

		if not player then
			return false
		end

		local player_name = player:get_player_name()

		local new_book = self:new()
		new_book.page = 0
		new_book.pages = content or {"", ""}
		new_book.writable = "true"

		new_book.user_name = player_name

		local book_itemstack = ItemStack(modname..":book")
		if not _title or string_is_empty(_title) then
			_title = S("No title")
		end
		if not _author or string_is_empty(_author) then
			_author = player_name
		end
		new_book.title = _title
		new_book.author = _author
		new_book.creator = player_name
		local meta = book_itemstack:get_meta()
		meta:set_string("description", _title .. "\n" .. _author)
		meta:set_string(modname..":book", minetest.serialize(new_book))
		if player:set_wielded_item(book_itemstack) then
			return new_book
		else
			return false
		end
	end,

	rip_sheet = function(self, fields)
		local pag_1, pag_2 = self:calc_ripped_sheets(fields)
		table.remove (self.pages, pag_2)
		table.remove (self.pages, pag_1)
		self.page = pag_1 - 1
	end,

	get_author = function(self)
		return self.author
	end,

	get_page = function(self, page_idx)
		return self.pages[(page_idx or 1)]
	end,

	get_verso = function(self, spread)
		if not spread then
			spread = self:get_spread()
		end
		local verso = (spread * 2) - 2
		return verso
	end,

	get_recto = function(self, spread)
		if not spread then
			spread = self:get_spread()
		end
		local recto = (spread * 2) - 1
		return recto
	end,

	get_spread = function(self)
		local spread = math.floor((self.page/2) + 1)
		return spread
	end,

	get_last_spread = function(self)
		local spread = math.floor((#self.pages/2) + 1)
		return spread
	end,

	get_title = function(self)
		return self.title
	end,

	insert_sheet = function(self, page_idx)
		table.insert(self.pages, page_idx, "")
		table.insert(self.pages, page_idx, "")
		return ""
	end,

	is_cover = function(self)
		if self.page == 0 then
			return true
		else
			return false
		end
	end,

	make_formspec = function(self, focus)

		local is_creator, signed, writable
		if self.user_name == self.creator then
			is_creator = true
		end
		if bool_check(self.writable) then
			writable = true
		end
		if bool_check(self.signed) then
			signed = true
		end
		local page_count = self:page_count()

		local page = self.page
		local spread = self:get_spread()
		local last_spread = self:get_last_spread()

		local cover, backcover
		if self:is_cover() then
			cover = true
		end
		if page == -1 then
			backcover = true
		end

		local background, size, save_pos, insert_sheet_recto_pos, next_spread_pos, last_spread_pos, rip_sheet_recto_pos
		if cover then
			background = "bookz_cover.png"
			size = {w=8, h=10}
			save_pos = {x=2.25, y=8.5}
			insert_sheet_recto_pos = {x=4, y=8.5}
			last_spread_pos = {x=5.25, y=8.5}
			next_spread_pos = {x=6.5, y=8.5}
		else
			background = "bookz_spread.png"
			size = {w=16, h=10}
			save_pos = {x=5.75, y=8.75}
			rip_sheet_recto_pos = {x=10.5, y=8.75}
			insert_sheet_recto_pos = {x=11.75, y=8.75}
			next_spread_pos = {x=14.25, y=8.75}
			last_spread_pos = {x=13, y=8.75}
		end

		local render = {
			"formspec_version[5]",
			"size["..size.w..","..size.h.."]",
			"no_prepend[]",
			"style_type[button;bgcolor=#523928]",
			"background[0,0;"..size.w..","..size.h..";"..background.."]",
			--"bgcolor[#fce6d2;neither]",
			"style_type[textarea,checkbox;bgcolor=#fce6d2;textcolor=black]",
			"style_type[label;color=#e5cbb1;textcolor=black]"
		}

		if focus then
			table.insert(render, "set_focus["..focus.."; true]")
		end

		if cover then --first page
			local name_title = ""
			local name_author = ""
			if is_creator and not signed then
				table.insert(render, "checkbox[3.25,7;writable;"..S("Writable")..";"..tostring(self.writable).."]")
				if writable then
					name_title = "title"
					name_author = "author"
				end
			end
			table.insert(render, "textarea[2,2;4,1;"..name_title..";;"..self.title.."]")
			table.insert(render, "textarea[2,4;4,1;"..name_author..";;"..self.author.."]")
			table.insert(render, "label[3.25,7.5;"..tostring(page_count).." "..S("pages").."]")
		end

		local name_recto_page = ""
		local name_verso_page = ""

		if is_creator and writable and not signed then
			name_recto_page = "recto_page"
			name_verso_page = "verso_page"
			if not cover and spread > 1 then
				table.insert(render, "button[3.25,8.75;1,1;insert_sheet_verso;+]")
				table.insert(render, "button[4.5,8.75;1,1;rip_sheet_verso;-]")
			end
			table.insert(render, "button["..insert_sheet_recto_pos.x..","..insert_sheet_recto_pos.y..
				";1,1;insert_sheet_recto;+]")
			if spread < last_spread and not cover then
				table.insert(render, "button["..rip_sheet_recto_pos.x..","..rip_sheet_recto_pos.y..
				";1,1;rip_sheet_recto;-]")
			end
			table.insert(render,"button["..save_pos.x..","..save_pos.y..";1.5,1;save;"..S("Save").."]")
			table.insert(render,"button[8.75,8.75;1.5,1;sign;"..S("Sign").."]")
		end

		if spread > 1 then
			local verso_idx = self:get_verso()
			local verso_page = self.pages[verso_idx]
			table.insert(render, "textarea[0.75,0.5;6.5,7.5;"..name_verso_page..";;"..verso_page.."]")
			table.insert(render, "label[4,8.5;"..tostring(verso_idx).."]") --recto page
		end

		if spread < last_spread then
			local recto_idx = self:get_recto()
			local recto_page = self.pages[recto_idx]
			if recto_page then
				table.insert(render, "textarea[8.75,0.5;6.5,7.5;"..name_recto_page..";;"..recto_page.."]")
				table.insert(render, "label[12,8.5;"..tostring(recto_idx).."]")
			end
		end

		if not cover then
			table.insert(render, "button[0.75,8.75;1,1;previous_spread;<]")
			if spread > 1 then
				table.insert(render, "button[2,8.75;1,1;first_spread;<<]")
			end
		end
		if spread < last_spread then
			table.insert(render, "button["..next_spread_pos.x..","..next_spread_pos.y..";1,1;next_spread;>]")
			table.insert(render, "button["..last_spread_pos.x..","..last_spread_pos.y..";1,1;last_spread;>>]")
		end
		return table.concat(render, "")
	end,

	on_player_receive_fields = function(self, formname, fields)
		if (formname ~= modname..":book") and (formname ~= modname..":confirm") then
			return
		end
		if formname == modname..":confirm" then
			if fields.yes_sign then
				self:sign(self.fields)
			elseif fields.yes_rip_sheet then
				self:rip_sheet(self.fields)
			end
			self:show()
			return
		end
		if fields.quit then
			return
		end
		local focus
		if fields.title then
			self.title = fields.title
		end
		if fields.author then
			self.author = fields.author
		end
		if fields.previous_spread then
			self:previous_spread()
			self:save()
	    elseif fields.next_spread then
			self:next_spread()
			self:save()
		elseif fields.first_spread then
			self.page = 1
			self:save()
			self:play_sound("page_turn")
		elseif fields.last_spread then
			self.page = #self.pages
			self:save()
			self:play_sound("page_turn")
		elseif fields.save then
			self:save_spread(fields)
		elseif fields.sign then
			self:confirm_sign(fields)
			return
	    elseif fields.insert_sheet_verso or fields.insert_sheet_recto then
			local new_page_idx
			self:save_spread(fields) --do this before change the page pos
			if fields.insert_sheet_recto then
				new_page_idx = self:get_recto()
				focus = "verso_page"
			else
				new_page_idx = self:get_verso()
				focus = "recto_page"
			end
			self:insert_sheet(new_page_idx)
		elseif fields.rip_sheet_recto or fields.rip_sheet_verso then
			self:confirm_rip_sheet(fields)
			return
		elseif fields.writable then
			self.writable = fields.writable
			self:save_spread(fields)
		end
		self:show(focus)
    end,

    new = function(self)
		local new_book = {}
		setmetatable(new_book, self)
		self.__index = self
		return new_book
	end,

	page_exists = function(self, idx)
		if self.pages[idx] then
			return true
		else
			return false
		end
	end,

	page_count = function(self)
		return #self.pages
	end,

	read = function(self, itemstack, player)
		local meta_book = minetest.deserialize(itemstack:get_meta():get_string(modname..":book"))
		local read_book = self:new()
		read_book.title = meta_book.title
		read_book.author = meta_book.author
		read_book.creator = meta_book.creator
		read_book.page = meta_book.page
		read_book.pages = meta_book.pages
		read_book.signed = meta_book.signed
		read_book.user_name = player:get_player_name()
		read_book.writable = meta_book.writable
		return read_book
	end,

	save = function(self)
		self.fields = nil --do not save
		local book_itemstack = ItemStack(modname..":book")
		local meta = book_itemstack:get_meta()
		meta:set_string("description", self.title .. "\n" .. self.author)
		meta:set_string(modname..":book", minetest.serialize(self))
		local player = minetest.get_player_by_name(self.user_name)
		if player and player:set_wielded_item(book_itemstack) then
			return book_itemstack
		else
			return false
		end
	end,

	save_spread = function(self, fields)
		--Firstly save the spread pages->
		if self.page > 1 then
			self:save_page(self:get_verso(), fields.verso_page)
		end
		if self.page < self:page_count() then
			self:save_page(self:get_recto(), fields.recto_page)
		end
		self:save()
	end,

	sign = function(self, fields)
		self.signed = "true"
		self:save_spread(fields)
	end,

	save_page = function(self, page_idx, text)
		self.pages[page_idx] = text or ""
	end,

	set_author = function(self, author)
		self.author = author or ""
	end,

	set_title = function(self, title)
		self.title = title or ""
	end,

	play_sound = function(self, _type)
		local soundfile
		if _type == "page_turn" then
			soundfile = "bookz_page_turn"
		elseif _type == "book_close" then
			soundfile = "bookz_book_close"
		end
		if soundfile then
			minetest.sound_play(soundfile, {to_player = self.user_name, gain = 0.5})
		end
	end,

	previous_spread = function(self)
		if self.page == 1 then
			self.page = 0
			self:play_sound("book_close")
		else
			local spread = self:get_spread()
			spread = spread - 1
			if spread == 1 then
				self.page = 1
			else
				self.page = self:get_verso(spread)
			end
			self:play_sound("page_turn")
		end
	end,

	next_spread = function(self)
		if self:is_cover() then
			self.page = 1
		else
			local spread = self:get_spread()
			spread = spread + 1
			self.page = self:get_verso(spread)
		end
		self:play_sound("page_turn")
	end,

	show = function(self, focus)
		minetest.show_formspec(self.user_name, modname..":book", self:make_formspec(focus))
	end
}

local function get_context(player)
	return bookz.contexts[player:get_player_name()]
end

local function create_context(player, _book)
	bookz.contexts[player:get_player_name()] = _book
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= modname..":book" and formname ~= modname..":confirm" then
        return
    end
	local _book = get_context(player)
	_book:on_player_receive_fields(formname, fields)
end)

minetest.register_on_leaveplayer(function(player)
	bookz.contexts[player:get_player_name()] = nil
end)

minetest.register_craftitem(modname..":book", {
	description = S("Book"),
	inventory_image = modname.."_book.png",
	groups = {book = 1, writing = 1},
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local mybook
		if string_is_empty(meta:get_string(modname..":book")) then
			mybook = book:create(user)
		else
			mybook = book:read(itemstack, user)
		end
		create_context(user, mybook)
		mybook:show()
	end
})

minetest.register_craft({
	output = modname..":book",
	type = "shaped",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "default:paper", "default:paper"}
	}
})
