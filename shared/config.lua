Config = {}

-- General Config (using locals for faster access)
Config.Notify = 'ox'       -- Notification system: 'qb' (QBCore), 'ox' (ox_lib), or 'other' (custom implementation)
Config.Progress = 'circle' -- Progress bar style: 'circle' (ox_lib circle) or 'bar' (ox_lib bar)
Config.Language = 'fi'     -- Language: 'en' (English) or 'fi' (Finnish)

-- Debug Config
Config.Debug = {
    Enabled = true,        -- Set to true to enable debug messages
    ShowCoords = true,     -- Show coordinates in debug messages
    LogBinStatus = true,   -- Log bin status (empty/full)
    LogZoneCreation = true, -- Log zone creation events
    LogBagCollection = true -- Log bag collection events
}

-- Locales Config (simplified - only essential strings)
Config.Locales = {
  ['en'] = {
      ['collect_bag'] = 'Collect Garbage Bag',
      ['put_bag'] = 'Put Garbage Bag in Vehicle',
      ['clock_in'] = 'Clock-in',
      ['clock_out'] = 'Clock-out',
      ['clocked_in'] = 'You have clocked in and your vehicle has been released.',
      ['clocked_out'] = 'You have finished your shift and the vehicle has been returned.',
      ['max_bags'] = 'You have reached the maximum number of bags, go to the boss and get paid.',
      ['collecting_bag'] = 'Collecting garbage bag',
      ['putting_bag'] = 'Putting garbage bag in the vehicle',
      ['clocking_in'] = 'Clocking in',
      ['clocking_out'] = 'Clocking out',
      ['pay_received'] = 'You have been paid $%s for the bags you collected.',
      ['no_pay_received'] = 'You didnt collect any bags so you didnt get paid.',
      ['garbage_job'] = 'Garbage Job',
      ['talk_to_boss'] = 'Talk to Boss',
      ['not_enough_money'] = 'You do not have enough money to rent a vehicle.',
      ['rent_success'] = 'You have rented a vehicle.',
      ['vehicle_spawn_failed'] = 'Failed to spawn vehicle',
      ['go_to_area'] = 'Go to the marked area and collect garbage bags.',
      ['no_locations'] = 'No garbage locations configured.',
      ['job_aborted'] = 'Job aborted. No payment received.',
      ['payment_cooldown'] = 'You must wait before receiving another payment.',
      ['bags_collected_msg'] = 'You collected %d garbage bags.',
      ['bags_deposited_msg'] = 'You placed %d garbage bags in the vehicle.',
      ['bin_empty'] = 'This bin is empty.',
      ['marked_bins_only'] = 'You can only collect garbage from marked bins.',
      ['bags_collected'] = 'Bags Collected',
      ['estimated_pay'] = 'Estimated Pay',
      ['rental_cost'] = 'Rental Cost',
      ['all_bins_empty'] = 'All bins in this area are empty. A new zone has been marked on your map.',
      ['new_zone'] = 'New Garbage Zone',
      ['new_zone_creating'] = 'Creating new garbage zone...',
      ['get_new_location'] = 'Get New Garbage Location',
      ['location_failed'] = 'Failed to get current location, selecting new random location',
      ['zone_creation_failed'] = 'Failed to create new zone, selecting new location',
      ['forcing_new_zone'] = 'Forcing new garbage zone creation...',
      ['must_be_on_duty'] = 'You must be on duty as a garbage collector to use this command',
      
      -- Team-related locale strings
      ['team_created'] = 'You have created a garbage collection team. Share your team code: %s',
      ['team_joined'] = 'You have joined a garbage collection team',
      ['team_full'] = 'This team is already full',
      ['team_not_found'] = 'Team not found',
      ['team_leader_left'] = 'The team leader has left, the job has been aborted',
      ['team_member_left'] = '%s has left the team',
      ['team_member_joined'] = '%s has joined the team',
      ['enter_team_code'] = 'Enter Team Code',
      ['join_team'] = 'Join Team',
      ['create_team'] = 'Create Team',
      ['team_payment'] = 'You received $%s as a team member',
      ['team_leader_payment'] = 'You received $%s as the team leader',
      ['team_already_in'] = 'You are already in a team',
      ['team_leader_only'] = 'Only the team leader can do this',
      ['team_code'] = 'Team Code: %s',
      ['team_members'] = 'Team Members',
      ['team_leader'] = 'Leader',
      ['team_member'] = 'Member',
      ['team_management'] = 'Team Management',
      ['view_team'] = 'View Team',
      ['leave_team'] = 'Leave Team',
      ['disband_team'] = 'Disband Team',
      ['wait_for_leader'] = 'Wait for Leader',
      ['leader_must_start'] = 'The team leader must start the job',
      ['team_truck_marked'] = 'Your team\'s garbage truck is marked on your map',
      ['team_work_alone'] = 'Work Alone',
      ['team_work_friends'] = 'Work With Friends',
      ['invalid_team_code'] = 'Invalid team code format',
      ['team_disbanded'] = 'You have disbanded your team',
      ['team_left'] = 'You have left the team',
      ['team_share_code'] = 'Share this code with friends to let them join',
      ['team_copy_code'] = 'Team code copied to clipboard',
      ['team_current_members'] = 'Current team members',
      ['team_job_started'] = 'Team job has started',
      ['team_job_ended'] = 'Team job has ended',
      ['team_job_aborted'] = 'Team job has been aborted',
      ['team_payment_received'] = 'Team payment received',
      ['team_payment_distributed'] = 'Payment has been distributed to all team members',
      ['team_vehicle_location'] = 'Team vehicle location',
      ['team_follow_leader'] = 'Follow your team leader',
      ['team_waiting_members'] = 'Waiting for team members',
      ['team_ready_start'] = 'Ready to start the job',
      ['create_new_team'] = 'Create a new team as the leader',
      ['join_existing_team'] = 'Join an existing team with a code',
      ['team_code_label'] = 'Team Code',
      ['team_code_description'] = 'Enter the 6-letter team code',
      ['team_garbage_truck'] = 'Team Garbage Truck',
      ['team_functionality'] = 'Team functionality requires ox_lib',
      
      -- Context menu translations
      ['context_title'] = 'Garbage Job',
      ['context_start_work'] = 'Start Work',
      ['context_start_desc'] = 'Start working as a garbage collector',
      ['context_work_alone'] = 'Work Alone',
      ['context_work_alone_desc'] = 'Start working as a garbage collector',
      ['context_work_friends'] = 'Work With Friends',
      ['context_work_friends_desc'] = 'Start working as a garbage collector',
      ['context_finish_work'] = 'Finish Work',
      ['context_finish_desc'] = 'End your shift and get paid',
      ['context_abort'] = 'Abort Job',
      ['context_abort_desc'] = 'Cancel your current job'
  },

  ['fi'] = {
      ['collect_bag'] = 'Kerää roskapussi',
      ['put_bag'] = 'Laita roskapussi ajoneuvoon',
      ['clock_in'] = 'Aloita työvuoro',
      ['clock_out'] = 'Lopeta työvuoro',
      ['clocked_in'] = 'Aloitit työvuoron ja ajoneuvo on käyttövalmis.',
      ['clocked_out'] = 'Lopetit työvuoron ja ajoneuvo palautettiin.',
      ['max_bags'] = 'Olet kerännyt maksimi määrän pusseja, mene pomon luo saadaksesi palkkaa.',
      ['collecting_bag'] = 'Kerätään roskapussia',
      ['putting_bag'] = 'Laitetaan roskapussia ajoneuvoon',
      ['clocking_in'] = 'Kirjaudutaan sisään',
      ['clocking_out'] = 'Kirjaudutaan ulos',
      ['pay_received'] = 'Sait $%s kerätyistä pusseista.',
      ['no_pay_received'] = 'Et kerännyt yhtään pussia, etkä saanut palkkaa.',
      ['garbage_job'] = 'Roskakuski',
      ['talk_to_boss'] = 'Puhu Pomolle',
      ['not_enough_money'] = 'Sinulla ei ole tarpeeksi rahaa vuokrataksesi ajoneuvon.',
      ['rent_success'] = 'Vuokrasit ajoneuvon.',
      ['vehicle_spawn_failed'] = 'Ajoneuvon luonti epäonnistui',
      ['go_to_area'] = 'Mene merkitylle alueelle ja kerää roskapusseja.',
      ['no_locations'] = 'Ei määritettyjä roskalokaatioita.',
      ['job_aborted'] = 'Työ peruutettu. Ei palkkaa.',
      ['payment_cooldown'] = 'Sinun täytyy odottaa ennen seuraavaa palkkaa.',
      ['bags_collected_msg'] = 'Keräsit %d roskapussia.',
      ['bags_deposited_msg'] = 'Laitoit %d roskapussia ajoneuvoon.',
      ['bin_empty'] = 'Tämä roskis on tyhjä.',
      ['marked_bins_only'] = 'Voit kerätä roskia vain merkityistä roskiksista.',
      ['bags_collected'] = 'Kerätyt pussit',
      ['estimated_pay'] = 'Arvioitu palkka',
      ['rental_cost'] = 'Vuokrahinta',
      ['all_bins_empty'] = 'Kaikki alueen roskikset ovat tyhjiä. Uusi alue on merkitty kartallesi.',
      ['new_zone'] = 'Uusi Roskakuskialue',
      ['new_zone_creating'] = 'Luodaan uutta roskakuskialuetta...',
      ['get_new_location'] = 'Hanki uusi roskakuskialue',
      ['location_failed'] = 'Nykyisen sijainnin haku epäonnistui, valitaan uusi satunnainen sijainti',
      ['zone_creation_failed'] = 'Uuden alueen luominen epäonnistui, valitaan uusi sijainti',
      ['forcing_new_zone'] = 'Pakotetaan uuden roskakuskialueen luominen...',
      ['must_be_on_duty'] = 'Sinun täytyy olla työvuorossa käyttääksesi tätä komentoa',

      -- Team-related locale strings
      ['team_created'] = 'Luoit roskankeräystiimin. Jaa koodi: %s',
      ['team_joined'] = 'Liityit tiimiin',
      ['team_full'] = 'Tiimi on jo täynnä',
      ['team_not_found'] = 'Tiimiä ei löytynyt',
      ['team_leader_left'] = 'Tiimin johtaja poistui, työ peruttiin',
      ['team_member_left'] = '%s poistui tiimistä',
      ['team_member_joined'] = '%s liittyi tiimiin',
      ['enter_team_code'] = 'Syötä tiimikoodi',
      ['join_team'] = 'Liity tiimiin',
      ['create_team'] = 'Luo tiimi',
      ['team_payment'] = 'Sait $%s tiimin jäsenenä',
      ['team_leader_payment'] = 'Sait $%s tiimin johtajana',
      ['team_already_in'] = 'Olet jo tiimissä',
      ['team_leader_only'] = 'Vain tiimin johtaja voi tehdä tämän',
      ['team_code'] = 'Tiimikoodi: %s',
      ['team_members'] = 'Tiimin jäsenet',
      ['team_leader'] = 'Johtaja',
      ['team_member'] = 'Jäsen',
      ['team_management'] = 'Tiimin hallinta',
      ['view_team'] = 'Näytä tiimi',
      ['leave_team'] = 'Poistu tiimistä',
      ['disband_team'] = 'Hajota tiimi',
      ['wait_for_leader'] = 'Odotetaan johtajaa',
      ['leader_must_start'] = 'Johtajan on aloitettava työ',
      ['team_truck_marked'] = 'Tiiminne roska-auto on merkitty kartalle',
      ['team_work_alone'] = 'Työskentele yksin',
      ['team_work_friends'] = 'Työskentele ystävien kanssa',
      ['invalid_team_code'] = 'Virheellinen tiimikoodi',
      ['team_disbanded'] = 'Hajotit tiimin',
      ['team_left'] = 'Poistuit tiimistä',
      ['team_share_code'] = 'Jaa tämä koodi ystävillesi, jotta he voivat liittyä',
      ['team_copy_code'] = 'Tiimikoodi kopioitu leikepöydälle',
      ['team_current_members'] = 'Nykyiset tiimin jäsenet',
      ['team_job_started'] = 'Tiimityö on alkanut',
      ['team_job_ended'] = 'Tiimityö on päättynyt',
      ['team_job_aborted'] = 'Tiimityö on keskeytetty',
      ['team_payment_received'] = 'Tiimipalkka vastaanotettu',
      ['team_payment_distributed'] = 'Palkka on jaettu kaikille tiimin jäsenille',
      ['team_vehicle_location'] = 'Tiimin ajoneuvon sijainti',
      ['team_follow_leader'] = 'Seuraa tiiminjohtajaa',
      ['team_waiting_members'] = 'Odotetaan tiimin jäseniä',
      ['team_ready_start'] = 'Valmiina aloittamaan työn',
      ['create_new_team'] = 'Luo uusi tiimi johtajana',
      ['join_existing_team'] = 'Liity olemassa olevaan tiimiin koodilla',
      ['team_code_label'] = 'Tiimikoodi',
      ['team_code_description'] = 'Syötä 6-kirjaiminen tiimikoodi',
      ['team_garbage_truck'] = 'Tiimin roska-auto',
      ['team_functionality'] = 'Tiimitoiminnallisuus vaatii ox_lib',
      
      -- Context menu translations
      ['context_title'] = 'Roskakuski',
      ['context_start_work'] = 'Aloita työ',
      ['context_start_desc'] = 'Aloita työskentely roskakuskina',
      ['context_work_alone'] = 'Työskentele yksin',
      ['context_work_alone_desc'] = 'Aloita työskentely roskakuskina',
      ['context_work_friends'] = 'Työskentele ystävien kanssa',
      ['context_work_friends_desc'] = 'Aloita työskentely roskakuskina',
      ['context_finish_work'] = 'Lopeta työ',
      ['context_finish_desc'] = 'Lopeta työvuoro ja saa palkka',
      ['context_abort'] = 'Keskeytä työ',
      ['context_abort_desc'] = 'Peruuta nykyinen työ'
  }
}

