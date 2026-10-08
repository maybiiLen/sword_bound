--[[
================================================================================
  INVENTORY  (weapons for now)
================================================================================
Which weapons a player owns, shown in the Inventory panel, and the gate for equipping them.

FLOW
  Open the panel -> InventoryItemsController (client) shows owned weapons in the item grid
  -> click one to SELECT it (details appear on the DetailCard) -> press Equip ->
  EquipRemote("Equip", weaponId) -> WeaponService checks
  InventoryService:Owns + that you are not mid-attack/block -> equips (model on the back,
  active class, data.EquippedWeapon saved) -> the character attribute EquippedWeapon changes
  -> the UI moves the E badge, the Weapon row and the stats (ATK).
  The client never decides anything: it displays what the server says.

WHERE THINGS ARE
  DataTemplate.Inventory                      saved: { Weapons = { [weaponId] = true } }
                                              (new players start with TestSword + StarterSword)
  ServerScriptService.Inventory
    InventoryServer (Script, bootstrap), InventoryService (module)
  ReplicatedStorage.Inventory.Remotes
    GetInventory (RemoteFunction, no args) -> { Weapons = { weaponId } }
    InventoryChanged (RemoteEvent, server -> client) same snapshot after a grant
  StarterGui.Main Menu Gui.InventoryItemsController (LocalScript)
                                              drives the Equipment screen (see SCREEN LAYOUT)
  StarterGui.Main Menu Gui.InventoryHudHider (LocalScript)
                                              hides every other HUD/menu while the panel is open
                                              (see HUD HIDING)
  StarterGui.Main Menu Gui.InventoryController opens/closes the panel and hands the camera to
  InventoryCamera (it no longer builds a duplicate-character preview).
  StarterGui.Main Menu Gui.InventoryCamera (ModuleScript)
                                              frames the live character while the panel is open
  StarterGui.Main Menu Gui.InventoryTabController switches Equipment/Mounts (dark colors,
  title + subtitle per tab).

API  (InventoryService, server)
  :Owns(player, weaponId) -> boolean
  :GetWeapons(player) -> { weaponId }          sorted, registered weapons only
  :GrantWeapon(player, weaponId) -> boolean    use this for drops, shops, quest rewards
  A player is never locked out of their equipped weapon: on load it is added to the owned set
  if missing (saves from before inventory existed).

SCREEN LAYOUT  (InventoryPanel spans ~96% x 94% of the screen at 16:9, dark theme; modeled on the SAO
equipment reference)
  Two groups with a gap between them: the LEFT group (character + stats) floats over the world at the
  left of the screen; the RIGHT group (title, tabs, slot list, detail card, grid) is the "Equipment"
  panel at the right (x 43%-100%). The TitleBar/TabBar only span the right group.
  TitleBar (title + subtitle + close) / TabBar (Equipment, Mounts) / Body:
    Body.EquipmentPanel   left: PlayerNameLabel (the character itself is the LIVE one in the world, see CHARACTER VIEW), LevelLabel (mirrors
                          ClassGui's level), StatsPanel (Stat_HP/Stamina/SP/ATK/DEF/STR/AGI/DEX/INT).
                          HP, Stamina and ATK (equipped weapon Damage) are live; the rest show "-"
    Body.SlotsPanel       middle: SlotList rows Row_Weapon/Jacket/Gloves/Pants/Shield (only Weapon is
                          real, the others are empty placeholders) and DetailCard (name, Weapon ATK,
                          Reach, icon, STR/DEX/AGI/INT, Unique MOD, EX-MOD, EquipButton). MOD and
                          stat boxes are placeholders until those systems exist
    Body.ItemsPanel       right: CategoryBar (only Swords is real), SearchBar, ItemGrid, Footer
                          (Weapons Held count, Lock/Unlock = placeholder, Sort A-Z/Z-A works)
  MountsBody is the Mounts tab (restyled dark, sits in the right group). The tab switch hides Body,
  so the character + stats are hidden on the Mounts tab.

UI NOTES
  - Slots are the pre-built ItemSlot1..100 buttons; owned weapons fill them by DisplayName (Sort
    toggles A-Z / Z-A); the SearchBox filters by name. Unused slots stay empty. The controller sets
    the grid CellSize so 5 square cells fill the width.
  - Each slot gets a ViewportFrame icon of the weapon model, a name label, an "EquippedBadge" (E)
    if equipped and a "SelectedMarker" outline if selected. Both are child Frames/labels, never
    recolors of the button, so ButtonHoverEffects' hover tweens don't fight them.
  - New weapons appear automatically once they are in the player's Inventory.Weapons.
  - Z-ORDER: the Main Menu Gui uses ZIndexBehavior.Global, so everything generated inside a slot
    or card is given a ZIndex above its parent's (icon +1, name +2, badge +3, marker +4).
    Leaving them at the default ZIndex would draw them behind the slot background and the slots
    would look empty.

TAPER  (the perspective look of the reference: panels start a little smaller toward the middle of the
screen and grow taller toward the screen edges; nothing is rotated)
  Roblox UI has no perspective, so the taper is drawn with rows of thin vertical "slices" (plain Frames)
  whose heights change from one end to the other. The panels' contents stay rectangular.
    - LEFT: Body.EquipmentPanel.StatsPanel.Shape (48 slices): the stats panel is 10% shorter at its inner
      (right) end than at the screen-edge (left) end, kept vertically centered.
    - RIGHT: InventoryPanel.RightShape (48 slices, behind everything): a dark silhouette around the
      Equipment panel. Its inner (left) end hugs the content, the outer (right) end is taller: the top edge
      rises ~2.2% and the bottom edge falls ~1.8% of the panel height toward the screen edge.
  CONTENTS follow the same perspective (subtle, a degree or so): each element is rotated about its center by
  the slope of its own height (top bands rise toward the screen edge, bottom ones fall) and, in the right
  group, the two columns are stretched vertically by their position (SlotsPanel ~1%, ItemsPanel ~3%).
    - RIGHT: TitleBar, TabBar, SlotsPanel.SlotList / DetailCard, ItemsPanel.CategoryBar / SearchBar / Footer
    - LEFT: each StatsPanel Stat_ row and the LevelLabel (rows above the middle fall toward the inner end,
      rows below it rise, and they shrink a little toward the inner end)
    - ItemGrid is deliberately NOT rotated (a rotated ScrollingFrame can't clip); only its column is stretched
  Every moved element keeps its original layout in attributes (TaperPos, TaperSize, TaperAnchor, TaperRot),
  so the effect can be tuned or undone: restore Position/Size/AnchorPoint/Rotation from those and re-apply.
  Rotation pivots use AnchorPoint (0.5, 0.5) on these elements; keep that if you move them.
  To change the amount, resize the slices' Y Position/Size scale (or delete the Shape and rebuild it with
  other numbers). Slices are translucent and tile exactly with no overlap, which shows no seams while the
  panel is NOT rotated; once a parent is rotated they show hairline seams (use opaque slices that overlap
  a hair instead). CanvasGroup.GroupTransparency was ignored in testing, so don't use it for this.
  ROBLOX LIMITATION worth knowing: a rotated GUI (or any GUI under a rotated parent) cannot clip its
  children, so a ScrollingFrame inside a rotated InventoryPanel spills out. InventoryPanel.Rotation is 0
  now. If you ever tilt it again, set PAGED_GRID = true at the top of InventoryItemsController: the grid
  then shows only the rows that fit and pages with the mouse wheel (ScrollTrack shows the position).

CHARACTER VIEW
  The character shown at the left is the player's LIVE character, not a copy. InventoryController
  calls InventoryCamera.Enter() on open and .Exit() on close. While open:
    - the camera locks onto the character from a 3/4 front angle, framed at the left of the screen
      above the stats panel and turned toward the menu; it follows the character if it moves
    - the character keeps animating, and the equipped sword stays drawn in its hand the whole time
    - walking/jumping input (WASD, arrows, Space, left stick, A button) is blocked by a
      high-priority ContextActionService sink, and every combat key (attack, block, roll, lock-on and E)
      is swallowed by InventoryWeaponDisplay (client-side only; the server does not know the panel is open)
    - the cursor is freed even if the combat camera had locked it
  Exit() restores the previous camera (type, position, field of view) and the movement input.
  WEAPON IN HAND: InventoryWeaponDisplay (called by InventoryController next to InventoryCamera) draws the
  equipped weapon into the character's hand while the panel is open, so the weapon you equip is the one you
  see. It sends the normal EquipRemote("Toggle") (the server stays in charge: cooldown, Idle-state check,
  animations, other players), retrying a few times if the server ignores a request.
    - open: remembers whether the weapon was drawn, draws it if it wasn't
    - equip a different weapon while open: WeaponService:Equip puts the new one on the back (WeaponDrawn is
      reset), then InventoryWeaponDisplay draws it again (~0.2 s later)
    - close: puts it back the way it was (sheathed if it was sheathed before, still drawn if it was drawn)
    - pressing E while open does nothing: ToggleWeaponInputs is blocked (press only; releases pass), so the
      sword can't be sheathed and redrawn. The module's own requests use EquipRemote directly and are not blocked
  Framing numbers (FOV, screen position, camera angle, easing) are constants at the top of
  InventoryCamera. A wall between the character and the camera pulls the camera in closer.
  Roblox's default PlayerModule is NOT used (it is not present in this game's PlayerScripts).
  The old ViewportFrame (EquipmentPanel.AvatarViewport) is left in place, hidden and unused.

HUD HIDING
  While InventoryPanel is visible, InventoryHudHider disables every other ScreenGui in PlayerGui
  (SAO_HUD, SprintGui, ClassGui, AbilityHud, ...), hides the "Main Menu" button and turns off
  Roblox's chat / player list / backpack / health / emotes. It restores exactly what it hid when
  the panel closes. A new HUD gets hidden automatically; keep a gui visible by adding it to KEEP in
  the script (TouchGui and Freecam are in it). Roblox's own top-left menu buttons cannot be hidden.

NOT BUILT YET
  Armour/accessory/off-hand items (the Jacket/Gloves/Pants/Shield rows are placeholders), the
  stats behind SP/DEF/STR/AGI/DEX/INT, MODs, other weapon categories, Lock/Unlock, stacking, drag
  and drop, unequip, revoking weapons. Add other item types as new keys under DataTemplate.Inventory.
]]

return {}

