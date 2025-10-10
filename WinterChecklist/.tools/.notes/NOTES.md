# Lua Notes — Core Concepts (from WinterChecklist exploration)

These notes summarize key Lua behaviors and conventions you’ve encountered while reading through **WinterChecklist.lua**.

---

## 1. `local ADDON_NAME, NS = ...`
- `...` = Lua's **varargs** operator — it captures all unnamed arguments passed to a chunk or function.
- In WoW, each addon file is *executed like a function call* where Blizzard passes:
  1. `ADDON_NAME`: a **string** (the addon folder name, e.g. `"WinterChecklist"`)
  2. `NS`: a **shared table** (namespace) common to all files in the same addon.
- `NS.ADDON = ADDON_NAME` stores the name for reference elsewhere.
- This pattern prevents global pollution and provides a shared space for addon data.

---

## 2. `do ... end` — Local scope block
- Creates a **temporary scope** for local variables and function definitions.
- Anything `local` inside the block vanishes after `end`.
- Common uses:
  - Keep helper functions private.
  - Create short‑lived constants or aliases (`local tinsert = table.insert`).
  - Improve speed via local lookups.
  - Group related functions neatly without leaking names.

---

## 3. `tcopy` and `tcopy_missing`
- Custom **deep‑copy / deep‑merge** helpers.
- `tcopy(dst, src)` overwrites `dst` values with those from `src` (recursively).
- `tcopy_missing(dst, src)` fills only *absent* keys (useful for defaults).
- They are exported as `NS.table_copy` / `NS.table_copy_missing` and called under those names.

---

## 4. Function definition styles
| Syntax | Equivalent to | Notes |
|--------|----------------|-------|
| `function NS:Print(...) end` | `NS.Print = function(self, ...) end` | “Method” form; gets `self` automatically. |
| `function NS.Print(...) end` | `NS.Print = function(...) end` | Plain function, no `self`. |
| `local function Foo(...) end; NS.Foo = Foo` | same as above | Useful if you want locals for recursion or testing. |

### Why `:` is used for Print/Debug
- Signals that the function is a **method** on the namespace.
- Keeps the local scope clean (no `local Print` name left behind).
- Automatically passes `self` when you call `NS:Print()`.

---

## 5. `self` and the colon operator
- `:` in **definitions** adds a hidden first parameter named `self`.
- `:` in **calls** passes the left‑hand value as that parameter.
- Example:
  ```lua
  function NS:Debug(msg)
    print(self.ADDON, msg)
  end

  NS:Debug("hi")   -- calls NS.Debug(NS, "hi")
  ```
- Use `.` for plain functions (no implicit `self`), `:` for methods needing context.

---

## 6. General addon best practices illustrated
- **Use locals** wherever possible; avoid polluting `_G` (the global table).
- **Share data/functions** only through the `NS` table.
- **Keep utilities** inside `do ... end` blocks for tidy organization.
- **Alias global functions** (e.g., `local print = print`) inside blocks for performance.
- **Separate configuration and runtime logic** with helpers like `table_copy_missing`.

---

## 7. Mental model summary
- Lua’s modules are just **tables** of functions.
- `:` is syntactic sugar for passing that table as `self`.
- `do ... end` provides a temporary workspace.
- WoW loads each file as a **chunk** with `...` filled automatically.
- Everything is built from simple language features — no classes, no imports; you assemble structures manually.

---

## 8. How locals survive past a `do ... end`

- When a `do ... end` block finishes, **the names** of any locals go out of scope,  
  but **the values** they referred to remain alive if something still references them.

- Example:

  ```lua
  do
    local function tcopy(dst, src)
      -- ...
    end
    NS.table_copy = tcopy
  end
  ```

  Here:
  - `tcopy` is a local variable holding a function.
  - `NS.table_copy = tcopy` assigns that same function to `NS.table_copy`.
  - When the block ends, the *name* `tcopy` vanishes,  
    but the *function value* remains alive because `NS.table_copy` still points to it.

- Inside `tcopy`, recursive calls (`tcopy(dst[k], v)`) work because Lua keeps an  
  **upvalue** reference to the original local function.

- This is how Lua modules “export” functions safely:  
  private locals inside a `do ... end`, public handles via `NS.*`.

---

## 9. Some propmts
  - Assume that I have used your three new files word for word. Move all code from winterchecklist.lua having to do with the minimap button into a new file minimap.lua. Do this revision in the same way as you just did the previous revision -- making sure all four files work well together (utils, slash, minimap and winterchecklist) and note the order I should give in the TOC for them. Provide the new files as downloads only, do not display them.

  - You are a seasoned World of Warcraft LUA developer with thousands of successful addons to your credit and a desire to teach the world your skills. Assume that I have taken all those files from the last result word for word. Now use those to please review all LUA files (not lib/) and check for 
    • inconsistencies
    • magic numbers that should be declared at the beginning
    • localization that should be handled
    • opportunities to have a tiny bit of code actually as a user preference togglable in the options screen
    • top-of-file descriptors that should be revised or added
    • modest comments that should be added for longer sections of code that don't seem to have any
    • namespace or leaky globals
    • other good practices that keep lean, durable code. 
    • good reliance on the 4 lib files we've imported
    • consideration of any other lib files we should import, based on the product direction we are going
  - Complete these recommendations by integrating them into the files you just provided in the last result and but before you link them again as downloadable files, think one more time and be sure we're not missing a better approach.

---

_These fundamentals cover 90% of the Lua behavior you’ll meet when building or debugging WoW addons._

