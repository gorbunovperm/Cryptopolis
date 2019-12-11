pragma solidity 0.4.26;

contract Cryptopolis {
    uint256 private price = 0.001 ether; // 100 CLO
    uint8 public croupierId = 0;
    uint8 constant maxPlayers = 2;
    address owner;

    uint256[1000] public startBlockNumber;
    address[1000] public winner;
    uint256 currentGameId;

    uint8 constant fieldsAmount = 20;
    uint8 constant EMPTY_FIELD_ID = fieldsAmount;
    uint256 constant goPassedReward = 200;
    uint256 constant initialFunds = 1500;
    uint8 constant EMPTY_OWNER = 15;
    uint256 constant buyingRightDuration = 8;

    enum FieldTypes { Empty, Company, TaxOffice, Casino}
    enum ChanceCards { Loss, Win, Teleport }

    uint8[5] private MULTIPLIER_LEVEL = [2, 5, 15, 45, 80];
    uint8 constant chanceCardsAmount = 3;

    uint8 constant TAX_INCREASING_MOVES = 10;
    uint8 public taxLevel = 0;
    uint8 constant TAX_MAX_LEVEL = 10;
    uint8 constant taxIncreasingPercent = 10;
    uint8 private movesMade = 0;

    uint256 constant CHANCE_FEE_AMOUNT = 100;
    uint256 constant CHANCE_REWARD_AMOUNT = 150;
    uint256[fieldsAmount] public buyingRightExpiration;

    mapping(address => uint8) playerNumber;
    mapping(address => string) public names;

    Field[fieldsAmount] private fields;
    Player[maxPlayers] private players;
    uint8 private playersInGame;
    uint8 private playersEntered;

    struct Field {
        int256 payment;
        uint8 owner;
        uint8 level;
        FieldTypes fieldType;
        uint256 price;
        uint8 buyingRight;
    }

    struct Player {
        address addr;
        uint8 position;
        uint256 balance;
        bool inGame;
        uint8 weapon_teleport;
    }

    event PositionChanged(address player, uint8 stepsNumber, uint8 newPosition);
    event BalanceChanged(address player, uint256 newBalance, int256 payment, uint8 fieldId);
    event WeaponsChanged(address player, uint8 weapon_teleport);
    event NewPlayer(address player, uint8 skin, uint256 balance, string name);
    event PlayerLost(address player);
    event FieldUpdated(uint8 fieldId, int256 payment, uint8 owner, uint8 level, FieldTypes fieldType, uint256 price, uint8 buyingRight);
    event CasinoResult(address player, uint8 cardType, uint256 value);
    event croupierChanged(uint8 croupierId);
    event TaxLevelUpdated(uint256 taxPercent);


    constructor() public {
        require(maxPlayers < EMPTY_OWNER);

        owner = msg.sender;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner);
        require(_owner != address(0));

        owner = _owner;
    }

    function constructor2() public {
        require(msg.sender == owner);
        _constructor2();
    }

    function _constructor2() private {
        //require(startBlockNumber.length == winner.length, "Previous game is not finished.");

        startBlockNumber[currentGameId] = block.number;

        taxLevel = 0;
        movesMade = 0;

        fields[0] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Empty, price: 0, buyingRight: EMPTY_OWNER});
        fields[1] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 100, buyingRight: EMPTY_OWNER});
        fields[2] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 110, buyingRight: EMPTY_OWNER});
        fields[3] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 120, buyingRight: EMPTY_OWNER});
        fields[4] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Casino, price: 0, buyingRight: EMPTY_OWNER});
        fields[5] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 110, buyingRight: EMPTY_OWNER});
        fields[6] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 120, buyingRight: EMPTY_OWNER});
        fields[7] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 130, buyingRight: EMPTY_OWNER});
        fields[8] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Casino, price: 0, buyingRight: EMPTY_OWNER});
        fields[9] = Field({payment: 90, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.TaxOffice, price: 0, buyingRight: EMPTY_OWNER});
        fields[10] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 130, buyingRight: EMPTY_OWNER});
        fields[11] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 140, buyingRight: EMPTY_OWNER});
        fields[12] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 150, buyingRight: EMPTY_OWNER});

        fields[13] = Field({payment: 50, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.TaxOffice, price: 0, buyingRight: EMPTY_OWNER});
        fields[14] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Casino, price: 0, buyingRight: EMPTY_OWNER});
        fields[15] = Field({payment: 25, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.TaxOffice, price: 0, buyingRight: EMPTY_OWNER});
        fields[16] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 140, buyingRight: EMPTY_OWNER});
        fields[17] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 150, buyingRight: EMPTY_OWNER});
        fields[18] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Company, price: 160, buyingRight: EMPTY_OWNER});
        fields[19] = Field({payment: 0, owner: EMPTY_OWNER, level: 0, fieldType: FieldTypes.Casino, price: 0, buyingRight: EMPTY_OWNER});

        address plr;
        for (uint256 i = 0; i < players.length; i++) {
            plr = players[i].addr;
            playerNumber[plr] = 0;
        }

        delete players;
        delete buyingRightExpiration;
        delete fields;
        playersEntered = 0;
        playersInGame = 0;
    }

    function() external {
        revert();
    }

    function buyTicket(string memory _name) public payable {
        uint8 number = playerNumber[msg.sender];
        require(number == 0, "You already have a ticket.");
        require(msg.value == price, "The paid amount does not match the ticket price.");
        require(playersEntered < maxPlayers, "All seats are occupied.");
        bytes memory _bytesName = bytes(_name);
        bytes memory bytesName = bytes(names[msg.sender]);
        require(bytesName.length != 0 || _bytesName.length != 0, "You should set your name.");
        if (bytesName.length == 0) {
            names[msg.sender] = _name;
        }

        Player memory p = Player({
            addr: msg.sender,
            position: 0,
            balance: initialFunds,
            inGame: true,
            weapon_teleport: 0
        });
        players[playersEntered] = p;
        playersEntered++;
        playerNumber[msg.sender] = uint8(playersEntered);
        playersInGame++;

        emit NewPlayer(msg.sender, playerNumber[msg.sender] - 1, initialFunds, names[msg.sender]);
    }

    function makeMoves() public {
        require(playersEntered == players.length);
        Field memory field;
        for(uint8 i = 0; i < uint8(buyingRightExpiration.length); i++) {
            if (buyingRightExpiration[i] != 0 && buyingRightExpiration[i] <= block.number) {
                fields[i].buyingRight = EMPTY_OWNER;
                field = fields[i];
                buyingRightExpiration[i] = 0;
                emit FieldUpdated(
                    i, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
            }
        }

        require(players[croupierId].addr == msg.sender, "You're not a croupier.");
        movesMade++;

        for (i = 0; i < uint8(players.length); i++) {
            _makeMove(i);
        }

        croupierId++;
        if (croupierId == players.length) {
            croupierId = 0;
        }
        // TODO: if all players Lost make End of the game
        while(players[croupierId].inGame == false) {
            croupierId++;
            if (croupierId == players.length) {
                croupierId = 0;
            }
        }

        if (movesMade == TAX_INCREASING_MOVES) {
            if (taxLevel < TAX_MAX_LEVEL) {
                taxLevel++;
                _updateFieldsTaxes();
                emit TaxLevelUpdated(100 + uint256(taxLevel) * uint256(taxIncreasingPercent));
            }

            movesMade = 0;
        }

        emit croupierChanged(croupierId);
    }

    function _updateFieldsTaxes() private {
        for(uint8 i = 0; i < uint8(fields.length); i++) {
            if (fields[i].fieldType == FieldTypes.Company) {
                fields[i].payment = _calculateFieldTax(i);
            }
        }
    }

    function _makeMove(uint8 playerId) private {
        Player memory player = players[playerId];
        if (!player.inGame) return;

        uint8 stepsNumber = _countSteps(player.addr);
        uint8 position = players[playerId].position;
        bool goPassed = false;

        position += stepsNumber;
        if (position >= fieldsAmount) {
            position = position - fieldsAmount;
            goPassed = true;
        }
        require(position < fieldsAmount, "A player can't complete the entire game board in 1 turn.");

        if (goPassed) {
            players[playerId].balance += goPassedReward;
            emit BalanceChanged(msg.sender, players[playerId].balance, int256(goPassedReward), 0);
        }

        _arrival(playerId, position);

        emit PositionChanged(player.addr, stepsNumber, players[playerId].position);
    }

    function teleport(uint8 position) public {
        uint8 playerId = playerNumber[msg.sender] - 1;
        Player memory player = players[playerId];
        require(player.weapon_teleport > 0, "You have no teleports.");
        players[playerId].weapon_teleport--;

        emit WeaponsChanged(players[playerId].addr, players[playerId].weapon_teleport);

        _arrival(playerId, position);

        emit PositionChanged(player.addr, 0, players[playerId].position);
    }

    function _arrival(uint8 _playerId, uint8 _position) private {
        players[_playerId].position = _position;
        if(fields[_position].fieldType == FieldTypes.Casino) {
            _getChance(_position, _playerId);
        } else if (fields[_position].owner != _playerId) {
            _payFee(players[_playerId].position, _playerId);
            _changeFieldBuyingRight(players[_playerId].position, _playerId);
        }
    }

    function _changeFieldBuyingRight(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        if (field.fieldType != FieldTypes.Company) return;
        if (field.owner != EMPTY_OWNER) return;
        if (field.buyingRight != EMPTY_OWNER) return;

        field.buyingRight = _playerId;
        buyingRightExpiration[_fieldId] = block.number + buyingRightDuration;
        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
    }

    function _getChance(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        require(field.fieldType == FieldTypes.Casino, "The lottery only works if you stand on the Casino field.");

        uint8 cardNumber = _getChanceCard(player.addr);

        if (cardNumber == uint8(ChanceCards.Loss)) {
            if (int256(player.balance) - int256(CHANCE_FEE_AMOUNT) < 0 &&
            !_sellAssets(_playerId, CHANCE_FEE_AMOUNT)) {
                _playerLost(_playerId);
                emit BalanceChanged(player.addr, player.balance, -int256(CHANCE_FEE_AMOUNT), _fieldId);
            } else {
                players[_playerId].balance -= CHANCE_FEE_AMOUNT;
                emit BalanceChanged(player.addr, player.balance, -int256(CHANCE_FEE_AMOUNT), _fieldId);
            }
            emit CasinoResult(player.addr, uint8(ChanceCards.Loss), CHANCE_FEE_AMOUNT);
        } else if(cardNumber == uint8(ChanceCards.Win)) {
            players[_playerId].balance += CHANCE_REWARD_AMOUNT;
            emit BalanceChanged(player.addr, players[_playerId].balance, int256(CHANCE_REWARD_AMOUNT), _fieldId);
            emit CasinoResult(player.addr, uint8(ChanceCards.Win), CHANCE_REWARD_AMOUNT);
        } else if(cardNumber == uint8(ChanceCards.Teleport)) {
            players[_playerId].weapon_teleport += 1;
            emit WeaponsChanged(player.addr, players[_playerId].weapon_teleport);
            emit CasinoResult(player.addr, uint8(ChanceCards.Teleport), 1);
        }
    }

    function _payFee(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];

        int256 payment = field.payment;

        if (int256(player.balance) - payment < 0 &&
        !_sellAssets(_playerId, uint256(payment))) {
            _playerLost(_playerId);
            emit BalanceChanged(player.addr, player.balance, -payment, _fieldId);
        } else {
            player.balance = uint256(int256(player.balance) - payment);
            emit BalanceChanged(player.addr, player.balance, -payment, _fieldId);

            if (field.owner != EMPTY_OWNER) {
                Player storage fieldOwner = players[field.owner];
                fieldOwner.balance = uint256(int256(fieldOwner.balance) + payment);
                emit BalanceChanged(fieldOwner.addr, fieldOwner.balance, payment, _fieldId);
            }
        }
    }

    function _sellAssets(uint8 _playerId, uint256 _requiredFunds) private returns(bool) {
        Player storage player = players[_playerId];
        uint8 saleFieldId = getPlayerAsset(_playerId);

        while (player.balance < _requiredFunds && saleFieldId != EMPTY_FIELD_ID) {
            _downgradeField(saleFieldId);
            saleFieldId = getPlayerAsset(_playerId);
        }

        if (player.balance >= _requiredFunds) {
            return true;
        }

        return false;
    }

    function getPlayerAsset(uint8 _playerId) public view returns(uint8 fieldId) {
        uint8 i;
        for(uint8 j = uint8(fields.length); j > 0; j--) {
            i = j - 1;
            if (fields[i].owner == _playerId) {
                return i;
            }
        }
        return EMPTY_FIELD_ID;
    }

    function _downgradeField(uint8 _fieldId) private {
        require(_fieldId < fieldsAmount, "Incorrect field ID for sale.");
        Field storage field = fields[_fieldId];
        require(field.owner < players.length, "Incorrect field for sale. Nonexistent owner.");
        Player storage player = players[field.owner];

        if (field.level == 0) {
            field.owner = EMPTY_OWNER;
        } else {
            field.level--;
        }
        field.payment = _calculateFieldTax(_fieldId);

        player.balance += field.price / 2;

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
        emit BalanceChanged(player.addr, player.balance, int256(field.price / 2), _fieldId);
    }

    function _buyField(uint8 _fieldId) private {
        require(playerNumber[msg.sender] > 0, "You are not a member of this party ;)");
        uint8 playerId = playerNumber[msg.sender] - 1;
        Field storage field = fields[_fieldId];
        require(field.buyingRight == playerId, "You don't have rights to buy this field.");

        Player storage player = players[playerId];
        require(player.balance >= field.price, "Not enough funds.");
        if (field.fieldType != FieldTypes.Company) return;
        if (field.owner != EMPTY_OWNER) return;

        field.owner = playerId;
        player.balance -= field.price;
        field.buyingRight = EMPTY_OWNER;
    }

    function buildUp (uint8 _fieldId) public {
        Field storage field = fields[_fieldId];

        require(field.level < 4, "Maximum level of building is 4.");
        Player memory player;

        if(field.owner == EMPTY_OWNER) {
            _buyField(_fieldId);
            player = players[field.owner];
        } else {
            player = players[field.owner];
            require(player.addr == msg.sender, "Only owner of the field can upgrade it.");
            require(player.balance >= field.price, "Not enough funds.");

            players[field.owner].balance -= field.price;
            field.level++;
        }

        field.payment = _calculateFieldTax(_fieldId);

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
        emit BalanceChanged(player.addr, player.balance, -int256(field.price), _fieldId);
    }

    function _calculateFieldTax(uint8 _fieldId) private view returns(int256 tax) {
        Field storage field = fields[_fieldId];
        require(field.fieldType == FieldTypes.Company, "Only Company field need to calculate tax.");
        if (field.owner == EMPTY_OWNER) {
            return 0;
        }

        int256 basePayment = int256(field.price) / 50;
        uint256 multiplier = uint256(MULTIPLIER_LEVEL[field.level]);

        tax = basePayment * int256(multiplier) * int256(100 + taxIncreasingPercent * taxLevel) / 100;
        return tax;
    }

    function _countSteps(address _player) private view returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 12 + 1);
    }

    function _getChanceCard(address _player) private view returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % chanceCardsAmount);
    }

    function _playerLost(uint8 _playerId) private {
        Player memory player = players[_playerId];
        require(player.inGame);

        players[_playerId].inGame = false;
        players[_playerId].balance = 0;
        players[_playerId].position = 0;
        playersInGame--;
        emit PlayerLost(player.addr);

        if (playersInGame == 1) {
            _finishGame();
        }
    }

    function _finishGame() private {
        address winnerAddress;
        for(uint256 i; i < players.length; i++) {
            if (players[i].inGame == true) {
                winnerAddress = players[i].addr;
                break;
            }
        }
        winner[currentGameId] = winnerAddress;
        _constructor2();
    }


    function destruct() public {
        require(msg.sender == owner, "Only the owner can do it.");
        selfdestruct(owner);
    }


    // View functions

    function getPlayersCount() public view returns(uint256) {
        return playersEntered;
    }

    function getPlayer(uint8 _playerId) public view
    returns(address addr, uint256 position, uint256 balance, bool inGame, uint256 weapon_teleport, string memory name) {
        addr = players[_playerId].addr;
        return (addr, players[_playerId].position, players[_playerId].balance,
        players[_playerId].inGame, players[_playerId].weapon_teleport, names[addr]);
    }

    function getFieldsCount() public view returns(uint256) {
        return fieldsAmount;
    }

    function getFields(uint8 _fieldId) public view
    returns(int256 payment, uint8 owner, uint8 level, FieldTypes fieldType, uint256 price, uint8 buyingRight) {
        payment = fields[_fieldId].payment;
        owner = fields[_fieldId].owner;
        level = fields[_fieldId].level;
        fieldType = fields[_fieldId].fieldType;
        price = fields[_fieldId].price;
        buyingRight = fields[_fieldId].buyingRight;
    }
}