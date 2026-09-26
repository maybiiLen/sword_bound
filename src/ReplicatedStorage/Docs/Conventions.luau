--[[
================================================================================
  CONVENTIONS  (rules for every dev AND every dev's Cursor agent)
================================================================================
We all build live in the same Team Create place, each through our own Cursor + Studio
connection. There are no branches, so these rules are what keeps us from breaking
each other's work.

1. READ FIRST
   Before changing a system, read its Docs page and the header comment of every module you
   touch. Agents: start every task by reading Docs.README.

2. ONE OWNER, ONE FOLDER
   Each system lives in its own folders (see the index in Docs.README). Build new things in
   your own folders. Need something from another system? Use its public API / attributes /
   signals, or ask the owner to add one.

3. NEVER DELETE OR RECREATE SOMEONE ELSE'S INSTANCES
   No "clear the folder and rebuild". Make targeted edits (change the lines you need).
   Agents: never Destroy() or overwrite instances outside your task's folders.

4. EDIT SCRIPTS, DON'T REPLACE THEM
   Change the specific lines. Replacing a whole script silently erases whatever a teammate
   changed in it a minute ago.

5. CODE SHAPE
   - Server: ModuleScript services with :Start(), plus ONE bootstrap Script per system.
   - Client: ModuleScript controllers with :Start(), plus ONE bootstrap LocalScript.
   - Tuning numbers live in a Config module, not scattered through code.
   - Content (weapons, classes...) is data modules; behavior is classes (see Docs.Combat).
   - Server is authoritative: the client may predict and request, the server decides.
   - Validate every RemoteEvent argument on the server (typeof checks, ranges, rate).
   - Cross-system state goes through Attributes (replicated) with names kept in the Config.
   - Clean up with Trove; custom events with Signal (ReplicatedStorage.Shared.Util).

6. EVERY MODULE STARTS WITH A HEADER COMMENT
   Purpose, public API, who uses it, and which Docs page covers it.

7. SAVED DATA IS SACRED
   Only add keys to PlayerData.DataTemplate. Never rename/remove a key without the owner;
   it wipes players' progress. See Docs.PlayerData.

8. FINISH = DOCS UPDATED
   Update your Docs page and add a line to the Docs.README changelog.

9. GIT (optional history)
   Henry snapshots the place into git for history (Studio -> git, one way). Git is a
   backup, not how we sync; the live place is the source of truth.
]]

return {}