-- Function to get localized text
function Config.GetLocale(key)
  return Config.Locales[Config.Language][key] or key
end

-- Job Config
Config.RequireJob = false  -- Set to true if you want to require a specific job to do garbage collection
Config.Job = 'garbage'     -- Job name required if Config.RequireJob is true
Config.RentalCost = 300    -- Cost to rent the garbage truck

-- Payment Config
Config.PayPerBag = 20      -- Amount paid per bag collected
Config.MaxBags = 25        -- Maximum number of bags that can be collected before payment
Config.MaxPaymentPerRound = Config.MaxBags * Config.PayPerBag -- Pre-computed max payment

-- Vehicle Config
Config.VehicleModel = 'trash'  -- Vehicle model to spawn for garbage collection
Config.VehicleHash = GetHashKey('trash') -- Pre-computed hash for faster comparison
Config.VehicleSpawn = vector4(-324.4425, -1523.8933, 27.2586, 266.4719)  -- Location where vehicle spawns (x, y, z, heading)

-- Location & Blip Config
Config.JobClock = vector3(-322.2470, -1545.8246, 31.0199)  -- Location of the job clock-in/out point
Config.Blip = {
  Show = true,           -- Whether to show the job blip on the map
  Sprite = 318,          -- Blip sprite ID (318 is a garbage truck)
  Color = 25,            -- Blip color (25 is light green)
  Scale = 0.8,           -- Blip size
}

