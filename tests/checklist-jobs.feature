# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_mining — Jobs

  @kora_mining @checklist @checklist:kora_mining:mine-rock @cat:jobs
  Scenario: Mine a rock via target
    """
    Checklist test: Look at a placed rock prop, use target 'Mine rock'; progress bar + pickaxe anim runs, ore/gem item added to inventory.
    """
    Given I have 1 "bronze_pickaxe"
    When I manually: go to a placed mining rock prop and look at it
    And I select the "Mine rock" target option
    Then a progress bar should run
    And I confirm: my character plays the pickaxe animation
    And I confirm: an ore or gem item is added to my inventory

  @kora_mining @checklist @checklist:kora_mining:mine-requires-pickaxe @cat:jobs
  Scenario: Pickaxe and level requirement
    """
    Checklist test: Try mining without a pickaxe or below the rock's level; error notification, no item and no XP.
    """
    Given I have no "bronze_pickaxe"
    And I have no "iron_pickaxe"
    And I have no "steel_pickaxe"
    And I have no "titanium_pickaxe"
    And I have no "obsidian_pickaxe"
    When I manually: go to a placed mining rock prop and try to mine it with target 'Mine rock'
    Then I should see an error notification
    And I confirm: no item is added to my inventory
    And I confirm: my mining XP did not increase
    When I manually: get a pickaxe, then try to mine a rock whose required level is above my mining level
    Then I should see an error notification
    And I confirm: no item is given and no XP is gained

  @kora_mining @checklist @checklist:kora_mining:mine-xp @cat:jobs
  Scenario: Mining XP gained
    """
    Checklist test: Mine rocks and check kora_skills mining XP increases by the rock's xpPerMine and level-ups occur.
    """
    Given I have 1 "bronze_pickaxe"
    When I manually: note my current mining XP in kora_skills
    And I manually: mine several rocks via target 'Mine rock'
    Then I confirm: my kora_skills mining XP increased by the rock's xpPerMine for each rock mined
    And I confirm: a level-up occurs when the XP threshold is reached

  @kora_mining @checklist @checklist:kora_mining:rock-respawn @cat:jobs
  Scenario: Rock taken and respawn
    """
    Checklist test: After mining a rock it disappears for all players and reappears after the respawn time (default 60s).
    """
    Given I have 1 "bronze_pickaxe"
    When I manually: mine a placed rock via target 'Mine rock'
    Then I confirm: the rock disappears
    When I manually: ask a second player to look at the same rock spot
    Then I confirm: the other player sees the rock gone as well
    When I wait 60 seconds
    Then I confirm: the rock reappears after the respawn time (default 60s)
    And I confirm: the other player also sees the rock again

  @kora_mining @checklist @checklist:kora_mining:mine-speed-bonus @cat:jobs
  Scenario: Pickaxe tier / level speed bonus
    """
    Checklist test: Compare progress time with bronze vs higher pickaxe and at higher mining level; duration shortens.
    """
    Given I have 1 "bronze_pickaxe"
    And I have 1 "iron_pickaxe"
    When I manually: mine a rock with the bronze pickaxe and note how long the progress bar takes
    And I manually: mine the same kind of rock with the iron pickaxe and note the progress time
    Then I confirm: the progress time with the iron pickaxe is shorter
    When I manually: gain a higher mining level and mine the same rock again
    Then I confirm: the progress duration is shorter than at the lower level

  @kora_mining @checklist @checklist:kora_mining:mine-cancel @cat:jobs
  Scenario: Cancel mining
    """
    Checklist test: Start mining then cancel the progress bar; no item given, rock stays available.
    """
    Given I have 1 "bronze_pickaxe"
    When I manually: start mining a rock via target 'Mine rock'
    And I cancel the progress bar
    Then I confirm: no item was added to my inventory
    And I confirm: the rock is still available to mine

  @kora_mining @checklist @checklist:kora_mining:pickaxe-vendor @cat:jobs
  Scenario: Pickaxe vendor shop
    """
    Checklist test: At a vendor ped use target 'Buy Pickaxes'; shop lists Bronze/Iron/Steel/Titanium/Obsidian with levels and prices.
    """
    When I manually: go to a pickaxe vendor ped
    And I select the "Buy Pickaxes" target option
    Then the "kora_mining:pickaxeShop" app opens
    And I confirm: the shop lists Bronze, Iron, Steel, Titanium and Obsidian pickaxes
    And I confirm: each pickaxe shows its required level and price

  @kora_mining @checklist @checklist:kora_mining:buy-pickaxe @cat:jobs
  Scenario: Buy a pickaxe
    """
    Checklist test: Buy Bronze Pickaxe ($250); cash deducted, item added; high-tier pick locked below required level; owned item shows 'Owned'.
    """
    Given my cash balance is at least 250
    And I have no "bronze_pickaxe"
    When I manually: go to a pickaxe vendor ped
    And I select the "Buy Pickaxes" target option
    And I manually: buy the Bronze Pickaxe ($250)
    Then my cash balance should have changed by -250
    And my "bronze_pickaxe" count should have changed by 1
    And I confirm: a high-tier pickaxe above my level is shown as locked and cannot be bought
    And I confirm: the Bronze Pickaxe now shows 'Owned' in the shop

  @kora_mining @checklist @checklist:kora_mining:smelter-station @cat:jobs
  Scenario: Smelter menu
    """
    Checklist test: At the smelter (1110.65,-2008.68,30.93) target 'Open Smelter'; recipe list for bars/materials/jewellery with needs and level.
    """
    Given I am at 1110.65, -2008.68, 30.93
    When I select the "Open Smelter" target option
    Then the "kora_mining:smelting" app opens
    And I confirm: a recipe list for bars, materials and jewellery is shown
    And I confirm: each recipe shows its needed items and required level

  @kora_mining @checklist @checklist:kora_mining:smelt-bar @cat:jobs
  Scenario: Smelt ore into bar
    """
    Checklist test: Select Smelt Copper with copper_ore; 10s progress, ore consumed, copper_ignot given, smelting XP added.
    """
    Given I have 10 "copper_ore"
    When I manually: go to a smelting station and open it with the target option
    And I manually: select Smelt Copper
    Then a progress bar should run
    And I confirm: the progress bar lasts about 10 seconds
    And I confirm: the copper_ore is consumed
    And I should have at least 1 "copper_ignot"
    And I confirm: smelting XP is added

  @kora_mining @checklist @checklist:kora_mining:smelt-requirements @cat:jobs
  Scenario: Smelting level/ingredient check
    """
    Checklist test: Try a recipe lacking ingredients or level (e.g. Smelt Gold at lvl<40); refused with an error.
    """
    Given I have no "gold_ore"
    When I manually: go to a smelting station and open it with the target option
    And I manually: try a recipe without the required ingredients
    Then I should see an error notification
    When I manually: try Smelt Gold with a smelting level below 40
    Then I should see an error notification

  @kora_mining @checklist @checklist:kora_mining:smelt-materials @cat:jobs @manual
  Scenario: Process materials and jewellery
    """
    Checklist test: Craft Process Steel / Gold Ring / gem jewellery at the smelter; inputs consumed, output given.
    """
    When I manually: go to a smelting station and open it with the target option
    And I manually: craft Process Steel with the required inputs
    Then I confirm: the inputs are consumed and the output is given
    When I manually: craft a Gold Ring with the required inputs
    Then I confirm: the inputs are consumed and the output is given
    When I manually: craft a gem jewellery piece with the required inputs
    Then I confirm: the inputs are consumed and the output is given

  @kora_mining @checklist @checklist:kora_mining:gem-cutter @cat:jobs
  Scenario: Gem cutter station
    """
    Checklist test: At the cutter (1072.7,-1987.54,30.75) use target 'Cut Gems' and cut uncut gems if recipes are configured.
    """
    Given I am at 1072.7, -1987.54, 30.75
    When I select the "Cut Gems" target option
    Then I confirm: the cutter menu opens (only applies when cutting recipes are configured; otherwise mark Pass if nothing is listed)
    When I manually: cut an uncut gem
    Then I confirm: the uncut gem is consumed and the cut gem is given

  @kora_mining @checklist @checklist:kora_mining:smelt-cancel @cat:jobs
  Scenario: Cancel smelting
    """
    Checklist test: Start smelting then cancel; ingredients are not consumed and you can start again.
    """
    Given I have 10 "copper_ore"
    When I manually: go to a smelting station and open it with the target option
    And I manually: start Smelt Copper
    And I cancel the progress bar
    Then I should have 10 "copper_ore"
    And I should see a notification containing "Smelting cancelled"
    When I manually: start Smelt Copper again
    Then a progress bar should run

  @kora_mining @checklist @checklist:kora_mining:mining-creator @cat:jobs @needs:admin
  Scenario: Admin /miningCreator
    """
    Checklist test: As admin run /miningCreator; non-admin gets 'Admin permission required'. App lists rockspawns, smelting and pickaxe vendor tabs.
    """
    When I run the command "/miningCreator"
    Then the "kora_mining:creator" app opens
    And I confirm: the app lists rockspawns, smelting and pickaxe vendor tabs
    When I manually: ask a second non-admin player to run /miningCreator
    Then I confirm: the other player sees the notification 'Admin permission required'

  @kora_mining @checklist @checklist:kora_mining:creator-rockspawn @cat:jobs @needs:admin
  Scenario: Create/edit rockspawn and spots
    """
    Checklist test: In creator create a rockspawn, set model/item/level/XP/respawn, place spots, save, delete; rocks update live.
    """
    When I run the command "/miningCreator"
    Then the "kora_mining:creator" app opens
    When I manually: in the creator create a rockspawn
    And I manually: set its model, item, level, XP and respawn
    And I manually: place spots for it and save
    Then I confirm: rocks update live at the placed spots
    When I manually: delete the rockspawn
    Then I confirm: its rocks are removed live

  @kora_mining @checklist @checklist:kora_mining:creator-smelting @cat:jobs @needs:admin
  Scenario: Create smelting recipes/crafters
    """
    Checklist test: In creator make a new recipe and a new crafter station with location; station appears with target after save.
    """
    When I run the command "/miningCreator"
    Then the "kora_mining:creator" app opens
    When I manually: open the smelting tab and create a new recipe
    And I manually: create a new crafter station and place its location
    And I manually: save the station
    Then I confirm: the station appears with a target option at its location

  @kora_mining @checklist @checklist:kora_mining:creator-vendor @cat:jobs @needs:admin
  Scenario: Creator pickaxe vendor locations/prices
    """
    Checklist test: In creator add/remove vendor locations and change a pickaxe price; vendor ped and shop price update.
    """
    When I run the command "/miningCreator"
    Then the "kora_mining:creator" app opens
    When I manually: open the pickaxe vendor tab and add a vendor location
    Then I confirm: a vendor ped appears at the new location
    When I manually: remove a vendor location
    Then I confirm: the vendor ped at that location is removed
    When I manually: change a pickaxe price and save
    Then I confirm: the shop shows the updated price
