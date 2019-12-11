/*
    Задача:
    * Штраф за не ход.
    * Не обновлять buyingRight каждый ход, расчитывать это во фронте.

    Lines: 566

    Past version:
    Deployment: 4'522'291
    Constructor 0: 256'999
    BuyTicket 1: 499'106
    BuyTicket 2: 523'391

    Desctruct: 14'060
*/

pragma solidity 0.4.26;

contract Cryptopolis {
    uint8 constant CROUPIER_DURATION = 6;
    uint256 constant CROUPIER_PENALTY = 50;

    uint256 private price = 1 ether; // 1 CLO
    uint8 public croupierId;
    uint256 public croupierExpiration;
    uint8 constant maxPlayers = 5;
    address owner;

    uint256[1000] public startBlockNumber;
    address[1000] public winner;
    uint256 currentGameId;

    uint8 constant fieldsAmount = 30;
    uint256 constant newRoundReward = 200;
    uint256 constant initialFunds = 1500;
    uint8 constant EMPTY_OWNER = 0;
    uint256 constant buyingRightDuration = 8;
    uint256 constant GAME_FEE = 5;

    enum FieldTypes { Empty, Company, TaxOffice, Casino}
    enum ChanceCards { Loss, Win, Teleport }
    enum Reason { CroupierPenalty, FieldSettlement, NewRound, Upgrade, Downgrade, FieldAcquisition, CasinoLosing, CasinoWinning }

    uint8 constant chanceCardsAmount = 3;

    uint8 constant TAX_INCREASING_MOVES = 5;
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
        uint256 payment;
        uint8 owner; // Player Number
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
    event BalanceChanged(address player, uint256 newBalance, int256 payment, uint8 fieldId, Reason reason);
    event WeaponsChanged(address player, uint8 weapon_teleport);
    event NewPlayer(address player, uint8 skin, uint256 balance, string name);
    event PlayerLost(address player);
    event FieldUpdated(uint8 fieldId, uint256 payment, uint8 owner, uint8 level, FieldTypes fieldType, uint256 price, uint8 buyingRight);
    event CasinoResult(address player, uint8 cardType, uint256 value);
    event croupierChanged(uint8 croupierId);
    event TaxLevelUpdated(uint256 taxPercent);
    event Penalty(uint8 playerId);


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

    function _constructor(uint8 _step) private {
        //require(startBlockNumber.length == winner.length, "Previous game is not finished.");
        if (_step == 0) {
            startBlockNumber[currentGameId] = block.number;

            address addr;
            for (uint256 i = 0; i < players.length; i++) {
                addr = players[i].addr;
                playerNumber[addr] = 0;
            }

            delete players;
            delete fields;
            delete buyingRightExpiration;

            playersEntered = 0;
            playersInGame = 0;
            croupierId = 0;
            taxLevel = 0;
            movesMade = 0;
        } else if (_step == 1) {
            fields[0].fieldType = FieldTypes.Empty;

            fields[1].fieldType = FieldTypes.Company;
            fields[2].fieldType = FieldTypes.Company;
            fields[3].fieldType = FieldTypes.Company;

            fields[1].price = 100;
            fields[2].price = 110;
            fields[3].price = 120;

            fields[4].fieldType = FieldTypes.Casino;
            fields[8].fieldType = FieldTypes.Casino;

            fields[5].fieldType = FieldTypes.Company;
            fields[6].fieldType = FieldTypes.Company;
            fields[7].fieldType = FieldTypes.Company;

            fields[5].price = 110;
            fields[6].price = 120;
            fields[7].price = 130;

            fields[9].fieldType = FieldTypes.TaxOffice;
            fields[9].payment = 90;

        } else if(_step == 2) {
            fields[10].fieldType = FieldTypes.Company;
            fields[11].fieldType = FieldTypes.Company;
            fields[12].fieldType = FieldTypes.Company;

            fields[10].price = 130;
            fields[11].price = 140;
            fields[12].price = 150;

            fields[13].fieldType = FieldTypes.TaxOffice;
            fields[13].payment = 50;

            fields[14].fieldType = FieldTypes.Casino;

            fields[15].fieldType = FieldTypes.TaxOffice;
            fields[15].payment = 25;

            fields[16].fieldType = FieldTypes.Company;
            fields[17].fieldType = FieldTypes.Company;
            fields[18].fieldType = FieldTypes.Company;

            fields[16].price = 140;
            fields[17].price = 150;
            fields[18].price = 160;

            fields[19].fieldType = FieldTypes.Casino;

            require(fields.length > 0);
            //// debug
            /*fields[1].owner = 1;
            fields[2].owner = 1;
            fields[3].owner = 1;
            fields[5].owner = 1;
            fields[6].owner = 1;
            fields[7].owner = 1;
            fields[10].owner = 1;
            fields[11].owner = 1;
            fields[12].owner = 1;*/
        } else if (_step == 3) {
            fields[20].fieldType = FieldTypes.Casino;

            fields[21].fieldType = FieldTypes.Company;
            fields[22].fieldType = FieldTypes.Company;
            fields[23].fieldType = FieldTypes.Company;

            fields[21].price = 160;
            fields[22].price = 170;
            fields[23].price = 180;

            fields[24].fieldType = FieldTypes.Casino;

            fields[25].fieldType = FieldTypes.TaxOffice;
            fields[25].payment = 30;

            fields[26].fieldType = FieldTypes.Company;
            fields[27].fieldType = FieldTypes.Company;
            fields[28].fieldType = FieldTypes.Company;

            fields[26].price = 170;
            fields[27].price = 180;
            fields[28].price = 190;

            fields[29].fieldType = FieldTypes.TaxOffice;
            fields[29].payment = 25;
        }

        if (playersEntered == maxPlayers) {
            croupierId = 0;
            croupierExpiration = block.number + CROUPIER_DURATION;
        }
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
        playerNumber[msg.sender] = playersEntered;
        playersInGame++;

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
                // Is it necessary here?
                croupierExpiration = block.number + CROUPIER_DURATION;
                emit croupierChanged(croupierId);
            }
        }
        require(players[croupierId].inGame == true, "You're not in the game.");

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
                    i, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
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
        if(fields[_position].fieldType == FieldTypes.Casino) {
            _getChance(_position, _playerId);
        } else if (fields[_position].owner != _playerId + 1) {
            _makePayment(_playerId, fields[_position].payment, _position, Reason.FieldSettlement);
            _changeFieldBuyingRight(players[_playerId].position, _playerId);
        }
    }

    function _changeFieldBuyingRight(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        Player storage player = players[_playerId];
        if (field.fieldType != FieldTypes.Company) return;
        if (field.owner != EMPTY_OWNER) return;
        if (field.buyingRight != EMPTY_OWNER) return;

        field.buyingRight = _playerId + 1;
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

        if (field.level == 0) {
            field.owner = EMPTY_OWNER;
        } else {
            field.level--;
        }
        field.payment = _calculateFieldTax(_fieldId);

        player.balance += field.price / 2;

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
        emit BalanceChanged(player.addr, player.balance, int256(field.price / 2), _fieldId, Reason.Downgrade);
    }

    function _buyField(uint8 _fieldId, uint8 _playerId) private {
        Field storage field = fields[_fieldId];
        require(field.buyingRight == _playerId + 1, "You don't have rights to buy this field.");

        field.owner = _playerId + 1;
        field.buyingRight = EMPTY_OWNER;
        _makePayment(_playerId, field.price, _fieldId, Reason.FieldAcquisition);
    }

    function buildUp (uint8 _fieldId) public {

        require(playerNumber[msg.sender] > 0, "You are not a member of this party ;)");
        Field storage field = fields[_fieldId];
        require(field.level < 4, "Maximum level of building is 4.");
        require(field.fieldType == FieldTypes.Company, "Only a Company can be upgraded.");

        uint8 number = playerNumber[msg.sender];
        uint8 playerId = number - 1;
        Player memory player = players[playerId];
        require(player.balance >= field.price, "Not enough funds.");

        if (field.owner == EMPTY_OWNER) {
            _buyField(_fieldId, playerId);
        } else {
            require(number == field.owner, "Only owner of the field can upgrade it.");
            _makePayment(playerId, field.price, _fieldId, Reason.Upgrade);
            field.level++;
        }

        field.payment = _calculateFieldTax(_fieldId);

        emit FieldUpdated(
            _fieldId, field.payment, field.owner, field.level, field.fieldType, field.price, field.buyingRight);
    }

    function _calculateFieldTax(uint8 _fieldId) private view returns(uint256 tax) {
        Field storage field = fields[_fieldId];
        require(field.fieldType == FieldTypes.Company, "Only Company field need to calculate tax.");
        if (field.owner == EMPTY_OWNER) {
            return 0;
        }

        uint256 basePayment = field.price / 50;
        uint256 multiplier = getLevelMultiplier(field.level);

        tax = basePayment * multiplier * (100 + taxIncreasingPercent * taxLevel) / 100;
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
    returns(uint256 payment, uint8 owner, uint8 level, FieldTypes fieldType, uint256 price, uint8 buyingRight) {
        payment = fields[_fieldId].payment;
        owner = fields[_fieldId].owner;
        level = fields[_fieldId].level;
        fieldType = fields[_fieldId].fieldType;
        price = fields[_fieldId].price;
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