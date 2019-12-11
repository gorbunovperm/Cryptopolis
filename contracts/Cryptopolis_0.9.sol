pragma solidity 0.4.26;

contract Cryptopolis {
    uint256 public price = 0.001 ether; // 100 CLO
    uint256 public croupierId = 0;
    uint256 public playersCount = 0;
    uint256 public maxPlayers = 5;
    address public owner;

    uint256 constant fieldsAmount = 39;
    uint256 constant goPassedReward = 200;
    uint256 constant initialFunds = 1000;
    uint256 constant FIELD_EMPTY = 0;
    uint256 constant FIELD_COMPANY = 1;
    uint256 constant FIELD_FEE = 2;
    uint256 constant FIELD_CHANCE = 3;
    uint256 constant EMPTY_OWNER = 15;

    uint256[5] private MULTIPLIER_LEVEL = [2, 5, 15, 45, 80];
    uint256 constant chanceCardsAmount = 10;
    uint256 constant CHANCE_FEE = 0;
    uint256 constant CHANCE_REWARD = 1;
    uint256 constant CHANCE_TELEPORT = 2;
    uint256 constant CHANCE_DIPLOMACY = 3;

    uint256 constant CHANCE_FEE_AMOUNT = 100;
    uint256 constant CHANCE_REWARD_AMOUNT = 150;
    uint256[chanceCardsAmount] private chanceCards;
    uint256[fieldsAmount] public buyingRightExpiration;

    mapping(address => uint256) playerNumber;

    Field[fieldsAmount] public fields;
    Player[] public players;

    struct Field {
        int256 payment;
        uint256 owner;
        uint256 level;
        uint256 fieldType;
        uint256 group;
        uint256 price;
        uint256 buyingRight;
    }

    struct Player {
        address addr;
        uint256 position;
        uint256 balance;
        bool inGame;
        uint256 weapon_teleport;
        uint256 weapon_diplomacy;
    }

    event PositionChanged(address player, uint256 stepsNumber, uint256 newPosition);
    event BalanceChanged(address player, uint256 newBalance);
    event WeaponsChanged(address player, uint256 weapon_teleport, uint256 weapon_diplomacy);
    event NewPlayer(address player, uint256 skin, uint256 balance);
    event PlayerLost(address player);
    event FieldUpdated(uint256 fieldId, int256 payment, uint256 owner, uint256 level, uint256 fieldType,
    uint256 group, uint256 price, uint256 buyingRight);
    event CasinoResult(address player, uint256 cardType, uint256 value);
    event croupierChanged(uint256 croupierId);


    constructor() public {
        require(maxPlayers < EMPTY_OWNER);

        chanceCards = [
            CHANCE_FEE,
            CHANCE_REWARD,
            CHANCE_TELEPORT,
            CHANCE_DIPLOMACY,
            CHANCE_TELEPORT,
            CHANCE_TELEPORT,
            CHANCE_DIPLOMACY,
            CHANCE_FEE,
            CHANCE_FEE,
            CHANCE_REWARD
        ];

        fields[0] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_EMPTY, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[1] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 1, price: 100, buyingRight: EMPTY_OWNER});
        fields[2] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 1, price: 110, buyingRight: EMPTY_OWNER});
        fields[3] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 1, price: 120, buyingRight: EMPTY_OWNER});
        fields[4] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[5] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 2, price: 110, buyingRight: EMPTY_OWNER});
        fields[6] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 2, price: 120, buyingRight: EMPTY_OWNER});
        fields[7] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 2, price: 130, buyingRight: EMPTY_OWNER});
        fields[8] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[9] = Field({payment: -90, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_FEE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[10] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 3, price: 130, buyingRight: EMPTY_OWNER});
        fields[11] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 3, price: 140, buyingRight: EMPTY_OWNER});
        fields[12] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 3, price: 150, buyingRight: EMPTY_OWNER});

        fields[13] = Field({payment: -50, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_FEE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[14] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[15] = Field({payment: -25, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_FEE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[16] = Field({payment: -2, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 4, price: 140, buyingRight: EMPTY_OWNER});
        fields[17] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 4, price: 150, buyingRight: EMPTY_OWNER});
        fields[18] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 4, price: 160, buyingRight: EMPTY_OWNER});
        fields[19] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[20] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[21] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 5, price: 160, buyingRight: EMPTY_OWNER});
        fields[22] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 5, price: 170, buyingRight: EMPTY_OWNER});
        fields[23] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 5, price: 180, buyingRight: EMPTY_OWNER});
        fields[24] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[25] = Field({payment: -30, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_FEE, group: 0, price: 0, buyingRight: EMPTY_OWNER});

        fields[26] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 6, price: 170, buyingRight: EMPTY_OWNER});
        fields[27] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 6, price: 180, buyingRight: EMPTY_OWNER});
        fields[28] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 6, price: 190, buyingRight: EMPTY_OWNER});
        fields[29] = Field({payment: -25, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_FEE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[30] = Field({payment: -3, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 7, price: 190, buyingRight: EMPTY_OWNER});
        fields[31] = Field({payment: -4, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 7, price: 200, buyingRight: EMPTY_OWNER});
        fields[32] = Field({payment: -4, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 7, price: 210, buyingRight: EMPTY_OWNER});
        fields[33] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[34] = Field({payment: -4, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 8, price: 200, buyingRight: EMPTY_OWNER});
        fields[35] = Field({payment: -4, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 8, price: 210, buyingRight: EMPTY_OWNER});
        fields[36] = Field({payment: -4, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_COMPANY, group: 8, price: 220, buyingRight: EMPTY_OWNER});
        fields[37] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0, buyingRight: EMPTY_OWNER});
        fields[38] = Field({payment: -60, owner: EMPTY_OWNER, level: 0, fieldType: FIELD_FEE, group: 0, price: 0, buyingRight: EMPTY_OWNER});

        owner = msg.sender;
    }

    function() private {
    }

    function buyTicket() payable public {
        uint256 number = playerNumber[msg.sender];
        require(number == 0);
        require(msg.value == price);
        require(players.length < maxPlayers);
        Player memory p = Player({
            addr: msg.sender,
            position: 0,
            balance: initialFunds,
            inGame: true,
            weapon_teleport: 0,
            weapon_diplomacy: 0
        });
        players.push(p);
        playerNumber[msg.sender] = players.length;

        emit NewPlayer(msg.sender, playerNumber[msg.sender] - 1, initialFunds);
        emit BalanceChanged(msg.sender, initialFunds);
        emit PositionChanged(msg.sender, 0, 0);
    }

    function makeMoves() public {
        Field memory field;
        for(uint256 i = 0; i < buyingRightExpiration.length; i++) {
            if (buyingRightExpiration[i] <= block.number) {
                fields[i].buyingRight = EMPTY_OWNER;
                field = fields[i];
                emit FieldUpdated(
                    i, field.payment, field.owner, field.level, field.fieldType, field.group, field.price, field.buyingRight);
            }
        }

        require(players[croupierId].addr == msg.sender);

        for (i = 0; i < players.length; i++) {
            _makeMove(i);
        }

        croupierId++;
        if (croupierId == players.length) {
            croupierId = 0;
        }

        emit croupierChanged(croupierId);
    }

    function _makeMove(uint256 playerId) private {
        Player memory player = players[playerId];
        if (!player.inGame) return;

        uint256 stepsNumber = _countSteps(player.addr);
        uint256 position = players[playerId].position;
        bool goPassed = false;

        position += stepsNumber;
        if (position >= fieldsAmount) {
            position = position - fieldsAmount;
            goPassed = true;
        }
        require(position < fieldsAmount, "A player can't complete the entire game board in 1 turn.");
        players[playerId].position = position;

        if (goPassed) {
            players[playerId].balance += goPassedReward;
        }

        if(fields[position].fieldType == FIELD_CHANCE) {
            _getChance(position, playerId);
        }
        _payFee(players[playerId].position, playerId);
        _changeFieldBuyingRight(players[playerId].position, playerId);

        emit PositionChanged(player.addr, stepsNumber, players[playerId].position);
    }

    function _changeFieldBuyingRight(uint256 _fieldId, uint256 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        if (field.fieldType != FIELD_COMPANY) return;
        if (field.buyingRight != EMPTY_OWNER) return;

        field.buyingRight = _playerId;
        buyingRightExpiration[_fieldId] = block.number + 4;
        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.group, field.price, field.buyingRight);
    }

    function _getChance(uint256 _fieldId, uint256 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        require(field.fieldType == FIELD_CHANCE, "The lottery only works if you stand on the Casino field.");

        uint256 cardNumber = _getChanceCard(player.addr);

        if (chanceCards[cardNumber] == CHANCE_FEE) {
            players[_playerId].balance -= CHANCE_FEE_AMOUNT;
            emit BalanceChanged(player.addr, players[_playerId].balance);
            emit CasinoResult(player.addr, CHANCE_FEE, CHANCE_FEE_AMOUNT);
        } else if(chanceCards[cardNumber] == CHANCE_REWARD) {
            players[_playerId].balance += CHANCE_REWARD_AMOUNT;
            emit BalanceChanged(player.addr, players[_playerId].balance);
            emit CasinoResult(player.addr, CHANCE_REWARD, CHANCE_REWARD_AMOUNT);
        } else if(chanceCards[cardNumber] == CHANCE_TELEPORT) {
            players[_playerId].weapon_teleport += 1;
            emit WeaponsChanged(player.addr, players[_playerId].weapon_teleport, players[_playerId].weapon_diplomacy);
            emit CasinoResult(player.addr, CHANCE_TELEPORT, 1);
        } else if(chanceCards[cardNumber] == CHANCE_DIPLOMACY) {
            players[_playerId].weapon_diplomacy += 1;
            emit WeaponsChanged(player.addr, players[_playerId].weapon_teleport, players[_playerId].weapon_diplomacy);
            emit CasinoResult(player.addr, CHANCE_DIPLOMACY, 1);
        }
    }

    function _payFee(uint256 _fieldId, uint256 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        uint256 multiplier = MULTIPLIER_LEVEL[field.level];
        if (field.owner == EMPTY_OWNER) {
            multiplier = 1;
        }

        // Check the payment in the field.
        // TODO: Check this condition.
        if (int256(player.balance) + field.payment >= 0) {
            player.balance = uint256(int256(player.balance) + field.payment * int256(multiplier));
            if (field.owner != EMPTY_OWNER) {
                Player storage fieldOwner = players[field.owner];
                fieldOwner.balance = uint256(int256(fieldOwner.balance) - field.payment * int256(multiplier));

                emit BalanceChanged(fieldOwner.addr, fieldOwner.balance);
            }
        } else {
            // TODO: Should be implemented more behaviours, like sale of buildings.
            _playerLost(_playerId);
        }

        emit BalanceChanged(player.addr, player.balance);
    }

    function _buyField(uint256 _fieldId) private {
        require(playerNumber[msg.sender] > 0, "You are not a member of this party ;)");
        uint256 playerId = playerNumber[msg.sender] - 1;
        Field storage field = fields[_fieldId];
        require(field.buyingRight == playerId, "You don't have rights to buy this field.");

        Player storage player = players[playerId];
        require(player.balance >= field.price, "Not enough funds.");
        if (field.fieldType != FIELD_COMPANY) return;
        if (field.owner != EMPTY_OWNER) return;

        field.owner = playerId;
        player.balance -= field.price;
        field.buyingRight = EMPTY_OWNER;

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.group, field.price, field.buyingRight);
        emit BalanceChanged(player.addr, player.balance);
    }

    function buildUp (uint256 _fieldId) public {
        Field storage field = fields[_fieldId];

        if(field.owner == EMPTY_OWNER) {
            _buyField(_fieldId);
            return;
        }

        Player storage player = players[field.owner];
        require(player.addr == msg.sender, "Only owner of the field can upgrade it.");
        require(player.balance >= field.price, "Not enough funds.");

        player.balance -= field.price;
        field.level++;

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.group, field.price, field.buyingRight);
        emit BalanceChanged(player.addr, player.balance);
    }

    function _countSteps(address _player) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 12 + 1;
    }

    function _getChanceCard(address _player) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 10;
    }

    function _playerLost(uint256 _playerId) public { // private
        Player memory player = players[_playerId];
        require(player.inGame);
        require(players.length != 0);

        //delete players[playersCount] = msg.sender;
        players[_playerId].inGame = false;
        players[_playerId].balance = 0;
        players[_playerId].position = 0;
        emit PlayerLost(player.addr);
    }


    function destruct() public {
        require(msg.sender == owner, "Only the owner can do it.");
        selfdestruct(owner);
    }


    // View functions

    function getPlayersCount() public view returns(uint256) {
        return players.length;
    }

    function getPlayer(uint256 _playerId) public view
    returns(address addr, uint256 position, uint256 balance, bool inGame, uint256 weapon_teleport, uint256 weapon_diplomacy) {
        return (players[_playerId].addr, players[_playerId].position, players[_playerId].balance,
        players[_playerId].inGame, weapon_teleport, weapon_diplomacy);
    }

    function getFieldsCount() public view returns(uint256) {
        return fieldsAmount;
    }

    function getFields(uint256 _fieldId) public view
    returns(int256 payment, uint256 owner, uint256 level, uint256 fieldType, uint256 group, uint256 price, uint256 buyingRight) {
        payment = fields[_fieldId].payment;
        owner = fields[_fieldId].owner;
        level = fields[_fieldId].level;
        fieldType = fields[_fieldId].fieldType;
        group = fields[_fieldId].group;
        price = fields[_fieldId].price;
        buyingRight = fields[_fieldId].buyingRight;
    }

    function debug_position() public view returns(uint256, uint256, uint256, uint256) {
        return (players[0].position, players[1].position, players[2].position, players[3].position);
    }

}