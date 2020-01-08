pragma solidity 0.4.26;

contract Cryptopolis {
    // bitwise operations
    uint8 constant PRICE_MASK = 15; // 00001111
    uint8 constant TYPE_MASK = 240; // 11110000

    uint256 private price = 1 ether; // 1 CLO
    uint8 public croupierId;
    uint256 public croupierExpiration;
    address owner;

    uint256[1000] public startBlockNumber;
    address[1000] public winner;
    uint256 public currentGameId;

    uint8 constant fieldsAmount = 50;
    uint8 constant maxPlayers = 3;
    uint256 constant buyingRightDuration = 8;
    uint8 constant CROUPIER_DURATION = 6;
    uint256 constant CROUPIER_PENALTY = 50;
    uint256 constant BLOCKS_TO_REGISTER = 40;
    uint8 constant MIN_FIELD_PRICE = 100;
    uint8 constant MAX_FIELD_LEVEL = 4;

    uint256 constant newRoundReward = 200;
    uint256 constant initialFunds = 1500;
    uint8 constant EMPTY_OWNER = 0;
    uint256 constant GAME_FEE = 10;
    uint8 constant chanceCardsAmount = 3;
    uint8 constant TAX_INCREASING_MOVES = 5;
    uint8 constant TAX_MAX_LEVEL = 10;
    uint8 constant taxIncreasingPercent = 10;
    uint256 constant CHANCE_FEE_AMOUNT = 100;
    uint256 constant CHANCE_REWARD_AMOUNT = 150;

    enum FieldTypes { Empty, Company_0, Company_1, Company_2, Company_3, Company_4, TaxOffice, Casino }
    enum ChanceCards { Loss, Win, Teleport }
    enum Reason { CroupierPenalty, FieldSettlement, NewRound, Upgrade, Downgrade, FieldAcquisition, CasinoLosing, CasinoWinning }

    uint8 public taxLevel = 0;
    uint8 private movesMade = 0;

    uint256[fieldsAmount] public buyingRightExpiration;

    mapping(address => uint8) playerNumber;
    mapping(address => string) public names;

    Field[fieldsAmount] private fields;
    Player[maxPlayers] private players;
    uint8 private playersInGame;
    uint8 public playersEntered;
    uint256 lastEnteredBlock;

    struct Field {
        uint16 payment;
        uint8 owner; // Player Number
        // Field type plus price field plus level. Tree in one — in order to save memory.
        uint8 typeAndPrice;
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
    event BalanceChanged(address player, uint256 newBalance, int256 payment, uint8 fieldId, Reason reason);
    event WeaponsChanged(address player, uint8 weapon_teleport);
    event NewPlayer(address player, uint8 skin, uint256 balance, string name);
    event PlayerLost(address player);
    event FieldUpdated(uint8 fieldId, uint16 payment, uint8 owner, uint8 level, uint8 fieldType, uint256 price, uint8 buyingRight);
    event CasinoResult(address player, uint8 cardType, uint256 value);
    event croupierChanged(uint8 croupierId);
    event TaxLevelUpdated(uint256 taxPercent);
    event Penalty(uint8 playerId);

    function getFieldPrice(uint8 _fieldId) public view returns(uint8) {
        uint8 typeAndPrice = fields[_fieldId].typeAndPrice;
        // from 0 to 15
        uint8 price = typeAndPrice & PRICE_MASK;
        // from 100 to 250
        price = MIN_FIELD_PRICE + (price * 10);
        return price;
    }

    function getFieldType(uint8 _fieldId) public view returns(uint8) {
        uint8 typeAndPrice = fields[_fieldId].typeAndPrice;
        uint8 fieldType = typeAndPrice >> 4;
        return fieldType;
    }

    function getFieldLevel(uint8 _fieldId) public view returns(uint8) {
        uint8 fieldType = getFieldType(_fieldId);
        if (fieldType <= uint8(FieldTypes.Company_4) && fieldType > 0) {
            return fieldType - 1;
        } else {
            return 0;
        }
    }

    function _setFieldPrice(uint8 _fieldId, uint8 _price) internal {
        uint8 price = (_price - MIN_FIELD_PRICE) / 10;
        require(price < 16, 'The maximum price value is 250');
        uint8 typeAndPrice = fields[_fieldId].typeAndPrice;
        // clear bits with price
        typeAndPrice = typeAndPrice & TYPE_MASK;
        typeAndPrice = typeAndPrice | price;
        fields[_fieldId].typeAndPrice = typeAndPrice;
    }

    function _setFieldType(uint8 _fieldId, FieldTypes _ft) internal {
        uint8 _fieldType = uint8(_ft);
        require(_fieldType < 16, 'The maximum field type value is 15');
        uint8 typeAndPrice = fields[_fieldId].typeAndPrice;
        // clear bits with type
        typeAndPrice = typeAndPrice & PRICE_MASK;
        uint8 fieldType = _fieldType << 4;
        typeAndPrice = typeAndPrice | fieldType;
        fields[_fieldId].typeAndPrice = typeAndPrice;
    }

    function _setFieldLevel(uint8 _fieldId, uint8 _level) internal {
        require(_level <= MAX_FIELD_LEVEL, 'The maximum field level value is 4');
        uint8 fieldType = getFieldType(_fieldId);
        if (fieldType <= uint8(FieldTypes.Company_4) && fieldType > 0) {
            fieldType = _level + 1;
            _setFieldType(_fieldId, FieldTypes(fieldType));
        } else {
            revert();
        }
    }



    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner);
        require(_owner != address(0));

        owner = _owner;
    }

    function constructor2() public {
        require(msg.sender == owner);
        _constructor(0);
    }

    function _constructor(uint8 _step) public {
        require(msg.sender == owner);
        //require(startBlockNumber.length == winner.length, "Previous game is not finished.");
        if (_step == 0) {
            startBlockNumber[currentGameId] = block.number;
            delete fields;
            delete buyingRightExpiration;

            _removeAllPlayers();

            taxLevel = 0;
            movesMade = 0;
            require(fields.length > 0);
        } else if (_step == 1) {
            _setFieldType(0, FieldTypes.Empty);

            _setFieldType(1, FieldTypes.Company_0);
            _setFieldType(2, FieldTypes.Company_0);
            _setFieldType(3, FieldTypes.Company_0);

            _setFieldPrice(1, 100);
            _setFieldPrice(2, 110);
            _setFieldPrice(3, 120);
            _setFieldPrice(5, 100);
            _setFieldPrice(6, 110);
            _setFieldPrice(7, 120);
            _setFieldPrice(10, 100);
            _setFieldPrice(11, 110);
            _setFieldPrice(12, 120);
            _setFieldPrice(16, 100);
            _setFieldPrice(17, 110);
            _setFieldPrice(18, 120);
            _setFieldPrice(21, 100);
            _setFieldPrice(22, 110);
            _setFieldPrice(23, 120);
            _setFieldPrice(26, 100);
            _setFieldPrice(27, 110);
            _setFieldPrice(28, 120);
            _setFieldPrice(31, 100);
            _setFieldPrice(32, 110);
            _setFieldPrice(33, 120);
            _setFieldPrice(36, 100);
            _setFieldPrice(37, 110);
            _setFieldPrice(38, 120);
            _setFieldPrice(41, 100);
            _setFieldPrice(42, 110);
            _setFieldPrice(43, 120);
            _setFieldPrice(46, 100);
            _setFieldPrice(47, 110);
            _setFieldPrice(48, 120);

            _setFieldType(4, FieldTypes.Casino);
            _setFieldType(8, FieldTypes.Casino);

            _setFieldType(5, FieldTypes.Company_0);
            _setFieldType(6, FieldTypes.Company_0);
            _setFieldType(7, FieldTypes.Company_0);


            _setFieldType(9, FieldTypes.TaxOffice);
            fields[9].payment = 90;

            _setFieldType(10, FieldTypes.Company_0);
            _setFieldType(11, FieldTypes.Company_0);
            _setFieldType(12, FieldTypes.Company_0);

            _setFieldType(13, FieldTypes.TaxOffice);
            fields[13].payment = 50;

            _setFieldType(14, FieldTypes.Casino);

            _setFieldType(15, FieldTypes.TaxOffice);
            fields[15].payment = 25;

            _setFieldType(16, FieldTypes.Company_0);
            _setFieldType(17, FieldTypes.Company_0);
            _setFieldType(18, FieldTypes.Company_0);

            _setFieldType(19, FieldTypes.Casino);
            _setFieldType(20, FieldTypes.Casino);

            _setFieldType(21, FieldTypes.Company_0);
            _setFieldType(22, FieldTypes.Company_0);
            _setFieldType(23, FieldTypes.Company_0);

            _setFieldType(24, FieldTypes.Casino);

            _setFieldType(25, FieldTypes.TaxOffice);
            fields[25].payment = 30;

            _setFieldType(26, FieldTypes.Company_0);
            _setFieldType(27, FieldTypes.Company_0);
            _setFieldType(28, FieldTypes.Company_0);


            _setFieldType(29, FieldTypes.TaxOffice);
            fields[29].payment = 25;

            _setFieldType(30, FieldTypes.Casino);

            _setFieldType(31, FieldTypes.Company_0);
            _setFieldType(32, FieldTypes.Company_0);
            _setFieldType(33, FieldTypes.Company_0);

            _setFieldType(34, FieldTypes.Casino);

            _setFieldType(35, FieldTypes.TaxOffice);
            fields[35].payment = 30;

            _setFieldType(36, FieldTypes.Company_0);
            _setFieldType(37, FieldTypes.Company_0);
            _setFieldType(38, FieldTypes.Company_0);

            _setFieldType(39, FieldTypes.TaxOffice);
            fields[39].payment = 25;

            _setFieldType(40, FieldTypes.Casino);

            _setFieldType(41, FieldTypes.Company_0);
            _setFieldType(42, FieldTypes.Company_0);
            _setFieldType(43, FieldTypes.Company_0);

            _setFieldType(44, FieldTypes.Casino);

            _setFieldType(45, FieldTypes.TaxOffice);
            fields[45].payment = 30;

            _setFieldType(46, FieldTypes.Company_0);
            _setFieldType(47, FieldTypes.Company_0);
            _setFieldType(48, FieldTypes.Company_0);

            _setFieldType(49, FieldTypes.TaxOffice);
            fields[49].payment = 25;
        }

        if (playersEntered == maxPlayers) {
            croupierId = 0;
            croupierExpiration = block.number + CROUPIER_DURATION;
        }
    }

    function() external {
        revert();
    }

    function _removeAllPlayers() private {
        address addr;
        for (uint256 i = 0; i < players.length; i++) {
            addr = players[i].addr;
            playerNumber[addr] = 0;
        }
        delete players;
        playersEntered = 0;
        playersInGame = 0;
        croupierId = 0;
        lastEnteredBlock = 0;
    }

    function buyTicket(string memory _name) public payable {
        if (lastEnteredBlock != 0 && block.number - lastEnteredBlock > BLOCKS_TO_REGISTER) {
            _removeAllPlayers();
        }
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
        playerNumber[msg.sender] = playersEntered;
        playersInGame++;
        lastEnteredBlock = block.number;

        _constructor(playersEntered);

        emit NewPlayer(msg.sender, playerNumber[msg.sender] - 1, initialFunds, names[msg.sender]);
    }

    function makeMoves() public {
        require(playersEntered == players.length, "Not all players in the game.");
        require(playerNumber[msg.sender] > 0, "You're not a player.");
        require(players[croupierId].addr == msg.sender || croupierExpiration < block.number, "You're not a croupier.");

        if (croupierExpiration < block.number) {
            _penalty(croupierId);

            if(players[croupierId].addr != msg.sender) {
                croupierId = playerNumber[msg.sender] - 1;
                croupierExpiration = block.number + CROUPIER_DURATION;
                emit croupierChanged(croupierId);
            }
        }
        require(players[croupierId].inGame == true || playersInGame == 1, "You're not in the game.");

        if (playersInGame == 1) {
            _finishGame();
            return;
        }
        Field memory field;
        for(uint8 i = 0; i < uint8(buyingRightExpiration.length); i++) {
            if (buyingRightExpiration[i] != 0 && buyingRightExpiration[i] <= block.number) {
                fields[i].buyingRight = EMPTY_OWNER;
                field = fields[i];
                buyingRightExpiration[i] = 0;
                emit FieldUpdated(
                    i, field.payment, field.owner, getFieldLevel(i), getFieldType(i), getFieldPrice(i), field.buyingRight);
            }
        }

        movesMade++;

        for (i = 0; i < uint8(players.length); i++) {
            _makeMove(i);
        }

        croupierId++;
        if (croupierId == players.length) {
            croupierId = 0;
        }
        while(players[croupierId].inGame == false) {
            croupierId++;
            if (croupierId == players.length) {
                croupierId = 0;
            }
        }
        croupierExpiration = block.number + CROUPIER_DURATION;

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

    function _penalty(uint8 _playerId) private {
        _makePayment(_playerId, CROUPIER_PENALTY, 0, Reason.CroupierPenalty);
        emit Penalty(_playerId);
    }

    function _makePayment(uint8 _playerId, uint256 _paymentAmount, uint8 _fieldId, Reason _reason) private {
        if (_paymentAmount == 0) {
            return;
        }
        Player storage player = players[_playerId];

        // making payment
        uint256 madePaymentAmount = 0;
        if (player.balance - _paymentAmount > player.balance &&
        !_sellAssets(_playerId, _paymentAmount)) {
            madePaymentAmount = player.balance;
            _playerLost(_playerId);
        } else {
            madePaymentAmount = _paymentAmount;
            player.balance -= _paymentAmount;
        }
        emit BalanceChanged(player.addr, player.balance, -int256(madePaymentAmount), _fieldId, _reason);

        // receiving funds
        if (_reason == Reason.FieldSettlement && fields[_fieldId].owner != EMPTY_OWNER) {
            uint8 fieldOwnerNumber = fields[_fieldId].owner;
            Player storage fieldOwner = players[fieldOwnerNumber - 1];
            fieldOwner.balance += madePaymentAmount;
            emit BalanceChanged(fieldOwner.addr, fieldOwner.balance, int256(madePaymentAmount), _fieldId, _reason);
        }
    }

    function _updateFieldsTaxes() private {
        for(uint8 i = 0; i < uint8(fields.length); i++) {
            // TODO: isCompany()
            if (getFieldType(i) <= uint8(FieldTypes.Company_4)) {
                fields[i].payment = _calculateFieldTax(i);
            }
        }
    }

    function _makeMove(uint8 playerId) private {
        Player memory player = players[playerId];
        if (!player.inGame) return;

        uint8 stepsNumber = _countSteps(player.addr);
        uint8 position = players[playerId].position;
        bool startPassed = false;

        position += stepsNumber;
        if (position >= fieldsAmount) {
            position = position - fieldsAmount;
            startPassed = true;
        }
        require(position < fieldsAmount, "A player can't complete the entire game board in 1 turn.");

        if (startPassed) {
            players[playerId].balance += newRoundReward;
            emit BalanceChanged(players[playerId].addr, players[playerId].balance, int256(newRoundReward), 0, Reason.NewRound);
        }

        _arrival(playerId, position);

        emit PositionChanged(player.addr, stepsNumber, players[playerId].position);
    }

    function teleport(uint8 position) public {
        uint8 playerId = playerNumber[msg.sender] - 1;
        require(playerId < players.length);
        Player memory player = players[playerId];
        require(player.weapon_teleport > 0, "You have no teleports.");
        players[playerId].weapon_teleport--;

        emit WeaponsChanged(players[playerId].addr, players[playerId].weapon_teleport);

        _arrival(playerId, position);

        emit PositionChanged(player.addr, 0, players[playerId].position);
    }

    function _arrival(uint8 _playerId, uint8 _position) private {
        players[_playerId].position = _position;
        if(getFieldType(_position) == uint8(FieldTypes.Casino)) {
            _getChance(_position, _playerId);
        } else if (fields[_position].owner != _playerId + 1) {
            _makePayment(_playerId, uint256(fields[_position].payment), _position, Reason.FieldSettlement);
            _changeFieldBuyingRight(players[_playerId].position, _playerId);
        }
    }

    function _changeFieldBuyingRight(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        uint8 fieldType = getFieldType(_fieldId);
        // TODO: isCompany()
        if (fieldType > uint8(FieldTypes.Company_4) || fieldType == 0) return;
        if (field.owner != EMPTY_OWNER) return;
        if (field.buyingRight != EMPTY_OWNER) return;

        field.buyingRight = _playerId + 1;
        buyingRightExpiration[_fieldId] = block.number + buyingRightDuration;
        emit FieldUpdated(
            _fieldId, field.payment, field.owner, getFieldLevel(_fieldId), fieldType, getFieldPrice(_fieldId), field.buyingRight);
    }

    function _getChance(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        require(getFieldType(_fieldId) == uint8(FieldTypes.Casino), "The lottery only works if you stand on the Casino field.");

        uint8 cardNumber = _getChanceCard(player.addr);

        if (cardNumber == uint8(ChanceCards.Loss)) {
            _makePayment(_playerId, CHANCE_FEE_AMOUNT, _fieldId, Reason.CasinoLosing);
            emit CasinoResult(player.addr, uint8(ChanceCards.Loss), CHANCE_FEE_AMOUNT);
        } else if(cardNumber == uint8(ChanceCards.Win)) {
            players[_playerId].balance += CHANCE_REWARD_AMOUNT;
            emit BalanceChanged(player.addr, players[_playerId].balance, int256(CHANCE_REWARD_AMOUNT), _fieldId, Reason.CasinoWinning);
            emit CasinoResult(player.addr, uint8(ChanceCards.Win), CHANCE_REWARD_AMOUNT);
        } else if(cardNumber == uint8(ChanceCards.Teleport)) {
            players[_playerId].weapon_teleport += 1;
            emit WeaponsChanged(player.addr, players[_playerId].weapon_teleport);
            emit CasinoResult(player.addr, uint8(ChanceCards.Teleport), 1);
        }
    }

    function _sellAssets(uint8 _playerId, uint256 _requiredFunds) private returns(bool) {
        Player storage player = players[_playerId];

        for (uint8 i = uint8(fields.length - 1); i < uint8(fields.length); i--) {
            if (fields[i].owner == _playerId + 1) {
                while (player.balance < _requiredFunds && fields[i].owner != EMPTY_OWNER) {
                    _downgradeField(i);
                }

                if (player.balance >= _requiredFunds) {
                    return true;
                }
            }
        }

        return false;
    }

    function _downgradeField(uint8 _fieldId) private {
        require(_fieldId < fieldsAmount, "Incorrect field ID for sale.");
        Field storage field = fields[_fieldId];
        require(field.owner <= players.length, "Incorrect field for sale. Nonexistent owner.");
        Player storage player = players[field.owner - 1];
        uint8 level = getFieldLevel(_fieldId);
        if (level == 0) {
            field.owner = EMPTY_OWNER;
        } else {
            _setFieldLevel(_fieldId, level - 1);
        }
        field.payment = _calculateFieldTax(_fieldId);
        uint8 price = getFieldPrice(_fieldId);
        player.balance += price / 2;

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, getFieldLevel(_fieldId), getFieldType(_fieldId), price, field.buyingRight);
        emit BalanceChanged(player.addr, player.balance, int256(price / 2), _fieldId, Reason.Downgrade);
    }

    function _buyField(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        require(field.buyingRight == _playerId + 1, "You don't have rights to buy this field.");

        field.owner = _playerId + 1;
        field.buyingRight = EMPTY_OWNER;
        _makePayment(_playerId, getFieldPrice(_fieldId), _fieldId, Reason.FieldAcquisition);
    }

    function buildUp (uint8 _fieldId) public {

        require(playerNumber[msg.sender] > 0, "You are not a member of this party ;)");
        Field storage field = fields[_fieldId];
        uint8 level = getFieldLevel(_fieldId);
        require(level < MAX_FIELD_LEVEL, "Maximum level of building is 4.");
        uint8 fieldType = getFieldType(_fieldId);
        // TODO: isCompany
        require(fieldType <= uint8(FieldTypes.Company_4), "Only a Company can be upgraded.");

        uint8 number = playerNumber[msg.sender];
        uint8 playerId = number - 1;
        Player memory player = players[playerId];
        uint8 price = getFieldPrice(_fieldId);
        require(player.balance >= price, "Not enough funds.");

        if (field.owner == EMPTY_OWNER) {
            _buyField(_fieldId, playerId);
        } else {
            require(number == field.owner, "Only owner of the field can upgrade it.");
            _makePayment(playerId, price, _fieldId, Reason.Upgrade);
            _setFieldLevel(_fieldId, level + 1);
        }

        field.payment = _calculateFieldTax(_fieldId);

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, getFieldLevel(_fieldId), fieldType, price, field.buyingRight);
    }

    function _calculateFieldTax(uint8 _fieldId) private view returns(uint16 tax) {
        Field storage field = fields[_fieldId];
        // TODO: isCompany
        require(getFieldType(_fieldId) <= uint8(FieldTypes.Company_4), "Only Company field need to calculate tax.");
        if (field.owner == EMPTY_OWNER) {
            return 0;
        }

        //uint256 basePayment = field.price / 50;
        uint256 multiplier = getLevelMultiplier(getFieldLevel(_fieldId));
        uint256 price = uint256(getFieldPrice(_fieldId));

        tax = uint16(price * multiplier * (100 + taxIncreasingPercent * taxLevel) / 100 / 50);
        return tax;
    }

    function _countSteps(address _player) private view returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 6 + 1);
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
    }

    function _finishGame() private {
        address winnerAddress;
        for(uint256 i = 0; i < players.length; i++) {
            if (players[i].inGame == true) {
                winnerAddress = players[i].addr;
                break;
            }
        }
        winner[currentGameId] = winnerAddress;
        uint256 fee = address(this).balance * GAME_FEE / 100;
        uint256 reward = address(this).balance - fee;
        owner.send(fee);
        winnerAddress.send(reward);
        currentGameId++;
        _constructor(0);
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
    returns(uint16 payment, uint8 owner, uint8 level, uint8 fieldType, uint256 price, uint8 buyingRight) {
        payment = fields[_fieldId].payment;
        owner = fields[_fieldId].owner;
        level = getFieldLevel(_fieldId);
        fieldType = getFieldType(_fieldId);
        price = getFieldPrice(_fieldId);
        buyingRight = fields[_fieldId].buyingRight;
    }

    function getLevelMultiplier(uint8 level) public pure returns(uint256) {
        if (level == 0) {
            return 2;
        } else if (level == 1) {
            return 5;
        } else if (level == 2) {
            return 15;
        } else if (level == 3) {
            return 45;
        } else if (level == 4) {
            return 80;
        }
    }
}