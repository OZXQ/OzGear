# Agent Guidelines: WoW 1.12.1 & Lua 5.0 Addon Development

This document defines the strict engineering standards, language constraints, and architecture conventions for AI agents and developers working on the **OzUF** codebase and World of Warcraft 1.12.1 (Vanilla / Turtle WoW / SuperWoW) addons.

---

## 0. ALWAYS READ FILES BEFORE CODING
* you MUST read all files in the project before coding
* commit everytime complete a request in git.

---

## 1. Runtime Environment & Lua 5.0 Dialect

World of Warcraft 1.12.1 (client build 5875) executes a customized **Lua 5.0.2** runtime. Many features standard in Lua 5.1, 5.2, 5.3, and LuaJIT **do NOT exist** or will cause critical runtime syntax errors that halt addon execution.

### Strict Syntax Rules & Forbidden Features

| Feature                                 | Status in WoW 1.12       | Correct Alternative                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :-------------------------------------- | :----------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`FontString:GetStringHeight()`**      | ❌ **DOES NOT EXIST**     | NEVER call `fs:GetStringHeight()`. In 1.12, FontStrings only have `GetStringWidth()`. Use `fs:GetHeight()`, standard metric defaults (e.g. 14), or guarded fallback `(fs.GetStringHeight and fs:GetStringHeight()) or fs:GetHeight() or 14`.                                                                                                                                                                                                                                                                                                                                                                     |
| **`ChatEdit_InsertLink()`**             | ❌ **DOES NOT EXIST**     | Introduced in WoW 2.0. In 1.12, use `ChatFrameEditBox:Insert(link)` or hook `ContainerFrameItemButton_OnClick`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Length Operator (`#t`)**              | ❌ **SYNTAX ERROR**       | Use `table.getn(t)` for tables, `string.len(s)` for strings.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **Integer Division (`//`)**             | ❌ **SYNTAX ERROR**       | Use `math.floor(a / b)`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **Bitwise Operators (`&`, `\|`, `~`)**  | ❌ **SYNTAX ERROR**       | Use arithmetic emulation or SuperWoW bitlib if available.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **`string.gmatch`**                     | ❌ **DOES NOT EXIST**     | Use `string.gfind(s, pattern)`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **`string.match`**                      | ❌ **DOES NOT EXIST**     | Use `string.find(s, pattern)` with capture unpacks.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **`string.lower()` / `string.upper()`** | ❌ **STRICTLY FORBIDDEN** | In Lua 5.0, `string.lower()` and `string.upper()` operate byte-by-byte using single-byte ASCII ranges. On Chinese/multilingual servers (zhCN/Turtle WoW), channel names, character names, and chat text contain multibyte encodings (GBK / UTF-8). Calling `string.lower` or `string.upper` can mutate bytes that fall in ASCII range, corrupting Chinese characters, and has no effect on non-ASCII case folding anyway. NEVER use `string.lower` or `string.upper` in this project. Use exact byte equality (`a == b`), prefix/suffix stripping, or plain substring search (`string.find(str, sub, 1, true)`). |
| **Variadic Expression (`...`)**         | ⚠️ **UNRELIABLE**         | Inside functions, rely on the implicit `arg` table (`arg[1]`, `arg.n`), `unpack()`, or explicit parameter lists.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| **`goto` / Labels**                     | ❌ **SYNTAX ERROR**       | Use structured control flow (`repeat ... until true`, `break`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Modulus Operator (`%`)**              | ❌ **SYNTAX ERROR**       | `%` doesn't work in WoW 1.12. use `math.mod(a, b)` instead.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **Global Environment Table**            | `_G` & `getglobal`       | Both `_G["name"]` and `getglobal("name")` are valid.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **Backward/Forward Compatibility**      | ❌ **DON'T CONSIDER**     | If you are sure some wow api or global variables are introduced later than 1.12, don't try to support it.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |

### Closure Variable Scoping Gotcha
In Lua 5.0, loop variables inside `for` loops can have scope quirks when captured by closures. Always re-bind loop variables into an explicit local variable before creating closures:
```lua
-- Correct in Lua 5.0:
for _, categoryName in ipairs(CATEGORY_LIST) do
    local capCategory = categoryName -- explicit local capture
    btn:SetScript("OnClick", function()
        select_category(capCategory)
    end)
end
```

---

## 2. WoW 1.12 FrameXML & Script System

### Pure Lua UI: Strictly NO XML for UI Creation
- **Rule:** Never use XML files (`.xml`) to create UI layouts, frames, or visual elements.
- **Rationale:** All frames, textures, buttons, and font strings must be created programmatically in Lua using `CreateFrame`, `OzUIHelper:create*`, or declarative schema tables. Pure Lua UI eliminates XML caching/reload bugs, avoids global namespace pollution from template tags, keeps layout testable, and allows complete dynamic resizing and anchor recalculation.

### Script Handler Context: `this`, `event`, `arg1`–`arg9`
In WoW 1.12, frame script handlers (`SetScript`) are executed within a special global context. They do **NOT** receive `self` as the first parameter:
```lua
-- ❌ Modern WoW (3.x+) pattern - FAILS in 1.12:
frame:SetScript("OnEvent", function(self, event, arg1) ... end)

-- ✅ Correct WoW 1.12 pattern:
frame:SetScript("OnEvent", function()
    -- 'this' is the frame
    -- 'event' is the event name string
    -- 'arg1' ... 'arg9' are the event payload arguments
    if event == "ADDON_LOADED" and arg1 == "OzUF" then
        -- handle init
    end
end)
```

### Frame Creation & Memory Permanence
> **CRITICAL:** Frames created via `CreateFrame` can **NEVER be garbage collected** by the client during a game session.
- **Frame Leaks:** Never call `CreateFrame` inside loops, `OnUpdate`, or repeated UI `refresh()` calls.
- **Frame Pooling:** Always recycle rows and buttons using a virtual row pool table (`rowPool = {}`). Show active rows and hide unused rows.
- **Parenting:** Always explicitly specify the parent frame. If orphaned, frames will fail to inherit scale or hide/show state.

### Garbage Collection & Loop Depth Rules
> [!CAUTION]
> **Lua 5.0 Stop-The-World GC & Single-Thread CPU Stalls:**
> 1. **NEVER create temporary tables in any event handling or `OnUpdate` function**: In Lua 5.0 (WoW 1.12), the garbage collector uses a stop-the-world mark-and-sweep algorithm. Allocating temporary tables (`{ ... }`, `{ GetChannelList() }`, `results = { orig(...) }`, etc.) inside `OnEvent`, `OnUpdate`, or hook wrappers accumulates thousands of garbage objects that trigger full GC freezes every couple minutes. Always reuse static file-level buffers, recycle table entries (`local entry = tbl[k] or {}`), or pass/return discrete positional arguments (`r1, r2, ...`).
> 2. **NEVER nest `for` loops deeper than 3**: Deeply nested iteration causes severe CPU stalls on the single-threaded client. Refactor multi-level iterations into indexed hash tables (O(1)), flatten loop logic, or spread work across multiple frames via ticker budgeting.

### FontString APIs: Strictly NEVER Call `GetStringHeight()`
> [!CAUTION]
> **`FontString:GetStringHeight()` DOES NOT EXIST in WoW 1.12.1 (Build 5875).**
> Calling `fontString:GetStringHeight()` will immediately crash the UI with:
> `attempt to call method 'GetStringHeight' (a nil value)`.
> - **Width:** `fontString:GetStringWidth()` IS supported natively.
> - **Height:** `fontString:GetStringHeight()` was only introduced in TBC (WoW 2.0).
> - **Correct alternatives:**
>   - Use `fontString:GetHeight()` (returns the allocated frame height).
>   - Use fixed standard font metrics (e.g. `14` for body text, `18` for headers).
>   - Use guarded fallback if dynamic height is desired:
>     ```lua
>     local h = (fs.GetStringHeight and fs:GetStringHeight()) or (fs.GetHeight and fs:GetHeight()) or 14
>     ```

### Strata Hierarchy
When overlapping frames or popups, use standard strata:
`BACKGROUND` &rarr; `LOW` &rarr; `MEDIUM` &rarr; `HIGH` &rarr; `DIALOG` &rarr; `FULLSCREEN` &rarr; `FULLSCREEN_DIALOG` &rarr; `TOOLTIP`.

---

## 3. Hooking Conventions & Safe Interception

Directly overwriting Blizzard or third-party functions is strictly forbidden. Always use clean function hooking:

```lua
-- Global function hook:
local orig_Func = Blizzard_Function
Blizzard_Function = function(a1, a2)
    orig_Func(a1, a2)
    -- custom logic
end

-- Secure hook pattern / guard recursion:
local is_updating = false
local function Safe_Update()
    if is_updating then return end
    is_updating = true
    -- perform updates
    is_updating = false
end
```

### Hook Safety Rules
1. **Recursion / Re-entrancy:** Hooks must never cause infinite recursion. Manual logic that triggers hooked events inside the hook must be guarded with flags.
2. **Preserve Arguments & Returns:** Always pass arguments through and preserve return values where applicable.

---

## 4. Naming Standards & Code Style

To maintain clean, consistent, and predictable code across the addon, adhere strictly to these naming conventions:

| Element                        | Convention         | Example                                                                                     | Notes                                                                                                            |
| :----------------------------- | :----------------- | :------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------- |
| **Module / Table / Metatable** | `PascalCase`       | `OzConfig`, `OzUF`, `OzHook`, `OzCastbar`                                                   | Applied to modules, singleton libraries, and metatables. Matches Blizzard API style (`CreateFrame`, `SetPoint`). |
| **Class Method**               | `snake_case`       | `get_value`, `create_button`, `apply_backdrop`, `register_mod`                              | Invoked with colon syntax (`obj:get_value()`).                                                                   |
| **Local Function**             | `snake_case`       | `print_null`, `toggle_system_buttons`, `update_layout`, `build_schema_ui`, `get_saved_size` | No prefix rules. Name should be self-explanatory.                                                                |
| **Global Variable / Constant** | `UPPER_SNAKE_CASE` | `CATEGORY_LIST`, `MINIMAP_ASSETS`, `CLASS_COLORS`, `OZUF_CONFIG`                            | Used for constants, global configurations, and lookup tables.                                                    |
| **Local Variable / Value**     | `snake_case`       | `system_status`, `frame_width`, `active_category`, `event_frame`, `item_count`              | No prefix rules. Name should be self-explanatory.                                                                |

### Why this mix (PascalCase modules + snake_case everything else)?
- **Blizzard API is PascalCase** (`CreateFrame`, `SetPoint`, `GetTime`). Modules that wrap Blizzard APIs use PascalCase to stay visually consistent with the host API.
- **Everything else is snake_case** to follow the Linux / LuaRocks / Git convention and avoid mental context-switching.
- **No prefix rules** (no forced `get_` / `set_` / noun-first). Self-explanatory names are better than mechanical prefixes.

### Forbidden
- ❌ `camelCase` for anything (no `getValue`, no `createButton`).
- ❌ `SCREAMING_CASE` for anything except constants.
- ❌ Prefix-based Hungarian notation (`strName`, `iCount`, `bEnabled`).
- ❌ Abbreviations longer than 2 letters that aren't universally understood (`cfg` ok, `sysstat` not ok).

---

## 5. Localization: Metatable Auto-Value Pattern

Never manually assign identical values for both `enUS` and `zhCN`. The English key string **IS** the default value.

### Standard Localization Pattern
Always define the localization table `L` and then define function `L_(k)` to auto fallback to the key string itself:

```lua
local LOCALE = GetLocale()
local L = {}
local function L_(k)
    return L[k] or k
end

-- Only define overrides for non-English locales (e.g. zhCN):
if LOCALE == "zhCN" then
    L["Auto Dismount"] = "自动下马"
    L["Auto Stance"]   = "自动姿态"
    L["Font Size"]     = "字体大小"
end
```

### Key Rules
- ❌ **FORBIDDEN:** Manually writing `L["Auto Dismount"] = "Auto Dismount"` for English. It creates redundant code, wastes memory, and adds maintenance overhead.
- ✅ **ALLOWED:** Reference English phrases directly in code via `L["Some English Text"]`. The fallback function dynamically returns the key itself on first access.
- ✅ **OVERRIDE:** Add non-English translations only under conditional locale blocks (`if LOCALE == "zhCN" then ... end`).

---

## 6. PRD Standards: Technical Blueprint, Not Presentation

A PRD is a build blueprint, not a brochure. No marketing prose, no aspirational feature lists, no "optional/stretch"
sections — if it is not in the code, it is not a feature. Every PRD contains exactly these four sections:

1. **Feature list** — what the code does today, mapped to file + config keys. Anything not built goes into an explicit
   **"Not implemented"** list so nobody assumes it exists.
2. **Wireframe** — ASCII drawing of the real layout, carrying the real numbers from the config (sizes, paddings,
   offsets), plus the stacking/anchor order.
3. **Table & frame relationship** — both sides:
   - Lua: module tables, config ownership, load order / enable order, runtime state vs config.
   - UI: who is whose parent (`SetParent` = inheritance of visibility/alpha/scale) and who anchors to whom
     (`SetPoint` = position only), including overlay/helper frames we create.
4. **Key tech challenge & resolution** — for each: the problem, *why the host system fights back*, the resolution,
   and where it lives. Example of the level of detail expected:
   "Blizzard re-shows hidden art on every layout pass → stub `Show()` with an empty function; `Hide()` alone is undone."

### Rules of thumb
- Prefer a table or a diagram over a paragraph.
- Numbers in the wireframe must match the config; never invent dimensions.
- Every "weird" workaround in the code must be traceable to an item in section 4.

---

## 7. Code Comment Policy: Comment the *Why*, Nothing Else

- ❌ **No comments that restate the code**: no section labels (`-- Bottom stack`), no narration
  (`-- loop over buttons`), no `-- set width` above a `SetWidth`.
- ✅ **Comment only non-obvious reasons**, i.e. what a reader cannot derive from the code:
  - workarounds for host-system behaviour (re-shown frames, forced sizes, re-applied textures),
  - re-entrancy / ordering guards,
  - client constants and magic numbers and where they come from,
  - performance trade-offs (why one shared ticker instead of N scripts),
  - ownership.
- **Format:** 1–2 lines directly above the code, first line states the reason, not the action.
- Config files may carry short ownership/default notes; everything else must earn its place.

---

## 8. Performance & Code Quality Checklist

Before committing or submitting changes to this repository, verify:
- [ ] **PRD has all four sections:** feature list (with "not implemented" list), ASCII wireframe with real numbers, table + UI parent/anchor relationships, key tech challenge & resolution.
- [ ] **Comments only explain *why*.** No narration, no section labels, no restating the code.
- [ ] **Every workaround in the code is covered by a PRD section 4 entry.**
- [ ] **Strictly NO XML for UI:** All UI constructed programmatically in Lua.
- [ ] **Naming standards adhered to:** Classes in `PascalCase`, methods in `snake_case`, local functions in `snake_case`, local variables in `snake_case`, globals in `UPPER_SNAKE_CASE`.
- [ ] **Metatable auto-value used for localization:** No redundant manual `enUS` key=value assignments.
- [ ] **No `#` length operators used.** (`table.getn` / `string.len` used instead).
- [ ] **No `//` integer division.** (`math.floor(a / b)` used instead).
- [ ] **No `string.gmatch`.** (`string.gfind` used instead).
- [ ] **No `string.lower` or `string.upper`.** (Corrupts Chinese / multibyte GBK/UTF-8 byte sequences; use exact equality or plain find).
- [ ] **No frame allocation leaks in loops.** Reusable row frame pools used for lists.
- [ ] **Script handlers use `this`, `event`, `arg1`..`arg9`** (no modern `self` parameters in `SetScript`).
- [ ] **No `CreateFrame` inside `OnUpdate` event.**

---

## 9. What you can't do

### Environment limits
- There is no lua runtime installed on this PC, so no command-line syntax verification is available.
- There is a WoW client, but cannot be run directly from terminal. If there is a bug, add print logs and ask the user to provide output.

### Modification limits
- Don't modify third-party core libraries unless 100% sure it's wrong. Ask first.
- Don't add new files outside the agreed directory structure.

### When uncertain
- If a rule conflicts with user instruction → **ask the user**.
- If a rule conflicts with existing code → **follow the rule**, note the deviation in a comment.
- If an API's existence is uncertain → **use `pcall` to verify at runtime**, or ask.
- If a task requires verification you can't do → **say so explicitly**, don't guess.