-- NPC Config
Config.NPC = {
  Model = "s_m_y_garbage",  -- NPC model
  Coords = vector4(-322.2470, -1545.8246, 31.0199, 265.7856),  -- NPC position and heading
  Scenario = "WORLD_HUMAN_CLIPBOARD",  -- Animation scenario for the NPC
}

-- Prop Config
Config.BagProp = GetHashKey("prop_cs_street_binbag_01") -- Pre-computed hash for faster loading

-- Anti-Exploit Config
Config.AntiExploit = {
  PaymentCooldown = 60,  -- Minimum time (in seconds) between payments
  MaxPaymentPerRound = Config.MaxBags * Config.PayPerBag, -- Maximum payment allowed per round
}

-- Team Work Configuration
Config.TeamWork = {
  Enabled = true,           -- Enable team work functionality
  MaxTeamSize = 4,          -- Maximum number of players in a team
  PaymentDistribution = {   -- How payment is distributed in a team
      Leader = 1.0,         -- Leader gets 100% of normal pay
      Member = 0.8          -- Members get 80% of normal pay
  }
}

-- Context Menu Config (using localized strings)
Config.Context = {
  Title = 'context_title',
  ClockIn = {
      Title = 'context_start_work',
      Description = 'context_start_desc',
      Icon = 'fa-solid fa-trash',
  },
  ClockInAlone = {
      Title = 'context_work_alone',
      Description = 'context_work_alone_desc',
      Icon = 'fa-solid fa-user',
  },
  ClockInTeam = {
      Title = 'context_work_friends',
      Description = 'context_work_friends_desc',
      Icon = 'fa-solid fa-users',
  },
  ClockOut = {
      Title = 'context_finish_work',
      Description = 'context_finish_desc',
      Icon = 'fa-solid fa-money-bill',
  },
  Abort = {
      Title = 'context_abort',
      Description = 'context_abort_desc',
      Icon = 'fa-solid fa-xmark',
  }
}

