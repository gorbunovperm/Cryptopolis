pragma solidity 0.4.25;

contract Cryptopolis {
    uint256 public price = 0.001 ether; // 100 CLO
    uint256 public croupierId = 0;
    uint256 public playersCount = 0;
    uint256 public maxPlayers = 5;
    address public owner;

    uint256 constant fieldsAmount = 40;
    uint256 constant goPassedReward = 200;
    uint256 constant initialFunds = 1000;
    uint256 constant FIELD_EMPTY = 0;
    uint256 constant FIELD_COMPANY = 1;
    uint256 constant FIELD_FEE = 2;
    uint256 constant FIELD_CHANCE = 3;
    mapping(address => uint256) playerNumber;

    Field[40] public fields;
    Player[] public players;

    struct Field {
        int256 payment;
        uint256 owner;
        uint256 level;
        uint256 fieldType;
        uint256 group;
        uint256 price;
    }

    struct Player {
        address addr;
        uint256 position;
        uint256 balance;
        bool inGame;
    }

    event PositionChanged(address player, uint256 stepsNumber, uint256 newPosition);
    event BalanceChanged(address player, uint256 newBalance);
    event NewPlayer(address player, uint256 skin, uint256 balance);
    event PlayerLost(address player);
    event FieldUpdated(uint256 fieldId, int256 payment, uint256 owner, uint256 level, uint256 fieldType, uint256 group, uint256 price);


    constructor() public {

        fields[0] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_EMPTY, group: 0, price: 0});
        fields[1] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 1, price: 100});
        fields[2] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 1, price: 110});
        fields[3] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 1, price: 120});
        fields[4] = Field({payment: 100, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});
        fields[5] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 2, price: 110});
        fields[6] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 2, price: 120});
        fields[7] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 2, price: 130});
        fields[8] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[9] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});

        fields[10] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 3, price: 130});
        fields[11] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 3, price: 140});
        fields[12] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 3, price: 150});
        fields[13] = Field({payment: -50, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});
        fields[14] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[15] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[16] = Field({payment: 100, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});
        fields[17] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 4, price: 140});
        fields[18] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 4, price: 150});
        fields[19] = Field({payment: -45, owner: 15, level: 2, fieldType: FIELD_COMPANY, group: 4, price: 160});

        fields[20] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[21] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[22] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 5, price: 160});
        fields[23] = Field({payment: -45, owner: 15, level: 1, fieldType: FIELD_COMPANY, group: 5, price: 170});
        fields[24] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 5, price: 180});
        fields[25] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 6, price: 170});
        fields[26] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 6, price: 180});
        fields[27] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 6, price: 190});
        fields[28] = Field({payment: -30, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});
        fields[29] = Field({payment: 100, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});

        fields[30] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 7, price: 190});
        fields[31] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 7, price: 200});
        fields[32] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 7, price: 210});
        fields[33] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[34] = Field({payment: 0, owner: 15, level: 0, fieldType: FIELD_CHANCE, group: 0, price: 0});
        fields[35] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 8, price: 200});
        fields[36] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 8, price: 210});
        fields[37] = Field({payment: -45, owner: 15, level: 0, fieldType: FIELD_COMPANY, group: 8, price: 220});
        fields[38] = Field({payment: -60, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});
        fields[39] = Field({payment: -60, owner: 15, level: 0, fieldType: FIELD_FEE, group: 0, price: 0});

        owner = msg.sender;
    }

    function() payable public {
        emit BalanceChanged(msg.sender, 111);
        emit PositionChanged(msg.sender, 3, 3);
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
            inGame: true});
        players.push(p);
        playerNumber[msg.sender] = players.length;

        emit NewPlayer(msg.sender, playerNumber[msg.sender] - 1, initialFunds);
        emit BalanceChanged(msg.sender, initialFunds);
        emit PositionChanged(msg.sender, 0, 0);
    }

    function makeMoves() public {
        //address croupierAddress = players[croupierId];
        require(players[croupierId].addr == msg.sender);

        for (uint i = 0; i < players.length; i++) {
            _makeMove(i);
        }

        croupierId++;
        if (croupierId == players.length) {
            croupierId = 0;
        }
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
        require(position < fieldsAmount);
        players[playerId].position = position;

        if (goPassed) {
            players[playerId].balance += goPassedReward;
        }

        // Check the payment in the field.
        // TODO: Check this condition.
        if (int256(players[playerId].balance) + fields[position].payment >= 0) {
            players[playerId].balance = uint256(int256(players[playerId].balance) + fields[position].payment);
        } else {
            // TODO: Should be implemented more behaviours, like sale of buildings.
            _playerLost(playerId);
        }

        // TODO: Move it to manual called public method.
        _buyField(players[playerId].position, playerId);

        emit BalanceChanged(player.addr, players[playerId].balance);
        emit PositionChanged(player.addr, stepsNumber, players[playerId].position);
    }

    function _buyField(uint256 _fieldId, uint256 _playerId) private {
        require(players[_playerId].balance >= fields[_fieldId].price, "Not enough funds");

        fields[_fieldId].owner = _playerId;
        players[_playerId].balance -= fields[_fieldId].price;

        emit FieldUpdated(
            _fieldId, fields[_fieldId].payment, fields[_fieldId].owner, fields[_fieldId].level, fields[_fieldId].fieldType, fields[_fieldId].group, fields[_fieldId].price);
    }

    function _countSteps(address _player) public view returns(uint256) { // make Private
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 12;
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

    function getPlayer(uint256 _playerId) public view returns(address addr, uint256 position, uint256 balance, bool inGame) {
        return (players[_playerId].addr, players[_playerId].position, players[_playerId].balance, players[_playerId].inGame);
    }

    function getFieldsCount() public view returns(uint256) {
        return fieldsAmount;
    }

    function getFields(uint256 _fieldId) public view
    returns(int256 payment, uint256 owner, uint256 level, uint256 fieldType, uint256 group, uint256 price) {
        payment = fields[_fieldId].payment;
        owner = fields[_fieldId].owner;
        level = fields[_fieldId].level;
        fieldType = fields[_fieldId].fieldType;
        group = fields[_fieldId].group;
        price = fields[_fieldId].price;
    }

    function debug_position() public view returns(uint256, uint256, uint256, uint256) {
        return (players[0].position, players[1].position, players[2].position, players[3].position);
    }

}