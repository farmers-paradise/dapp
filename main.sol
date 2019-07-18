pragma solidity ^0.4.24;

contract FarmVille {
    struct CropStat {
        /// Id for the crop
        uint32 id;

        /// Cost of one seed
        uint64 cost;

        /// Max interval between watering before this crop starts to detoriarate.
        uint64 wateringDuration;

        /// Duration for the crop to be ready to harvest after sowing.
        uint64 growthDuration;

        /// Determines if this struct is initialized.
        bool isInitialized;
    }

    mapping (uint32 => CropStat) cropStats;

    struct Field {
        /// Flat position of the slot
        uint32 pos;

        /// Type of crop currently growing.
        /// 0 if the field is currently empty.
        uint32 crop;

        /// Time at which the crop was sowed.
        /// 0 if the field is currently empty.
        uint256 sowed;

        /// Time at which the crop was watered.
        /// 0 if the field is currently empty.
        uint256 watered;
    }

    /// Player data structure
    struct Player {
        /// Size of the player's property
        uint16 size;

        /// A mapping of slot position to slot data structure
        mapping (uint32 => Field) slots;

        /// A mapping of seedId to amount of seeds in the inventory of that seed type.
        mapping (uint32 => uint128) seedInventory;

        /// Gold coins belonging to the player
        uint256 coins;

        bool isInitialized;
    }

    mapping(address => Player) players;

    /// Purchase given seeds with gold coins
    function purchaseSeeds(uint32 seedId, uint64 amount) external hasPlayer {
        CropStat storage stat = cropStats[seedId];
        assert(stat.isInitialized);

        uint256 cost = amount * stat.cost;

        Player storage player = players[msg.sender];

        assert(player.coins >= cost);

        player.coins -= cost;
        player.seedInventory[seedId] += amount;
    }

    /// Sell seeds for gold coins
    function sellSeeds(uint32 seedId, uint64 amount) external hasPlayer {
        CropStat storage stat = cropStats[seedId];
        assert(stat.isInitialized);

        Player storage player = players[msg.sender];

        // Make sure seeds are present
        assert(player.seedInventory[seedId] >= amount);

        player.seedInventory[seedId] -= amount;
        // TODO should this be based on market demand?
        player.coins += amount * stat.cost;
    }

    /// Sow a crop on the specified field
    function sow(uint32 slot, uint32 seedId) external hasPlayer {
        Player storage player = players[msg.sender];

        // TODO verify slot is present

        // Make sure that the field is empty
        assert(player.slots[slot].crop == 0);

        // Make sure seeds are present
        uint32 amount = 1;  // TODO this can be made varying
        assert(player.seedInventory[seedId] > amount);

        player.seedInventory[seedId] -= 1;

        player.slots[slot].crop = seedId;
        player.slots[slot].sowed = block.timestamp;
        player.slots[slot].watered = block.timestamp;
    }

    /// Water a field
    function water(uint32 slot) external hasPlayer {
        Player storage player = players[msg.sender];

        // TODO verify slot is present

        // Make sure the field has crops
        assert(player.slots[slot].crop != 0);

        // TODO check if the crops have died

        player.slots[slot].watered = block.timestamp;
    }

    /// Harvest a field
    function harvest(uint32 slot) external hasPlayer {
        Player storage player = players[msg.sender];

        // TODO verify slot is present

        // Make sure the field has crops
        assert(player.slots[slot].crop != 0);

        // TODO check if the crops have died

        // TODO check if the crops have rotten

        uint32 seedId = player.slots[slot].crop;
        player.slots[slot].crop = 0;
        player.slots[slot].sowed = 0;
        player.slots[slot].watered = 0;

        uint32 amount = 1;  // TODO make it variable based on quality of the yield
        player.seedInventory[seedId] += amount;
    }

    constructor() internal {
        // Initialize cropStats
        cropStats[1] = CropStat(1, 1, 1 hours, 2 hours, true);
        cropStats[2] = CropStat(2, 5, 2 hours, 5 hours, true);
    }

    modifier hasPlayer {
        require(players[msg.sender].isInitialized, "Player is not a participant!");
        _;
    }
}