-- Dumpster Models Config (using hashes for faster comparison)
Config.Models = {
  GetHashKey('prop_dumpster_01a'),
  GetHashKey('prop_dumpster_02a'),
  GetHashKey('prop_dumpster_02b'),
  GetHashKey('prop_dumpster_3a'),
  GetHashKey('prop_dumpster_4a'),
  GetHashKey('prop_dumpster_4b'),
  GetHashKey('prop_bin_01a'),
  GetHashKey('prop_bin_02a'),
  GetHashKey('prop_bin_03a'),
  GetHashKey('prop_bin_04a'),
  GetHashKey('prop_bin_05a'),
  GetHashKey('prop_bin_06a'),
  GetHashKey('prop_bin_07a'),
  GetHashKey('prop_bin_07b'),
  GetHashKey('prop_bin_07c'),
  GetHashKey('prop_bin_07d'),
  GetHashKey('prop_bin_08a'),
  GetHashKey('prop_bin_08open'),
  GetHashKey('prop_bin_09a'),
  GetHashKey('prop_bin_10a'),
  GetHashKey('prop_bin_10b'),
  GetHashKey('prop_bin_11a'),
  GetHashKey('prop_bin_11b'),
  GetHashKey('prop_bin_12a'),
  GetHashKey('prop_bin_13a'),
  GetHashKey('prop_bin_14a'),
  GetHashKey('prop_bin_14b'),
  GetHashKey('prop_bin_beach_01a'),
  GetHashKey('prop_bin_beach_01d'),
  GetHashKey('prop_bin_delpiero'),
  GetHashKey('prop_recyclebin_01a'),
  GetHashKey('prop_recyclebin_02_c'),
  GetHashKey('prop_recyclebin_02_d'),
  GetHashKey('prop_recyclebin_02a'),
  GetHashKey('prop_recyclebin_02b'),
  GetHashKey('prop_recyclebin_03_a'),
  GetHashKey('prop_recyclebin_04_a'),
  GetHashKey('prop_recyclebin_04_b'),
  GetHashKey('prop_recyclebin_05_a')
}

-- Zone Creation Config
Config.AutoCreateNewZone = true  -- Automatically create new zones when all bins are empty
Config.BagsPerNewZone = 5        -- This is now only used for periodic checks, not as a direct trigger
Config.UseRandomZones = false    -- If true, creates random zones; if false, uses locations from locations.lua
Config.MaxBinsPerZone = 10       -- Maximum number of bins to create per zone for performance

-- Regarding the Config.Inventory setting:
-- This setting is no longer needed since rewards are given directly as cash
-- However, we'll keep it for backward compatibility or future use
-- You can safely remove or comment out this line if you prefer
Config.Inventory = 'ox' -- Inventory system: 'ox' (ox_inventory) or 'qb' (qb-inventory)
