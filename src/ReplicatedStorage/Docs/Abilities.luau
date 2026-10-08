--[[
================================================================================
  ABILITIES  (HUD only for now)
================================================================================
The ability hotbar at the bottom of the screen: 3 ability slots (key number, name, red cooldown
fill) with one ultimate bar above them. There is NO ability system yet: the HUD displays state
and reports presses, nothing more. Whatever ability system gets built decides what a press does.

WHERE THINGS ARE
  StarterGui.AbilityHud                     the UI (Root > UltimateBar, Root > Abilities > Slot1..3)
    AbilityHudClient (LocalScript)          bootstrap, starts the controller on this ScreenGui
  ReplicatedStorage.Abilities
    AbilityConfig                           slot names, keys, colors, PreviewMode, attribute names
    AbilityHudController                    client module that drives the UI (API below)

CONTROLS
  Abilities: 1 / 2 / 3 (or click/tap the slot).  Ultimate: R (only when the bar is full).
  Keys are skipped while typing in a text box. Change keys in AbilityConfig.

API  (AbilityHudController, client)
  .Activated(slot)               Signal: a slot was pressed while ready (not on cooldown)
  .UltimateActivated()           Signal: ultimate pressed while the bar is full
  :SetAbilityName(slot, name)
  :StartCooldown(slot, seconds)  red fill starts full and drains to empty
  :GetCooldownRemaining(slot)
  :SetUltimateCharge(0..1)       bar fills left to right; brightens when full
  Or drive it with player attributes (names in AbilityConfig.Attributes):
    Ability<N>CooldownEnd (workspace:GetServerTimeNow() timestamp) + Ability<N>CooldownTime
    UltimateCharge (0..1)

PREVIEW MODE
  AbilityConfig.PreviewMode = true makes the HUD fake an ability system so it can be seen and
  tested: pressing a slot starts that slot's PreviewCooldown and adds PreviewUltimateGain to
  the ultimate bar; pressing R when full empties it. Set it to false when real abilities exist.

ADDING A REAL ABILITY
  1. Set PreviewMode = false.
  2. Listen to AbilityHudController.Activated, ask the server to use the ability (the server
     validates cost/cooldown), and on success set the cooldown attributes / call StartCooldown.
  3. Charge the ultimate by setting the player attribute UltimateCharge from the server.

LAYOUT NOTES
  - Pixel sizes: slots 82x72, bar 340x26, 14 px from the bottom edge of the screen. The sprint
    stamina bar (SprintGui) sits just above it. The HUD does not scale for small screens yet.
  - AbilityHud uses ZIndexBehavior.Sibling (the Inventory's Main Menu Gui is Global).

NOT BUILT YET
  Actual abilities, the ultimate's effect, per-ability icons, gamepad bindings, mobile layout.
]]

return {}
